import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundboard_app/config/app_config.dart';
import 'package:soundboard_app/services/storage_service.dart';
import 'package:soundboard_app/services/event_bus_service.dart';
import 'package:soundboard_app/events/favorite_events.dart';

class FavoriteChangedNotification extends Notification {
  final String soundId;
  final bool isFavorite;

  FavoriteChangedNotification(this.soundId, this.isFavorite);
}

class SoundButton extends StatefulWidget {
  final String text;
  final String soundPath;
  final Color color;
  final String id;
  final VoidCallback? onFavoriteChanged;

  const SoundButton({
    super.key,
    required this.text,
    required this.soundPath,
    required this.color,
    required this.id,
    this.onFavoriteChanged,
  });

  @override
  State<SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<SoundButton> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  final StorageService _storageService = StorageService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
    _checkFavoriteStatus();
  }

  @override
  void didUpdateWidget(SoundButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFavorite = await _storageService.isFavorite(widget.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
      });
    }
  }

  Future<void> _showFavoriteDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
        content: Text('Do you want to ${_isFavorite ? 'remove' : 'add'} "${widget.text}" ${_isFavorite ? 'from' : 'to'} favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_isFavorite) {
                await _storageService.removeFromFavorites(widget.id);
              } else {
                await _storageService.addToFavorites(widget.id);
              }
              setState(() {
                _isFavorite = !_isFavorite;
              });
              EventBusService.eventBus.fire(FavoriteStatusChanged(widget.id, !_isFavorite));
              widget.onFavoriteChanged?.call();
              Navigator.pop(context);
            },
            child: Text(_isFavorite ? 'Remove' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setAudioSource(AudioSource.asset(widget.soundPath));
      _audioPlayer.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing && state.processingState != ProcessingState.completed;
        });
      });
    } catch (e) {
      debugPrint('${AppConfig.errorInitializingAudio}: $e');
    }
  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
      } else {
        await _audioPlayer.seek(AppConfig.audioSeekDuration);
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('${AppConfig.errorPlayingSound}: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConfig.buttonElevation,
      color: widget.color.withOpacity(AppConfig.buttonOpacity),
      child: InkWell(
        onTap: _playPause,
        onLongPress: _showFavoriteDialog,
        borderRadius: BorderRadius.circular(AppConfig.buttonBorderRadius),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPlaying ? Icons.stop : Icons.play_arrow,
                    size: AppConfig.buttonIconSize,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: AppConfig.buttonTextStyle.copyWith(
                        fontSize: 13.0,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (_isFavorite)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.favorite,
                  size: 16,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BytesAudioSource extends StreamAudioSource {
  final List<int> bytes;
  BytesAudioSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
