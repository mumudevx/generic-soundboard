import * as cheerio from "cheerio";
import { ParserService } from "./parser.service.js";
import { logger } from "../utils/logger.js";
import path from "path";
import fs from "fs/promises";
import axios from "axios";
import { MobileAppGenerator } from './mobile-app.generator.js';

export class RealmOfDarknessParser extends ParserService {
  constructor() {
    super();
    this.soundboardsPath = "data/soundboards";
    this.maxRetries = 3;
    this.retryDelay = 2000; // 2 seconds
    this.concurrentDownloads = 2; // Number of concurrent downloads
    this.mobileAppGenerator = new MobileAppGenerator();
  }

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

  /**
   * Parses the detail page of a soundboard
   * @param {string} html - The HTML content of the detail page
   * @param {string} postId - The post ID
   * @param {string} title - The soundboard title
   * @returns {Promise<Object>} Parsed detail data
   */
  async parseDetail(html, postId, title) {
    try {
      const $ = cheerio.load(html);

      // Extract JavaScript file paths
      const scriptPaths = this.extractScriptPaths($);
      if (!scriptPaths.soundsJs || !scriptPaths.sbJs) {
        throw new Error("Could not find required JavaScript files");
      }

      // Fetch JavaScript files
      const [soundsJsContent, sbJsContent] = await Promise.all([
        this.fetchJavaScript(scriptPaths.soundsJs),
        this.fetchJavaScript(scriptPaths.sbJs),
      ]);

      const soundboardData = {
        id: postId,
        title: title,
        buttons: [],
        basePath: this.extractBasePath(sbJsContent),
      };

      // Extract button information directly from HTML
      $("div.sb button").each((index, elem) => {
        const $button = $(elem);
        const buttonText = $button.text().trim();
        const buttonId = $button.attr("id");

        // Skip "Stop Sounds" button and buttons without IDs
        if (buttonText !== "Stop Sounds" && buttonId) {
          soundboardData.buttons.push({
            id: `sound_${index + 1}`,  // Add index-based id with sound_ prefix
            text: buttonText,
            soundFile: buttonId,
            soundPath: this.buildSoundPath(soundboardData.basePath, buttonId),
          });
        }
      });

      // Create soundboard directory and save metadata
      const soundboardDir = await this.saveSoundboardData(soundboardData);

      // Download sound files
      await this.downloadSoundFiles(soundboardData, soundboardDir);

      return soundboardData;
    } catch (error) {
      logger.error(`Error parsing detail page: ${error.message}`);
      throw error;
    }
  }

  /**
   * Extracts JavaScript file paths from HTML
   * @param {CheerioStatic} $ - Cheerio instance
   * @returns {Object} Object containing paths to sounds.js and sb.js
   */
  extractScriptPaths($) {
    const scripts = {};
    $("script[src]").each((_, elem) => {
      const src = $(elem).attr("src");
      if (src) {
        if (src.includes("sounds.js")) {
          scripts.soundsJs = this.normalizeScriptPath(src);
        } else if (src.includes("sb.js")) {
          scripts.sbJs = this.normalizeScriptPath(src);
        }
      }
    });
    return scripts;
  }

  /**
   * Normalizes script path to absolute URL
   * @param {string} src - Script source path
   * @returns {string} Absolute URL
   */
  normalizeScriptPath(src) {
    if (src.startsWith("http")) {
      return src;
    } else if (src.startsWith("//")) {
      return `https:${src}`;
    } else if (src.includes("/")) {
      return `https://www.realmofdarkness.net${src}`;
    } else {
      return `https://www.realmofdarkness.net/${src}`;
    }
  }

  /**
   * Fetches JavaScript file content
   * @param {string} url - URL of the JavaScript file
   * @returns {Promise<string>} JavaScript file content
   */
  async fetchJavaScript(url) {
    try {
      const response = await axios.get(url, {
        timeout: 10000,
        headers: {
          Accept: "*/*",
          "User-Agent": "Mozilla/5.0 (compatible; GenericCrawler/1.0;)",
        },
      });
      return response.data;
    } catch (error) {
      logger.error(`Error fetching JavaScript file ${url}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Downloads sound files for a soundboard
   * @param {Object} soundboardData - Soundboard metadata
   * @param {string} soundboardDir - Directory to save sound files
   */
  async downloadSoundFiles(soundboardData, soundboardDir) {
    try {
      // Create sounds directory
      const soundsDir = path.join(soundboardDir, "sounds");
      await fs.mkdir(soundsDir, { recursive: true });

      // First, check which files need to be downloaded
      const existingFiles = new Set();
      try {
        const files = await fs.readdir(soundsDir);
        for (const file of files) {
          if (file.endsWith('.mp3')) {
            const stats = await fs.stat(path.join(soundsDir, file));
            if (stats.size > 0) {
              existingFiles.add(file.replace('.mp3', ''));
            }
          }
        }
      } catch (error) {
        logger.error(`Error reading existing files: ${error.message}`);
      }

      // Filter buttons that need downloading
      const buttonsToDownload = soundboardData.buttons.filter(
        button => !existingFiles.has(button.soundFile)
      );

      if (buttonsToDownload.length === 0) {
        logger.info(`All ${soundboardData.buttons.length} sound files already exist for ${soundboardData.title}`);
        
        // Update localPath for all existing buttons
        soundboardData.buttons.forEach(button => {
          button.localPath = path.join("sounds", `${button.soundFile}.mp3`);
        });

        return {
          success: soundboardData.buttons.length,
          failed: 0,
          total: soundboardData.buttons.length,
          skipped: soundboardData.buttons.length
        };
      }

      logger.info(`Found ${buttonsToDownload.length} new sounds to download out of ${soundboardData.buttons.length} total`);

      // Process buttons in chunks to limit concurrent downloads
      const chunks = this.chunkArray(
        buttonsToDownload,
        this.concurrentDownloads
      );

      let downloadedCount = 0;
      let failedDownloads = [];
      const totalNewSounds = buttonsToDownload.length;

      for (const chunk of chunks) {
        const downloads = chunk.map((button) =>
          this.downloadSoundFileWithRetry(button, soundsDir)
            .catch(error => {
              failedDownloads.push({
                button,
                error: error.message
              });
              return false;
            })
        );
        
        const results = await Promise.all(downloads);
        const successfulDownloads = results.filter(result => result !== false).length;
        downloadedCount += successfulDownloads;

        logger.info(`Downloaded ${downloadedCount}/${totalNewSounds} new sound files`);

        // Add delay between chunks to avoid rate limiting
        if (chunks.indexOf(chunk) < chunks.length - 1) {
          await this.delay(1000);
        }
      }

      // Remove failed downloads from metadata
      if (failedDownloads.length > 0) {
        logger.warn(`Failed to download ${failedDownloads.length} sound files:`, {
          failed: failedDownloads.map(f => ({
            text: f.button.text,
            soundFile: f.button.soundFile,
            error: f.error
          }))
        });

        // Remove failed downloads from soundboardData.buttons
        const failedSoundFiles = new Set(failedDownloads.map(f => f.button.soundFile));
        soundboardData.buttons = soundboardData.buttons.filter(button => 
          !failedSoundFiles.has(button.soundFile)
        );

        // Update metadata file with cleaned data
        await fs.writeFile(
          path.join(soundboardDir, "metadata.json"),
          JSON.stringify(soundboardData, null, 2)
        );
      }

      const totalSuccess = existingFiles.size + downloadedCount;
      logger.info(`Sound files status for ${soundboardData.title}:`, {
        existing: existingFiles.size,
        newlyDownloaded: downloadedCount,
        failed: failedDownloads.length,
        total: soundboardData.buttons.length
      });
      
      return {
        success: totalSuccess,
        failed: failedDownloads.length,
        total: soundboardData.buttons.length,
        skipped: existingFiles.size,
        new: downloadedCount
      };
    } catch (error) {
      logger.error(`Error downloading sound files: ${error.message}`);
      throw error;
    }
  }

  /**
   * Downloads a single sound file with retry mechanism
   * @param {Object} button - Button data containing sound information
   * @param {string} soundsDir - Directory to save sound files
   */
  async downloadSoundFileWithRetry(button, soundsDir, attempt = 1) {
    try {
      const soundUrl = `https://www.realmofdarkness.net${button.soundPath}`;
      const soundFilePath = path.join(soundsDir, `${button.soundFile}.mp3`);

      // Check if file already exists and is valid
      try {
        const stats = await fs.stat(soundFilePath);
        if (stats.size > 0) {
          logger.info(`Sound file already exists and valid: ${button.soundFile}.mp3`);
          button.localPath = path.join("sounds", `${button.soundFile}.mp3`);
          return true;
        } else {
          // File exists but is empty, delete it
          await fs.unlink(soundFilePath);
        }
      } catch {
        // File doesn't exist, proceed with download
      }

      const response = await axios({
        method: "get",
        url: soundUrl,
        responseType: "arraybuffer",
        timeout: 30000,
        headers: {
          Accept: "*/*",
          "User-Agent": "Mozilla/5.0 (compatible; GenericCrawler/1.0;)",
          Referer: "https://www.realmofdarkness.net/sb/",
          "Accept-Encoding": "gzip, deflate, br",
          Connection: "keep-alive",
        },
      });

      if (!response.data || response.data.length === 0) {
        throw new Error('Empty response received');
      }

      await fs.writeFile(soundFilePath, response.data);
      
      // Verify file was written successfully
      const fileStats = await fs.stat(soundFilePath);
      if (fileStats.size === 0) {
        throw new Error('File was written but is empty');
      }

      logger.info(`Downloaded sound file: ${button.soundFile}.mp3`);
      button.localPath = path.join("sounds", `${button.soundFile}.mp3`);
      return true;
    } catch (error) {
      if (attempt < this.maxRetries) {
        logger.warn(
          `Retry ${attempt}/${this.maxRetries} for ${button.soundFile}: ${error.message}`
        );
        await this.delay(this.retryDelay * attempt);
        return this.downloadSoundFileWithRetry(button, soundsDir, attempt + 1);
      }
      
      logger.error(
        `Failed to download ${button.soundFile} after ${this.maxRetries} attempts: ${error.message}`
      );
      throw error;
    }
  }

  /**
   * Splits array into chunks
   * @param {Array} array - Array to split
   * @param {number} size - Chunk size
   * @returns {Array} Array of chunks
   */
  chunkArray(array, size) {
    const chunks = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }

  /**
   * Delays execution
   * @param {number} ms - Milliseconds to delay
   * @returns {Promise} Promise that resolves after delay
   */
  delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  /**
   * Extracts base path for sound files from sb.js
   * @param {string} sbJs - Content of sb.js file
   * @returns {string} Base path for sound files
   */
  extractBasePath(sbJs) {
    try {
      const match = sbJs.match(/src:\s*\["(.*?)" \+ sounds/);
      if (match && match[1]) {
        return match[1];
      }
      return "/audio/sfx/";
    } catch (error) {
      logger.error(`Error extracting base path: ${error.message}`);
      return "/audio/sfx/";
    }
  }

  /**
   * Builds complete sound file path
   * @param {string} basePath - Base path from sb.js
   * @param {string} soundFile - Sound file name
   * @returns {string} Complete sound file path
   */
  buildSoundPath(basePath, soundFile) {
    return `${basePath}${soundFile}.mp3`;
  }

  /**
   * Saves soundboard data to filesystem
   * @param {Object} soundboardData - Soundboard data to save
   * @returns {string} The path to the soundboard directory
   */
  async saveSoundboardData(soundboardData) {
    try {
      // Create soundboards directory if it doesn't exist
      await fs.mkdir(this.soundboardsPath, { recursive: true });

      // Create directory for this soundboard
      const soundboardDir = path.join(
        this.soundboardsPath,
        soundboardData.title.toLowerCase().replace(/[^a-z0-9]+/g, "-")
      );
      await fs.mkdir(soundboardDir, { recursive: true });

      // Save metadata
      await fs.writeFile(
        path.join(soundboardDir, "metadata.json"),
        JSON.stringify(soundboardData, null, 2)
      );

      logger.info(`Saved soundboard data to ${soundboardDir}`);

      // Download sound files first
      await this.downloadSoundFiles(soundboardData, soundboardDir);

      // Generate mobile app only after all sounds are downloaded
      try {
        await this.mobileAppGenerator.generateMobileApp(soundboardData, soundboardDir);
        logger.info(`Generated mobile app for ${soundboardData.title}`);
      } catch (error) {
        logger.error(`Error generating mobile app: ${error.message}`);
        // Continue with the crawling process even if mobile app generation fails
      }

      return soundboardDir;
    } catch (error) {
      logger.error(`Error saving soundboard data: ${error.message}`);
      throw error;
    }
  }
}
