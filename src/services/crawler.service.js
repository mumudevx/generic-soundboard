import axios from "axios";
import * as cheerio from "cheerio";
import { logger } from "../utils/logger.js";
import { ParserService } from "./parser.service.js";

export class CrawlerService {
  constructor() {
    this.parser = new ParserService();
  }

  /**
   * Crawls a given URL and returns the parsed data
   * @param {string} url - The URL to crawl
   * @param {Object} options - Additional options for crawling
   * @returns {Promise<Object>} The parsed data
   */
  async crawl(url, options = {}) {
    try {
      logger.info(`Starting to crawl: ${url}`);

      const response = await this.fetchPage(url);
      const parsedData = await this.parser.parse(response.data);

      return parsedData;
    } catch (error) {
      logger.error(`Error crawling ${url}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Fetches a page from a given URL
   * @param {string} url - The URL to fetch
   * @returns {Promise<Object>} The axios response
   */
  async fetchPage(url) {
    try {
      const response = await axios.get(url, {
        headers: {
          "User-Agent": "Mozilla/5.0 (compatible; GenericCrawler/1.0;)",
        },
        timeout: 10000,
      });

      return response;
    } catch (error) {
      logger.error(`Error fetching ${url}: ${error.message}`);
      throw error;
    }
  }
}
