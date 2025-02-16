import winston from "winston";
import "winston-daily-rotate-file";
import path from "path";

const logFormat = winston.format.combine(
  winston.format.timestamp(),
  winston.format.colorize(),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    // Handle objects in the message
    if (typeof message === "object") {
      message = JSON.stringify(message, null, 2);
    }

    // Handle additional metadata
    const metaStr = Object.keys(meta).length
      ? JSON.stringify(meta, null, 2)
      : "";
    return `${timestamp} [${level}]: ${message} ${metaStr}`;
  })
);

// Create daily rotate file transports
const errorRotateTransport = new winston.transports.DailyRotateFile({
  filename: "logs/error-%DATE%.log",
  datePattern: "YYYY-MM-DD",
  level: "error",
  maxFiles: "30d", // Keep logs for 30 days
  maxSize: "20m", // Rotate if size exceeds 20MB
  format: logFormat
});

const combinedRotateTransport = new winston.transports.DailyRotateFile({
  filename: "logs/combined-%DATE%.log",
  datePattern: "YYYY-MM-DD",
  maxFiles: "30d",
  maxSize: "20m",
  format: logFormat
});

// Create console transport with colors
const consoleTransport = new winston.transports.Console({
  format: winston.format.combine(
    winston.format.colorize(),
    logFormat
  )
});

// Create logger instance
export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || "info",
  transports: [
    consoleTransport,
    errorRotateTransport,
    combinedRotateTransport
  ]
});

// Handle rotate events
errorRotateTransport.on("rotate", function (oldFilename, newFilename) {
  logger.info(`Error log rotated from ${oldFilename} to ${newFilename}`);
});

combinedRotateTransport.on("rotate", function (oldFilename, newFilename) {
  logger.info(`Combined log rotated from ${oldFilename} to ${newFilename}`);
});
