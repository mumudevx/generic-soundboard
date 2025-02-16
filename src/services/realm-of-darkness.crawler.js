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
  }

  /**
   * Crawls the Realm of Darkness website and stores posts in the database
   * @param {Object} options - Crawling options
   * @returns {Promise<Object>} Crawling results
   */
  async crawlPosts(options = {}) {
    try {
      logger.info("Starting to crawl Realm of Darkness posts");

      // Initialize database
      await this.db.init();

      // Fetch and parse the main page
      const response = await this.fetchPage(this.baseUrl);
      const result = await this.parser.parse(response.data);

      // Process each post
      const crawlResults = {
        total: result.posts.length,
        new: 0,
        updated: 0,
        errors: 0,
        detailsCrawled: 0
      };

      for (const post of result.posts) {
        try {
          const isNew = await this.db.upsertPost(post.id, post);
          
          if (isNew) {
            crawlResults.new++;
            logger.info(`New post found: ${post.title.text}`);
            
            // Crawl detail page for new posts
            await this.crawlPostDetail(post);
            crawlResults.detailsCrawled++;
          } else {
            crawlResults.updated++;
            logger.info(`Updated post: ${post.title.text}`);
          }
        } catch (error) {
          crawlResults.errors++;
          logger.error(`Error processing post ${post.id}: ${error.message}`);
        }
      }

      logger.info("Crawling completed", crawlResults);
      return crawlResults;
    } catch (error) {
      logger.error("Error during crawling:", error.message);
      throw error;
    }
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
