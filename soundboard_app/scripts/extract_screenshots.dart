import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;

void main() async {
  // Create screenshots directory if it doesn't exist
  final screenshotsDir = Directory('screenshots');
  if (!await screenshotsDir.exists()) {
    await screenshotsDir.create();
  }

  String currentFilename = '';
  StringBuffer base64Data = StringBuffer();
  bool isCollectingData = false;

  await for (String line in stdin.transform(utf8.decoder).transform(LineSplitter())) {
    if (line.startsWith('SCREENSHOT_START:')) {
      currentFilename = line.split(':')[1].trim();
      base64Data.clear();
      isCollectingData = true;
      print('Starting to collect data for $currentFilename');
    } else if (line.startsWith('SCREENSHOT_END:')) {
      if (isCollectingData && currentFilename.isNotEmpty) {
        final bytes = base64.decode(base64Data.toString());
        
        // Decode the image
        final decodedImage = img.decodeImage(bytes);
        
        if (decodedImage != null) {
          // Rotate the image 180 degrees
          final rotatedImage = img.copyRotate(decodedImage, angle: 180);
          
          // Flip the image horizontally
          final flippedImage = img.flipHorizontal(rotatedImage);
          
          // Encode the rotated and flipped image back to PNG
          final processedBytes = img.encodePng(flippedImage);
          
          // Save the processed image
          final file = File('screenshots/$currentFilename');
          await file.writeAsBytes(processedBytes);
          print('Saved rotated and flipped screenshot to: ${file.absolute.path}');
        } else {
          print('Failed to decode image for $currentFilename');
          // Save the original bytes as fallback
          final file = File('screenshots/$currentFilename');
          await file.writeAsBytes(bytes);
          print('Saved original (non-processed) screenshot to: ${file.absolute.path}');
        }
        
        isCollectingData = false;
      }
    } else if (isCollectingData) {
      base64Data.write(line);
    }
  }
} 