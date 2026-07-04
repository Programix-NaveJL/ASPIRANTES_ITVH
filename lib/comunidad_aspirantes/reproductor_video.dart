// ═════════════════════════════════════════════════════════════════
// reproductor_video.dart — Aspirantes ITVH
//
// Pantalla simple de reproducción de video a pantalla completa.
// Se abre desde el ícono de play en el carrusel de una publicación.
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';

class ReproductorVideo extends StatefulWidget {
  final String url;

  const ReproductorVideo({super.key, required this.url});

  @override
  State<ReproductorVideo> createState() => _ReproductorVideoState();
}

class _ReproductorVideoState extends State<ReproductorVideo> {
  late final VideoPlayerController _controller;
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _listo = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: _listo
            ? GestureDetector(
          onTap: _togglePlay,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              if (!_controller.value.isPlaying)
                const Icon(CupertinoIcons.play_circle_fill,
                    size: 64, color: Colors.white70),
            ],
          ),
        )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}