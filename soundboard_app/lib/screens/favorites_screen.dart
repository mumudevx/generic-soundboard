import 'package:flutter/material.dart';
import 'package:soundboard_app/widgets/base_screen.dart';
import 'package:soundboard_app/services/storage_service.dart';
import 'package:soundboard_app/widgets/sound_button.dart';
import 'package:soundboard_app/config/app_config.dart';

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
        displayedButtons = favoriteButtons;
      } else {
        displayedButtons = favoriteButtons
            .where((button) =>
                button['text'].toString().toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _storageService.getFavorites();
      print('Loaded favorites: $favorites');

      setState(() {
        favoriteButtons = favorites.map((id) {
          return widget.allSoundButtons.firstWhere(
            (button) => button['id'] == id,
            orElse: () {
              print('Button not found for id: $id');
              return <String, dynamic>{};
            },
          );
        })
        .where((button) => button.isNotEmpty)
        .toList();

        print('Processed favorite buttons: $favoriteButtons');
        displayedButtons = favoriteButtons;
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Favorite Sounds',
      searchController: _searchController,
      showFavoritesButton: false,
      soundButtons: widget.allSoundButtons,
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
                  color: AppConfig.getButtonColor(index),
                  id: button['id'],
                  onFavoriteChanged: _loadFavorites,
                );
              },
            ),
    );
  }
} 