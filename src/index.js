import { config } from "dotenv";
import { CrawlerService } from "./services/crawler.service.js";
import { logger } from "./utils/logger.js";

// Load environment variables
config();

async function main() {
  try {
    const crawler = new CrawlerService();

    // Example usage
    const url = "https://example.com";
    const result = await crawler.crawl(url);

    logger.info("Crawling completed successfully");
    logger.info("Results:", { data: result });
  } catch (error) {
    logger.error("An error occurred during crawling:", error.message);
    process.exit(1);
  }
}

main();
