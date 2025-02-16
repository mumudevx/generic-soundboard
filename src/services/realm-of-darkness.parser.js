import * as cheerio from "cheerio";
import { ParserService } from "./parser.service.js";
import { logger } from "../utils/logger.js";

export class RealmOfDarknessParser extends ParserService {
  /**
   * Parses HTML content specifically for Realm of Darkness website
   * @param {string} html - The HTML content to parse
   * @param {Object} options - Additional parsing options
   * @returns {Promise<Object>} The parsed data
   */
  async parse(html, options = {}) {
    try {
      const $ = cheerio.load(html);
      const posts = [];

      // Find all article elements that represent posts
      $("article").each((_, article) => {
        const $article = $(article);

        const post = {
          id: $article.attr("id")?.replace("post-", "") || null,
          title: this.extractTitle($, $article),
          url: this.extractPostUrl($, $article),
          date: this.extractDate($, $article),
          author: this.extractAuthor($, $article),
          categories: this.extractCategories($, $article),
          thumbnail: this.extractThumbnail($, $article),
          excerpt: this.extractExcerpt($, $article),
        };

        posts.push(post);
      });

      return {
        posts,
        totalPosts: posts.length,
      };
    } catch (error) {
      logger.error(`Error parsing Realm of Darkness HTML: ${error.message}`);
      throw error;
    }
  }

  /**
   * Extracts the title and its URL from an article
   * @param {CheerioStatic} $ - Cheerio instance
   * @param {Cheerio} $article - The article element
   * @returns {Object} Title information
   */
  extractTitle($, $article) {
    const titleElem = $article.find(".entry-title a");
    return {
      text: titleElem.text()?.trim() || null,
      url: titleElem.attr("href") || null,
    };
  }

  /**
   * Extracts the post URL from an article
   * @param {CheerioStatic} $ - Cheerio instance
   * @param {Cheerio} $article - The article element
   * @returns {string|null} The post URL
   */
  extractPostUrl($, $article) {
    return $article.find(".continue-reading").attr("href") || null;
  }

  /**
   * Extracts the publication date from an article
   * @param {CheerioStatic} $ - Cheerio instance
   * @param {Cheerio} $article - The article element
   * @returns {string|null} The publication date
   */
  extractDate($, $article) {
    return $article.find(".entry-date a").text()?.trim() || null;
  }

  /**
   * Extracts the author information from an article
   * @param {CheerioStatic} $ - Cheerio instance
   * @param {Cheerio} $article - The article element
   * @returns {Object} Author information
   */
  extractAuthor($, $article) {
    const authorElem = $article.find(".entry-author a");
    return {
      name: authorElem.text()?.trim() || null,
      url: authorElem.attr("href") || null,
    };
  }

  /**
   * Extracts categories from an article
   * @param {CheerioStatic} $ - Cheerio instance
   * @param {Cheerio} $article - The article element
   * @returns {Array} Array of categories
   */
  extractCategories($, $article) {
    const categories = [];
    $article.find(".entry-categories a").each((_, elem) => {
      const $elem = $(elem);
      categories.push({
        name: $elem.text()?.trim() || null,
        url: $elem.attr("href") || null,
      });
    });
    return categories;
  }

  /**
   * Extracts thumbnail information from an article
   * @param {CheerioStatic} $ - Cheerio instance
   * @param {Cheerio} $article - The article element
   * @returns {Object|null} Thumbnail information
   */
  extractThumbnail($, $article) {
    const imgElem = $article.find(".entry-thumbnail img");
    if (!imgElem.length) return null;

    return {
      url: imgElem.attr("src") || null,
      alt: imgElem.attr("alt") || null,
      width: imgElem.attr("width") || null,
      height: imgElem.attr("height") || null,
    };
  }

  /**
   * Extracts the excerpt from an article
   * @param {CheerioStatic} $ - Cheerio instance
   * @param {Cheerio} $article - The article element
   * @returns {string|null} The excerpt text
   */
  extractExcerpt($, $article) {
    return $article.find(".entry-excerpt p").text()?.trim() || null;
  }
}
