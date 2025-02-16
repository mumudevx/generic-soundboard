import * as cheerio from "cheerio";
import { logger } from "../utils/logger.js";

export class ParserService {
  /**
   * Parses HTML content and extracts desired data
   * @param {string} html - The HTML content to parse
   * @param {Object} options - Additional parsing options
   * @returns {Promise<Object>} The parsed data
   */
  async parse(html, options = {}) {
    try {
      const $ = cheerio.load(html);

      // Example parsing logic - customize based on your needs
      const data = {
        title: $("title").text() || null,
        description: $('meta[name="description"]').attr("content") || null,
        headings: this.extractHeadings($),
        links: this.extractLinks($),
        // Add more parsing methods as needed
      };

      return data;
    } catch (error) {
      logger.error(`Error parsing HTML: ${error.message}`);
      throw error;
    }
  }

  /**
   * Extracts all headings from the page
   * @param {CheerioStatic} $ - Cheerio instance
   * @returns {Array} Array of headings
   */
  extractHeadings($) {
    const headings = [];
    $("h1, h2, h3").each((i, elem) => {
      headings.push({
        level: elem.name,
        text: $(elem).text().trim(),
      });
    });
    return headings;
  }

  /**
   * Extracts all links from the page
   * @param {CheerioStatic} $ - Cheerio instance
   * @returns {Array} Array of links
   */
  extractLinks($) {
    const links = [];
    $("a").each((i, elem) => {
      const href = $(elem).attr("href");
      if (href && !href.startsWith("#")) {
        links.push({
          text: $(elem).text().trim(),
          url: href,
        });
      }
    });
    return links;
  }
}
