import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:soundboard_app/config/app_config.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdLoaded = false;
  bool _isInitialized = false;
  bool _hasShownInterstitial = false;  // This will reset when app restarts

  factory AdManager() {
    return _instance;
  }

  AdManager._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _hasShownInterstitial = false; // Reset flag on initialization
      loadBannerAd();
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
    if (!_isInitialized || _hasShownInterstitial) {
      debugPrint('Skipping interstitial ad load: initialized=$_isInitialized, hasShown=$_hasShownInterstitial');
      return;
    }

    try {
      await InterstitialAd.load(
        adUnitId: AppConfig.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded successfully');
            _interstitialAd = ad;
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: ${error.message}');
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
    }
  }

  Future<void> showInterstitialAd() async {
    if (!_isInitialized || _hasShownInterstitial || _interstitialAd == null) {
      debugPrint('Skipping interstitial ad show: initialized=$_isInitialized, hasShown=$_hasShownInterstitial, adLoaded=${_interstitialAd != null}');
      return;
    }

    try {
      _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Interstitial ad dismissed');
          ad.dispose();
          _interstitialAd = null;
          _hasShownInterstitial = true;
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
        },
      );
      
      await _interstitialAd?.show();
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
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
