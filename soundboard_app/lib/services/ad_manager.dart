import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:soundboard_app/config/app_config.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdLoaded = false;
  bool _isInitialized = false;
  bool _hasShownInterstitial = false;

  factory AdManager() {
    return _instance;
  }

  AdManager._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _hasShownInterstitial = false;
      
      // Load ads only once during initialization
      loadBannerAd();
      await loadInterstitialAd();  // Initial load
      
      debugPrint('AdManager initialized, interstitial ad loading...');
    } catch (e) {
      debugPrint('Failed to initialize AdMob: $e');
    }
  }

  void loadBannerAd() {
    if (!_isInitialized) {
      debugPrint('AdMob not initialized');
      return;
    }

    try {
      _bannerAd?.dispose(); // Dispose existing banner if any
      
      _bannerAd = BannerAd(
        adUnitId: AppConfig.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded successfully');
            _isBannerAdLoaded = true;
            if (_stateChangedCallback != null) {
              _stateChangedCallback!();
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: ${error.message}');
            ad.dispose();
            _isBannerAdLoaded = false;
            _bannerAd = null;
            if (_stateChangedCallback != null) {
              _stateChangedCallback!();
            }
          },
          onAdOpened: (ad) => debugPrint('Banner ad opened'),
          onAdClosed: (ad) => debugPrint('Banner ad closed'),
        ),
      );

      _bannerAd?.load();
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      _isBannerAdLoaded = false;
      _bannerAd = null;
    }
  }

  Widget? getBannerAdWidget() {
    if (!_isInitialized) return null;
    if (!_isBannerAdLoaded || _bannerAd == null) return null;

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  Future<void> loadInterstitialAd() async {
    if (!_isInitialized || _interstitialAd != null) {
      debugPrint('Skipping interstitial ad load: already loaded or not initialized');
      return;
    }

    try {
      debugPrint('Loading initial interstitial ad');
      await InterstitialAd.load(
        adUnitId: AppConfig.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Initial interstitial ad loaded successfully');
            _interstitialAd = ad;
          },
          onAdFailedToLoad: (error) {
            debugPrint('Initial interstitial ad failed to load: $error');
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading initial interstitial ad: $e');
    }
  }

  Future<void> showInterstitialAd() async {
    debugPrint('Attempting to show interstitial ad. Has shown before: $_hasShownInterstitial');
    
    // Check if ad was already shown
    if (_hasShownInterstitial) {
      debugPrint('Interstitial ad was already shown this session, skipping');
      return;
    }

    // Check if ad is available
    if (_interstitialAd == null) {
      debugPrint('No interstitial ad available to show');
      return;
    }

    try {
      debugPrint('Setting up interstitial ad callbacks');
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Interstitial ad dismissed, marking as shown');
          _hasShownInterstitial = true;
          ad.dispose();
          _interstitialAd = null;
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
        },
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Interstitial ad shown successfully, marking as shown');
          _hasShownInterstitial = true;
        },
      );
      
      debugPrint('Showing interstitial ad now');
      await _interstitialAd!.show();
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _isBannerAdLoaded = false;
  }

  bool get isBannerAdLoaded => _isBannerAdLoaded && _bannerAd != null;

  Function? _stateChangedCallback;
  void setStateChangedCallback(Function callback) {
    _stateChangedCallback = callback;
  }
}
