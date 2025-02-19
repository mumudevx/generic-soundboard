import 'package:flutter/material.dart';
import 'package:soundboard_app/config/app_config.dart';
import 'package:soundboard_app/screens/favorites_screen.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Map<String, dynamic>> soundButtons;
  final TextEditingController? searchController;
  final bool showFavoritesButton;

  const BaseScreen({
    super.key,
    required this.title,
    required this.body,
    required this.soundButtons,
    this.searchController,
    this.showFavoritesButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: showFavoritesButton 
            ? null 
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        titleSpacing: 48,
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppConfig.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (searchController != null)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search sounds...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    if (showFavoritesButton)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: IconButton(
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FavoritesScreen(
                                  allSoundButtons: soundButtons,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              if (searchController != null) const SizedBox(height: 16),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
} 