import { CrawlerService } from "./crawler.service.js";
import { RealmOfDarknessParser } from "./realm-of-darkness.parser.js";
import { DatabaseService } from "./database.service.js";
import { logger } from "../utils/logger.js";
import path from "path";

export class RealmOfDarknessCrawler extends CrawlerService {
  constructor() {
    super();
    this.parser = new RealmOfDarknessParser();
    this.db = new DatabaseService();
    this.baseUrl = "https://www.realmofdarkness.net/sb/";
    this.maxSoundboardsToCrawl = parseInt(process.env.MAX_SOUNDBOARDS_TO_CRAWL) || 10;
    this.testSoundboardUrl = process.env.RUN_TEST_SB_LINK || null;
  }

  /**
   * Crawls the Realm of Darkness website and stores posts in the database
   * @param {Object} options - Crawling options
   * @returns {Promise<Object>} Crawling results
   */
  async crawlPosts(options = {}) {
    try {
      // Check if we're in test mode
      if (this.testSoundboardUrl) {
        logger.info(`Running in test mode for soundboard: ${this.testSoundboardUrl}`);
        return await this.crawlTestSoundboard();
      }

      logger.info("Starting to crawl Realm of Darkness posts");
      logger.info(`Will crawl up to ${this.maxSoundboardsToCrawl} new soundboards`);

      // Initialize database
      await this.db.init();

      const crawlResults = {
        total: 0,
        new: 0,
        updated: 0,
        errors: 0,
        detailsCrawled: 0,
        pagesScanned: 0
      };

      let currentPage = 1;
      let newSoundboardsFound = 0;

      // Continue crawling pages until we reach the limit or no more pages
      while (newSoundboardsFound < this.maxSoundboardsToCrawl) {
        const pageUrl = currentPage === 1 
          ? this.baseUrl 
          : `${this.baseUrl}page/${currentPage}/`;

        try {
          // Fetch and parse the current page
          const response = await this.fetchPage(pageUrl);
          const result = await this.parser.parse(response.data);

          if (!result.posts.length) {
            logger.info("No more posts found, stopping pagination");
            break;
          }

          crawlResults.pagesScanned++;
          crawlResults.total += result.posts.length;

          // Process posts on this page
          for (const post of result.posts) {
            try {
              const isNew = await this.db.hasPost(post.id) === false;
              
              if (isNew && newSoundboardsFound < this.maxSoundboardsToCrawl) {
                // New soundboard within our limit
                newSoundboardsFound++;
                crawlResults.new++;
                logger.info(`New post found (${newSoundboardsFound}/${this.maxSoundboardsToCrawl}): ${post.title.text}`);
                
                // Crawl detail page and save to database
                await this.crawlPostDetail(post);
                await this.db.upsertPost(post.id, post);
                crawlResults.detailsCrawled++;

                if (newSoundboardsFound >= this.maxSoundboardsToCrawl) {
                  logger.info("Reached maximum number of soundboards to crawl");
                  break;
                }
              } else if (!isNew) {
                // Existing soundboard, just update the database
                crawlResults.updated++;
                await this.db.upsertPost(post.id, post);
                logger.info(`Updated post: ${post.title.text}`);
              }
            } catch (error) {
              crawlResults.errors++;
              logger.error(`Error processing post ${post.id}: ${error.message}`);
            }
          }

          // Add delay between pages to avoid rate limiting
          if (newSoundboardsFound < this.maxSoundboardsToCrawl) {
            await this.delay(2000); // 2 seconds delay between pages
            currentPage++;
          }
        } catch (error) {
          logger.error(`Error fetching page ${currentPage}: ${error.message}`);
          break;
        }
      }

      logger.info("Crawling completed", {
        ...crawlResults,
        lastPageScanned: currentPage
      });
      return crawlResults;
    } catch (error) {
      logger.error("Error during crawling:", error.message);
      throw error;
    }
  }

  /**
   * Crawls a single test soundboard
   * @returns {Promise<Object>} Crawling results
   */
  async crawlTestSoundboard() {
    try {
      // Extract title and ID from URL
      const urlParts = this.testSoundboardUrl.split('/');
      const slug = urlParts[urlParts.length - 2] || urlParts[urlParts.length - 1];
      
      // Create a minimal post object
      const testPost = {
        id: `test-${slug}`,
        title: {
          text: this._formatTitleFromSlug(slug),
          url: this.testSoundboardUrl
        }
      };

      // Crawl the test soundboard
      await this.crawlPostDetail(testPost);

      return {
        total: 1,
        new: 1,
        updated: 0,
        errors: 0,
        detailsCrawled: 1,
        pagesScanned: 1
      };
    } catch (error) {
      logger.error(`Error crawling test soundboard: ${error.message}`);
      throw error;
    }
  }

  /**
   * Formats a title from a URL slug
   * @param {string} slug - The URL slug
   * @returns {string} Formatted title
   */
  _formatTitleFromSlug(slug) {
    return slug
      .split('-')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  }

  /**
   * Delays execution
   * @param {number} ms - Milliseconds to delay
   * @returns {Promise} Promise that resolves after delay
   */
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Crawls a specific post's detail page and related files
   * @param {Object} post - Post data from main page
   * @returns {Promise<Object>} The parsed post detail data
   */
  async crawlPostDetail(post) {
    try {
      logger.info(`Crawling post detail: ${post.title.url}`);
      
      // Fetch detail page
      const detailResponse = await this.fetchPage(post.title.url);

      // Parse detail page and handle JavaScript files
      const detailData = await this.parser.parseDetail(
        detailResponse.data,
        post.id,
        post.title.text
      );

      return detailData;
    } catch (error) {
      logger.error(`Error crawling post detail ${post.title.url}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Extracts slug from URL
   * @param {string} url - The full URL
   * @returns {string} The slug
   */
  extractSlug(url) {
    const match = url.match(/\/sb\/([^/]+)\/?$/);
    return match ? match[1] : '';
  }
}
