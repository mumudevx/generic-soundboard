import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundboard_app/config/app_config.dart';

class SoundButton extends StatefulWidget {
  final String text;
  final String soundPath;
  final Color color;

  const SoundButton({
    super.key,
    required this.text,
    required this.soundPath,
    required this.color,
  });

  @override
  State<SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<SoundButton> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
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
        borderRadius: BorderRadius.circular(AppConfig.buttonBorderRadius),
        child: Padding(
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
              Text(
                widget.text,
                textAlign: TextAlign.center,
                style: AppConfig.buttonTextStyle.copyWith(
                  fontSize: 13.0,
                  height: 1.2,
                ),
              ),
            ],
          ),
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
