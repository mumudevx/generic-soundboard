import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:xml/xml.dart' as xml;

// Simple color class to replace dart:ui.Color
class Color {
  final int red;
  final int green;
  final int blue;
  final int alpha;
  
  Color(int value)
      : red = (value >> 16) & 0xFF,
        green = (value >> 8) & 0xFF,
        blue = value & 0xFF,
        alpha = (value >> 24) & 0xFF;
  
  @override
  String toString() => 'Color(0x${alpha.toRadixString(16).padLeft(2, '0')}${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')})';
}

void main() async {
  // Create output directory if it doesn't exist
  final storeAssetsDir = Directory('store_assets');
  if (!await storeAssetsDir.exists()) {
    await storeAssetsDir.create();
  }
  
  // Read the background color from colors.xml
  final colorsXmlFile = File('android/app/src/main/res/values/colors.xml');
  final colorsXmlContent = await colorsXmlFile.readAsString();
  
  // Parse XML to extract the background color
  final document = xml.XmlDocument.parse(colorsXmlContent);
  final colorElement = document.findAllElements('color')
      .firstWhere((element) => element.getAttribute('name') == 'ic_launcher_background');
  
  final colorHex = colorElement.innerText;
  print('Using background color: $colorHex');
  
  // Convert hex color to RGB
  final color = _hexToColor(colorHex);
  
  // Load the icon image
  final iconFile = File('assets/icon/icon.png');
  if (!await iconFile.exists()) {
    print('Error: Icon file not found at ${iconFile.path}');
    return;
  }
  
  final iconBytes = await iconFile.readAsBytes();
  final iconImage = img.decodeImage(iconBytes);
  
  if (iconImage == null) {
    print('Error: Failed to decode icon image');
    return;
  }
  
  // Generate app icon (512x512)
  await _generateImage(
    iconImage: iconImage,
    outputPath: '${storeAssetsDir.path}/app_icon.png',
    width: 512,
    height: 512,
    backgroundColor: color,
    iconScale: 0.8, // Icon will take up 80% of the space
  );
  
  // Generate feature graphic (1024x500)
  await _generateImage(
    iconImage: iconImage,
    outputPath: '${storeAssetsDir.path}/feature_graphic.png',
    width: 1024,
    height: 500,
    backgroundColor: color,
    iconScale: 0.6, // Icon will take up 60% of the height
  );
  
  print('Store assets generated successfully in ${storeAssetsDir.absolute.path}');
}

// Helper function to convert hex color to RGB
Color _hexToColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor'; // Add alpha if not present
  }
  return Color(int.parse(hexColor, radix: 16));
}

// Generate an image with the specified dimensions and background color
Future<void> _generateImage({
  required img.Image iconImage,
  required String outputPath,
  required int width,
  required int height,
  required Color backgroundColor,
  required double iconScale,
}) async {
  // Create a blank image with the specified background color
  final image = img.Image(width: width, height: height);
  
  // Fill the image with the background color
  img.fill(
    image,
    color: img.ColorRgba8(
      backgroundColor.red,
      backgroundColor.green,
      backgroundColor.blue,
      backgroundColor.alpha,
    ),
  );
  
  // Calculate the size of the icon
  int iconSize;
  if (width == height) {
    // For square images (app icon)
    iconSize = (width * iconScale).round();
  } else {
    // For rectangular images (feature graphic)
    iconSize = (height * iconScale).round();
  }
  
  // Resize the icon while maintaining aspect ratio
  final resizedIcon = img.copyResize(
    iconImage,
    width: iconSize,
    height: iconSize,
    interpolation: img.Interpolation.cubic,
  );
  
  // Calculate the position to center the icon
  final x = (width - resizedIcon.width) ~/ 2;
  final y = (height - resizedIcon.height) ~/ 2;
  
  // Composite the icon onto the background
  img.compositeImage(
    image,
    resizedIcon,
    dstX: x,
    dstY: y,
  );
  
  // Save the image
  final outputFile = File(outputPath);
  await outputFile.writeAsBytes(img.encodePng(image));
  
  print('Generated image: $outputPath (${width}x${height})');
} 