import fs from 'fs/promises';
import path from 'path';
import { logger } from '../utils/logger.js';
import { execSync } from 'child_process';

export class MobileAppGenerator {
  constructor() {
    this.templatePath = path.resolve('soundboard_app');
    this.outputBasePath = path.resolve('data/mobile-apps');
    this.colors = [
      '0xFF6200EE', '0xFF03DAC5', '0xFF018786', '0xFFBB86FC',
      '0xFF3700B3', '0xFFCF6679', '0xFF121212', '0xFF1E1E1E'
    ];
  }

  /**
   * Generates a mobile app from a soundboard
   * @param {Object} soundboardData - The soundboard data
   * @param {string} sourcePath - Path to the source soundboard directory
   */
  async generateMobileApp(soundboardData, sourcePath) {
    try {
      const appName = this._formatAppName(soundboardData.title);
      const folderName = this._formatFolderName(soundboardData.title);
      const targetPath = path.join(this.outputBasePath, folderName);

      logger.info(`Generating mobile app for: ${appName}`);

      // Create necessary directories
      await this._createDirectories(targetPath);

      // Copy template files
      await this._copyTemplateFiles(targetPath);

      // Copy sound files
      await this._copySoundFiles(sourcePath, targetPath);

      // Update metadata.json
      await this._updateMetadataFile(soundboardData, targetPath);

      // Update app_config.dart
      await this._updateAppConfig(soundboardData, targetPath);

      // Create TODO.md
      await this._createTodoFile(targetPath);

      logger.info(`Mobile app generated successfully at: ${targetPath}`);
      return targetPath;
    } catch (error) {
      logger.error(`Error generating mobile app: ${error.message}`);
      throw error;
    }
  }

  /**
   * Creates necessary directories for the mobile app
   * @param {string} targetPath - The target directory path
   */
  async _createDirectories(targetPath) {
    const dirs = [
      targetPath,
      path.join(targetPath, 'assets/sounds'),
      path.join(targetPath, 'lib/config'),
    ];

    for (const dir of dirs) {
      await fs.mkdir(dir, { recursive: true });
    }
  }

  /**
   * Copies template files to the target directory
   * @param {string} targetPath - The target directory path
   */
  async _copyTemplateFiles(targetPath) {
    try {
      await this._recursiveCopy(this.templatePath, targetPath, ['sounds']);
    } catch (error) {
      logger.error(`Error copying template files: ${error.message}`);
      throw error;
    }
  }

  /**
   * Recursively copies files from source to target
   * @param {string} source - Source directory
   * @param {string} target - Target directory
   * @param {Array} excludeDirs - Directories to exclude
   */
  async _recursiveCopy(source, target, excludeDirs = []) {
    try {
      const entries = await fs.readdir(source, { withFileTypes: true });

      // Skip problematic Flutter platform directories
      const skipDirs = [
        '.dart_tool',
        '.plugin_symlinks',
        'ephemeral',
        'build',
        '.pub-cache',
        '.pub',
        '.packages',
        '.flutter-plugins',
        '.flutter-plugins-dependencies',
        'Generated.xcconfig',
      ];

      for (const entry of entries) {
        const sourcePath = path.join(source, entry.name);
        const targetPath = path.join(target, entry.name);

        // Skip excluded and problematic directories
        if (excludeDirs.includes(entry.name) || skipDirs.includes(entry.name)) {
          continue;
        }

        try {
          const stats = await fs.lstat(sourcePath);

          if (stats.isSymbolicLink()) {
            // Skip symlinks
            continue;
          } else if (stats.isDirectory()) {
            await fs.mkdir(targetPath, { recursive: true });
            await this._recursiveCopy(sourcePath, targetPath, excludeDirs);
          } else if (stats.isFile()) {
            await fs.copyFile(sourcePath, targetPath);
          }
        } catch (error) {
          logger.warn(`Skipping ${sourcePath}: ${error.message}`);
          continue;
        }
      }
    } catch (error) {
      logger.error(`Error copying directory ${source}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Copies sound files from source to target
   * @param {string} sourcePath - Source directory containing sounds
   * @param {string} targetPath - Target directory for the mobile app
   */
  async _copySoundFiles(sourcePath, targetPath) {
    const sourceDir = path.join(sourcePath, 'sounds');
    const targetDir = path.join(targetPath, 'assets/sounds');

    // Remove existing hi.mp3 if it exists
    try {
      await fs.unlink(path.join(targetDir, 'hi.mp3'));
    } catch (error) {
      // Ignore error if file doesn't exist
    }

    // Copy all sound files
    const files = await fs.readdir(sourceDir);
    for (const file of files) {
      if (file.endsWith('.mp3')) {
        await fs.copyFile(
          path.join(sourceDir, file),
          path.join(targetDir, file)
        );
      }
    }
  }

  /**
   * Updates the metadata.json file
   * @param {Object} soundboardData - The soundboard data
   * @param {string} targetPath - Target directory path
   */
  async _updateMetadataFile(soundboardData, targetPath) {
    const metadataPath = path.join(targetPath, 'lib/config/metadata.json');
    await fs.writeFile(
      metadataPath,
      JSON.stringify(soundboardData, null, 2)
    );
  }

  /**
   * Updates the app_config.dart file
   * @param {Object} soundboardData - The soundboard data
   * @param {string} targetPath - Target directory path
   */
  async _updateAppConfig(soundboardData, targetPath) {
    const configPath = path.join(targetPath, 'lib/config/app_config.dart');
    let configContent = await fs.readFile(configPath, 'utf8');

    const appName = this._formatAppName(soundboardData.title);
    const packageName = this._formatPackageName(soundboardData.title);
    const randomColor = this._getRandomColor();

    configContent = configContent
      .replace(/static const String appName = '[^']+';/, `static const String appName = '${appName}';`)
      .replace(/static const String packageName = '[^']+';/, `static const String packageName = '${packageName}';`)
      .replace(/static const Color primaryColor = Color\([^)]+\);/, `static const Color primaryColor = Color(${randomColor});`);

    await fs.writeFile(configPath, configContent);

    // Update Android app name and namespace
    await this._updateAndroidAppName(targetPath, appName);
    await this._updateAndroidNamespace(targetPath, packageName);
  }

  /**
   * Updates the Android app name in strings.xml
   * @param {string} targetPath - Target directory path
   * @param {string} appName - New app name
   */
  async _updateAndroidAppName(targetPath, appName) {
    try {
      // Create res/values directory if it doesn't exist
      const valuesDir = path.join(targetPath, 'android/app/src/main/res/values');
      await fs.mkdir(valuesDir, { recursive: true });

      // Create or update strings.xml
      const stringsXml = `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">${appName}</string>
</resources>`;

      await fs.writeFile(path.join(valuesDir, 'strings.xml'), stringsXml);
      logger.info(`Updated Android app name to: ${appName}`);

      // Update AndroidManifest.xml to use string resource
      const manifestPath = path.join(targetPath, 'android/app/src/main/AndroidManifest.xml');
      let manifestContent = await fs.readFile(manifestPath, 'utf8');
      
      // Replace android:label with string resource reference
      manifestContent = manifestContent.replace(
        /android:label="[^"]*"/,
        'android:label="@string/app_name"'
      );

      await fs.writeFile(manifestPath, manifestContent);
      logger.info('Updated AndroidManifest.xml to use string resource');
    } catch (error) {
      logger.error(`Error updating Android app name: ${error.message}`);
    }
  }

  /**
   * Updates the Android namespace in build.gradle.kts
   * @param {string} targetPath - Target directory path
   * @param {string} packageName - Package name to use as namespace
   */
  async _updateAndroidNamespace(targetPath, packageName) {
    try {
      const buildGradlePath = path.join(targetPath, 'android/app/build.gradle.kts');
      let buildGradleContent = await fs.readFile(buildGradlePath, 'utf8');

      // Update namespace and applicationId
      buildGradleContent = buildGradleContent
        .replace(/namespace = "[^"]+"/, `namespace = "${packageName}"`)
        .replace(/applicationId = "[^"]+"/, `applicationId = "${packageName}"`);

      await fs.writeFile(buildGradlePath, buildGradleContent);
      logger.info(`Updated Android namespace and applicationId to: ${packageName}`);
    } catch (error) {
      logger.error(`Error updating Android namespace: ${error.message}`);
    }
  }

  /**
   * Creates the TODO.md file
   * @param {string} targetPath - Target directory path
   */
  async _createTodoFile(targetPath) {
    const todoContent = `# TODO List

- [ ] Create add units on Admob
- [ ] Update AndroidManifest with new Admob App ID
- [ ] Replace ad unit IDs in app_config.dart
- [ ] Design app icon
- [ ] Update app icon in assets/icon/ (dart run flutter_launcher_icons)
- [ ] Take screenshots for the app (./scripts/take_screenshots.sh)
- [ ] Run generate_store_assets.dart to generate app store assets (./scripts/generate_store_assets.dart)
- [ ] Release app (flutter build appbundle)
- [ ] Run content-automation project to generate app store listing content (index.js change prompt variable's value)
- [ ] Create Google Play Console app and upload appbundle
`;

    await fs.writeFile(path.join(targetPath, 'TODO.md'), todoContent);
  }

  /**
   * Formats the app name
   * @param {string} title - The soundboard title
   * @returns {string} Formatted app name
   */
  _formatAppName(title) {
    return title.trim()
      .replace(/[^\w\s]/g, '')
      .replace(/\s+/g, ' ')
      + ' Soundboard';
  }

  /**
   * Formats the folder name
   * @param {string} title - The soundboard title
   * @returns {string} Formatted folder name
   */
  _formatFolderName(title) {
    return title.toLowerCase()
      .replace(/[^\w\s]/g, '')
      .replace(/\s+/g, '_');
  }

  /**
   * Formats the package name
   * @param {string} title - The soundboard title
   * @returns {string} Formatted package name
   */
  _formatPackageName(title) {
    const sanitized = title.toLowerCase()
      .replace(/[^\w\s]/g, '')
      .replace(/\s+/g, '');
    return `com.hayarsdev.${sanitized}`;
  }

  /**
   * Gets a random color from the predefined list
   * @returns {string} Random color in hex format
   */
  _getRandomColor() {
    return this.colors[Math.floor(Math.random() * this.colors.length)];
  }
} 