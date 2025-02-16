import { CrawlerService } from "./crawler.service.js";
import { RealmOfDarknessParser } from "./realm-of-darkness.parser.js";
import { DatabaseService } from "./database.service.js";
import { logger } from "../utils/logger.js";

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
      };

      for (const post of result.posts) {
        try {
          const isNew = await this.db.upsertPost(post.id, post);
          if (isNew) {
            crawlResults.new++;
            logger.info(`New post found: ${post.title.text}`);
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
   * Crawls a specific post's detail page
   * @param {string} url - The post's detail page URL
   * @returns {Promise<Object>} The parsed post detail data
   */
  async crawlPostDetail(url) {
    try {
      logger.info(`Crawling post detail: ${url}`);

      const response = await this.fetchPage(url);
      // You can create a separate parser method for detail pages
      const detailData = await this.parser.parseDetail(response.data);

      return detailData;
    } catch (error) {
      logger.error(`Error crawling post detail ${url}: ${error.message}`);
      throw error;
    }
  }
}
