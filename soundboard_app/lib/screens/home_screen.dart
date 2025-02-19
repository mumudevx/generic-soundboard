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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  static const int _batchSize = 9;
  bool _isLoadingMore = false;
  bool _isLoadingPrevious = false;
  int _startIndex = 0;

  int _calculateInitialButtonCount(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonHeight = (MediaQuery.of(context).size.width - 32 - 24) /
        3; // (screen width - padding - spacing) / 3 columns
    final availableHeight =
        screenHeight - 100; // Approximate space for AppBar and padding
    final rowCount =
        (availableHeight / (buttonHeight + 12)).floor(); // height + spacing
    return (rowCount * 3) + 3; // rows * columns + extra row for scroll
  }

  @override
  void initState() {
    super.initState();
    loadMetadata();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    
    // Listen to favorite changes
    EventBusService.eventBus.on<FavoriteStatusChanged>().listen((event) {
      setState(() {
        // This will trigger a rebuild of all buttons
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when reaching bottom
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore) {
      _loadMoreItems();
    }

    // Load previous when reaching top
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 100 &&
        !_isLoadingPrevious &&
        _startIndex > 0) {
      _loadPreviousItems();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredButtons = soundButtons;
      } else {
        filteredButtons = soundButtons
            .where((button) =>
                button['text'].toString().toLowerCase().contains(query))
            .toList();
      }
      _startIndex = 0;
      displayedButtons =
          filteredButtons.take(_calculateInitialButtonCount(context)).toList();
    });
  }

  void _loadMoreItems() {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      final remainingItems =
          filteredButtons.length - (_startIndex + displayedButtons.length);
      final itemsToAdd =
          remainingItems < _batchSize ? remainingItems : _batchSize;

      if (itemsToAdd > 0) {
        displayedButtons.addAll(filteredButtons.getRange(
            _startIndex + displayedButtons.length,
            _startIndex + displayedButtons.length + itemsToAdd));
      }
      _isLoadingMore = false;
    });
  }

  void _loadPreviousItems() async {
    if (_isLoadingPrevious) return;
    setState(() {
      _isLoadingPrevious = true;
    });

    final itemsToAdd = _startIndex < _batchSize ? _startIndex : _batchSize;
    if (itemsToAdd > 0) {
      _startIndex -= itemsToAdd;
      final newItems = filteredButtons
          .getRange(_startIndex, _startIndex + itemsToAdd)
          .toList();

      final currentPosition = _scrollController.position.pixels;
      setState(() {
        displayedButtons.insertAll(0, newItems);
      });
      await Future.delayed(Duration.zero);
      _scrollController.jumpTo(currentPosition + (itemsToAdd * 120));
    }

    setState(() {
      _isLoadingPrevious = false;
    });
  }

  Future<void> loadMetadata() async {
    try {
      final String jsonString =
          await rootBundle.loadString('lib/config/metadata.json');
      final Map<String, dynamic> metadata = json.decode(jsonString);
      setState(() {
        soundButtons = List<Map<String, dynamic>>.from(metadata['buttons']);
        filteredButtons = soundButtons;
        title = metadata['title'] ?? AppConfig.appName;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final initialCount = _calculateInitialButtonCount(context);
          _startIndex = 0;
          displayedButtons = filteredButtons.take(initialCount).toList();
          setState(() {});
        });
      });
    } catch (e) {
      print('Error loading metadata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<FavoriteChangedNotification>(
      onNotification: (notification) {
        setState(() {}); // Rebuild the screen when favorite changes
        return true;
      },
      child: BaseScreen(
        title: title,
        searchController: _searchController,
        soundButtons: soundButtons,
        body: displayedButtons.isEmpty
            ? const Center(child: Text('No sounds found'))
            : GridView.builder(
                controller: _scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                ),
                itemCount: displayedButtons.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= displayedButtons.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final button = displayedButtons[index];
                  return SoundButton(
                    text: button['text'],
                    soundPath: 'assets/${button['localPath']}',
                    color: AppConfig.getButtonColor(_startIndex + index),
                    id: button['id'],
                    onFavoriteChanged: () {
                      // Refresh all buttons when favorite status changes
                      setState(() {
                        // This will trigger a rebuild of all buttons
                      });
                    },
                  );
                },
              ),
      ),
    );
  }
}
