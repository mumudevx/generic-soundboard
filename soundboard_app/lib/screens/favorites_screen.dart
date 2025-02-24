import 'package:flutter/material.dart';
import 'package:soundboard_app/widgets/base_screen.dart';
import 'package:soundboard_app/services/storage_service.dart';
import 'package:soundboard_app/widgets/sound_button.dart';
import 'package:soundboard_app/config/app_config.dart';
import 'package:soundboard_app/services/ad_manager.dart';

class FavoritesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allSoundButtons;

  const FavoritesScreen({
    super.key,
    required this.allSoundButtons,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> favoriteButtons = [];
  List<Map<String, dynamic>> displayedButtons = [];
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _searchController.addListener(_onSearchChanged);
    AdManager().loadInterstitialAd();  // Load the ad when screen opens
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
        displayedButtons = List.from(favoriteButtons); // Create a new copy
      } else {
        displayedButtons = favoriteButtons
            .where((button) =>
                button['text'].toString().toLowerCase().contains(query))
            .map((button) => Map<String, dynamic>.from(button)) // Create a new copy of each button
            .toList();
      }
      
      // Debug logs
      print('Favorites Search Query: $query');
      for (var button in displayedButtons) {
        print('Favorite Button ID: ${button['id']}, Text: ${button['text']}, Sound: ${button['localPath']}');
      }
    });
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _storageService.getFavorites();

      setState(() {
        favoriteButtons = favorites
            .map((id) {
              return widget.allSoundButtons.firstWhere(
                (button) => button['id'] == id,
                orElse: () {
                  return <String, dynamic>{};
                },
              );
            })
            .where((button) => button.isNotEmpty)
            .toList();

        displayedButtons = favoriteButtons;
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<bool> _onWillPop() async {
    await AdManager().showInterstitialAd();
    Navigator.of(context).pop(); // Explicitly pop the screen
    return false; // Return false to prevent default back behavior
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: BaseScreen(
        title: 'Favorite Sounds',
        searchController: _searchController,
        showFavoritesButton: false,
        soundButtons: widget.allSoundButtons,
        onBackPressed: () async {  // Add this callback
          await _onWillPop();
        },
        body: displayedButtons.isEmpty
            ? const Center(child: Text('No favorite sounds yet'))
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
                    color: AppConfig.getButtonColor(button['id']),
                    id: button['id'],
                    onFavoriteChanged: _loadFavorites,
                  );
                },
              ),
      ),
    );
  }
}
