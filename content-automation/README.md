# Content Automation with OpenAI Assistant

This Node.js application integrates with OpenAI's Assistant API to generate content and save it as markdown files.

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Copy `.env.example` to `.env` and fill in your OpenAI API key and Assistant ID:
   ```bash
   cp .env.example .env
   ```

## Configuration

Edit `.env` file with your settings:

```env
OPENAI_API_KEY=your_api_key_here
ASSISTANT_ID=your_assistant_id_here
OUTPUT_DIR=output
LOG_LEVEL=info
```

## Usage

1. Use the main application:
   ```bash
   npm start
   ```

3. Check the `output` directory for generated markdown files.

## Project Structure

```
content-automation/
├── src/
│   ├── services/
│   │   ├── openai.service.js
│   │   └── content.service.js
│   ├── utils/
│   │   └── logger.js
│   └── index.js
├── output/
└── logs/
```

## Features

- OpenAI Assistant API integration
- Markdown file generation with metadata
- Logging system
- Error handling

## Development

Run with nodemon for development:
```bash
npm run dev
```

## Logs

Logs are stored in:
- `logs/error.log` - Error logs only
- `logs/combined.log` - All logs 