export function sanitizeFilename(text) {
    return text
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, '-')    // Replace special chars with hyphen
      .replace(/^-+|-+$/g, '')        // Remove leading/trailing hyphens
      .substring(0, 50);              // Limit length
  }