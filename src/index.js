import { config } from "dotenv";
import { RealmOfDarknessCrawler } from "./services/realm-of-darkness.crawler.js";
import { logger } from "./utils/logger.js";

// Load environment variables
config();

async function main() {
  try {
    const crawler = new RealmOfDarknessCrawler();

    // Crawl posts from the main page
    const results = await crawler.crawlPosts();

    logger.info("Crawling completed successfully", {
      totalPosts: results.total,
      newPosts: results.new,
      updatedPosts: results.updated,
      errors: results.errors
    });
  } catch (error) {
    logger.error("An error occurred during crawling:", error.message);
    process.exit(1);
  }
}

main();
