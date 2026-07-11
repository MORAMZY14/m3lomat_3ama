import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../core/app_theme.dart';

class AudioPlayerCard extends StatefulWidget {
  const AudioPlayerCard({required this.url, super.key});

  final String url;

  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  final AudioPlayer _player = AudioPlayer();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _player.setUrl(widget.url);
    } catch (_) {
      _error = 'تعذّر تحميل الملف الصوتي';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
    if (_error != null) return Text(_error!, style: const TextStyle(color: AppColors.red));

    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton.filled(
                  onPressed: () => playing ? _player.pause() : _player.play(),
                  icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('السؤال الصوتي', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  onPressed: () => _player.seek(Duration.zero),
                  icon: const Icon(Icons.replay_rounded),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
