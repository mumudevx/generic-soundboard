import 'package:flutter/material.dart';
import 'package:soundboard_app/config/app_config.dart';
import 'package:soundboard_app/screens/favorites_screen.dart';
import 'package:soundboard_app/services/ad_manager.dart';

class BaseScreen extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Map<String, dynamic>> soundButtons;
  final TextEditingController? searchController;
  final bool showFavoritesButton;
  final VoidCallback? onBackPressed;

  const BaseScreen({
    super.key,
    required this.title,
    required this.body,
    required this.soundButtons,
    this.searchController,
    this.showFavoritesButton = true,
    this.onBackPressed,
  });

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  final AdManager _adManager = AdManager();

  @override
  void initState() {
    super.initState();
    _adManager.setStateChangedCallback(() {
      if (mounted) {
        setState(() {});
      }
    });
    _adManager.loadBannerAd();
  }

  @override
  void dispose() {
    _adManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.showFavoritesButton 
            ? null 
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onBackPressed ?? () => Navigator.pop(context),
              ),
        title: Text(
          widget.title,
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
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (widget.searchController != null)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: widget.searchController,
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
                          if (widget.showFavoritesButton)
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
                                        allSoundButtons: widget.soundButtons,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    if (widget.searchController != null) const SizedBox(height: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_adManager.isBannerAdLoaded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 0.5,
                    ),
                  ),
                  child: _adManager.getBannerAdWidget() ?? 
                    const SizedBox(height: 50),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 