import 'package:flutter/material.dart';
import 'package:soundboard_app/config/app_config.dart';
import 'package:soundboard_app/widgets/sound_button.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:soundboard_app/widgets/base_screen.dart';
import 'package:soundboard_app/services/event_bus_service.dart';
import 'package:soundboard_app/events/favorite_events.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> soundButtons = [];
  List<Map<String, dynamic>> displayedButtons = [];
  List<Map<String, dynamic>> filteredButtons = [];
  String title = AppConfig.appName;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadMetadata();
    _searchController.addListener(_onSearchChanged);
    
    // Listen to favorite changes
    EventBusService.eventBus.on<FavoriteStatusChanged>().listen((event) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        displayedButtons = soundButtons;
      } else {
        displayedButtons = soundButtons
            .where((button) =>
                button['text'].toString().toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> loadMetadata() async {
    try {
      final String jsonString =
          await rootBundle.loadString('lib/config/metadata.json');
      final Map<String, dynamic> metadata = json.decode(jsonString);
      setState(() {
        soundButtons = List<Map<String, dynamic>>.from(metadata['buttons']);
        displayedButtons = soundButtons;
        title = metadata['title'] ?? AppConfig.appName;
      });
    } catch (e) {
      print('Error loading metadata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<FavoriteChangedNotification>(
      onNotification: (notification) {
        setState(() {});
        return true;
      },
      child: BaseScreen(
        title: title,
        searchController: _searchController,
        soundButtons: soundButtons,
        body: displayedButtons.isEmpty
            ? const Center(child: Text('No sounds found'))
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                ),
                itemCount: displayedButtons.length,
                itemBuilder: (context, index) {
                  final button = displayedButtons[index];
                  return SoundButton(
                    text: button['text'],
                    soundPath: 'assets/${button['localPath']}',
                    color: AppConfig.getButtonColor(index),
                    id: button['id'],
                    onFavoriteChanged: () {
                      setState(() {});
                    },
                  );
                },
              ),
      ),
    );
  }
}
