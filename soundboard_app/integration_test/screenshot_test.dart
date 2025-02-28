import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:soundboard_app/main.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Screenshot Tests', () {
    testWidgets('Capture main app states', (WidgetTester tester) async {
      // Get app's local directory
      final appDir = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory(path.join(appDir.path, 'screenshots'));
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      print('Screenshots will be saved to: ${screenshotsDir.absolute.path}');

      // Start the app
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('screenshot'),
          child: MaterialApp(
            home: const SoundboardApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Helper function to take and encode screenshot
      Future<void> takeScreenshot(String name) async {
        // Ensure rendering is complete before taking screenshot
        await tester.pumpAndSettle();
        
        // Add an extra pump to ensure the frame is rendered
        await tester.pump();
        
        try {
          final finder = find.byKey(const Key('screenshot'));
          final element = tester.element(finder);
          final renderObject = element.renderObject as RenderRepaintBoundary;
          final image = await renderObject.toImage(pixelRatio: 3.0);
          final bytes = await image.toByteData(format: ImageByteFormat.png);
          final base64Image = base64Encode(bytes!.buffer.asUint8List());
          
          print('SCREENSHOT_START:$name');
          print(base64Image);
          print('SCREENSHOT_END:$name');
        } catch (e) {
          print('Error taking screenshot: $e');
          // Try one more time after a short delay
          await Future.delayed(const Duration(milliseconds: 500));
          await tester.pump();
          
          final finder = find.byKey(const Key('screenshot'));
          final element = tester.element(finder);
          final renderObject = element.renderObject as RenderRepaintBoundary;
          final image = await renderObject.toImage(pixelRatio: 3.0);
          final bytes = await image.toByteData(format: ImageByteFormat.png);
          final base64Image = base64Encode(bytes!.buffer.asUint8List());
          
          print('SCREENSHOT_START:$name');
          print(base64Image);
          print('SCREENSHOT_END:$name');
        }
      }

      // 1. Take screenshot of home screen with grid layout
      await Future.delayed(const Duration(seconds: 1)); // Wait for animations
      await tester.pumpAndSettle(); // Ensure UI is fully rendered
      await takeScreenshot('01_home_screen.png');

      // 2. Long press first sound button to show favorite dialog
      final soundButtons = find.byType(Card);
      expect(soundButtons, findsWidgets, reason: 'No sound buttons found');
      
      // Start long press
      final gesture = await tester.startGesture(tester.getCenter(soundButtons.first));
      await tester.pump(const Duration(seconds: 1)); // Hold for 1 second
      await gesture.up(); // Release the gesture
      
      // Wait for dialog to fully appear
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
      
      // Take screenshot of favorite dialog
      await tester.pumpAndSettle(); // Ensure UI is fully rendered
      await takeScreenshot('02_favorite_dialog.png');
      
      // Close dialog by tapping outside
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // 3. Navigate to favorites screen
      final favoriteIcon = find.byIcon(Icons.favorite);
      expect(favoriteIcon, findsOneWidget, reason: 'Favorites icon not found');
      
      await tester.tap(favoriteIcon);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
      
      // Take screenshot of favorites screen
      await tester.pumpAndSettle(); // Ensure UI is fully rendered
      await takeScreenshot('03_favorites_screen.png');
    });
  });
} 