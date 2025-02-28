import 'dotenv/config';
import { OpenAIService } from './services/openai.service.js';
import { ContentService } from './services/content.service.js';
import { logger } from './utils/logger.js';
import { sanitizeFilename } from './utils/naming.js';
async function main() {
  try {
    const openai = new OpenAIService();
    const content = new ContentService();

    const prompt = `amy soundboard`;
    const fileName = sanitizeFilename(prompt);

    logger.info('Sending prompt to assistant');
    const response = await openai.getAssistantResponse(prompt);

    logger.info('Saving response to markdown');
    await content.saveToMarkdown(response, fileName);

    logger.info('Process completed successfully');
  } catch (error) {
    logger.error('Process failed:', error);
    process.exit(1);
  }
}

main(); 