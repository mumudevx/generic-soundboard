import fs from "fs/promises";
import path from "path";
import { logger } from "../utils/logger.js";

export class DatabaseService {
  constructor(dbPath = "data/posts.json") {
    this.dbPath = dbPath;
    this.posts = new Map();
    this.initialized = false;
  }

  /**
   * Initializes the database
   */
  async init() {
    try {
      // Create data directory if it doesn't exist
      await fs.mkdir(path.dirname(this.dbPath), { recursive: true });

      // Load existing data if available
      try {
        const data = await fs.readFile(this.dbPath, "utf-8");
        const posts = JSON.parse(data);
        this.posts = new Map(Object.entries(posts));
      } catch (error) {
        if (error.code !== "ENOENT") {
          throw error;
        }
        // File doesn't exist, start with empty database
        await this.save();
      }

      this.initialized = true;
      logger.info("Database initialized successfully");
    } catch (error) {
      logger.error(`Error initializing database: ${error.message}`);
      throw error;
    }
  }

  /**
   * Saves the current state to the database file
   */
  async save() {
    try {
      const data = Object.fromEntries(this.posts);
      await fs.writeFile(this.dbPath, JSON.stringify(data, null, 2));
      logger.info("Database saved successfully");
    } catch (error) {
      logger.error(`Error saving database: ${error.message}`);
      throw error;
    }
  }

  /**
   * Adds or updates a post in the database
   * @param {string} id - The post ID
   * @param {Object} post - The post data
   * @returns {boolean} Whether the post was newly added
   */
  async upsertPost(id, post) {
    if (!this.initialized) await this.init();

    const isNew = !this.posts.has(id);
    this.posts.set(id, {
      ...post,
      updatedAt: new Date().toISOString(),
      crawledAt: isNew
        ? new Date().toISOString()
        : this.posts.get(id)?.crawledAt,
    });

    await this.save();
    return isNew;
  }

  /**
   * Checks if a post exists in the database
   * @param {string} id - The post ID
   * @returns {boolean} Whether the post exists
   */
  async hasPost(id) {
    if (!this.initialized) await this.init();
    return this.posts.has(id);
  }

  /**
   * Gets a post from the database
   * @param {string} id - The post ID
   * @returns {Object|null} The post data
   */
  async getPost(id) {
    if (!this.initialized) await this.init();
    return this.posts.get(id) || null;
  }

  /**
   * Gets all posts from the database
   * @returns {Array} Array of posts
   */
  async getAllPosts() {
    if (!this.initialized) await this.init();
    return Array.from(this.posts.values());
  }
}
