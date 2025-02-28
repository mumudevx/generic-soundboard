import fs from 'fs/promises';
import path from 'path';
import { logger } from '../utils/logger.js';

export class ContentService {
  constructor() {
    this.outputDir = process.env.OUTPUT_DIR || 'output';
  }

  /**
   * Saves content to a markdown file
   * @param {string} content - The content to save
   * @param {string} filename - The filename without extension
   */
  async saveToMarkdown(content, filename) {
    try {
      // Create output directory if it doesn't exist
      await fs.mkdir(this.outputDir, { recursive: true });

      const filePath = path.join(this.outputDir, `${filename}.md`);
      
      // Add timestamp to content
      const timestamp = new Date().toISOString();
      const contentWithMeta = `---
generated: ${timestamp}
---

${content}`;

      await fs.writeFile(filePath, contentWithMeta);
      logger.info(`Content saved to ${filePath}`);
    } catch (error) {
      logger.error(`Error saving content: ${error.message}`);
      throw error;
    }
  }

  /**
   * Reads content from a markdown file
   * @param {string} filename - The filename without extension
   * @returns {Promise<string>} The file content
   */
  async readFromMarkdown(filename) {
    try {
      const filePath = path.join(this.outputDir, `${filename}.md`);
      const content = await fs.readFile(filePath, 'utf8');
      return content;
    } catch (error) {
      logger.error(`Error reading content: ${error.message}`);
      throw error;
    }
  }
} 