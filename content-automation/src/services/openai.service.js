import OpenAI from 'openai';
import { logger } from '../utils/logger.js';

export class OpenAIService {
  constructor() {
    this.client = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });
    this.assistantId = process.env.ASSISTANT_ID;
  }

  /**
   * Creates a new thread and sends a message to the assistant
   * @param {string} content - The message content to send
   * @returns {Promise<string>} The assistant's response
   */
  async getAssistantResponse(content) {
    try {
      logger.info('Creating new thread');
      const thread = await this.client.beta.threads.create();

      logger.info('Adding message to thread');
      await this.client.beta.threads.messages.create(thread.id, {
        role: 'user',
        content: content
      });

      logger.info('Running assistant');
      const run = await this.client.beta.threads.runs.create(thread.id, {
        assistant_id: this.assistantId
      });

      // Wait for the run to complete
      let runStatus = await this.client.beta.threads.runs.retrieve(
        thread.id,
        run.id
      );

      while (runStatus.status !== 'completed') {
        if (runStatus.status === 'failed') {
          throw new Error('Assistant run failed');
        }
        
        await new Promise(resolve => setTimeout(resolve, 1000));
        runStatus = await this.client.beta.threads.runs.retrieve(
          thread.id,
          run.id
        );
        logger.debug(`Run status: ${runStatus.status}`);
      }

      // Get the messages
      const messages = await this.client.beta.threads.messages.list(thread.id);
      
      // Get the last assistant message
      const lastMessage = messages.data
        .filter(message => message.role === 'assistant')
        .pop();

      if (!lastMessage) {
        throw new Error('No response from assistant');
      }

      // Clean up the thread
      await this.client.beta.threads.del(thread.id);

      return lastMessage.content[0].text.value;
    } catch (error) {
      logger.error(`Error getting assistant response: ${error.message}`);
      throw error;
    }
  }
} 