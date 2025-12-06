import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';

class AvatarArea extends StatefulWidget {
  const AvatarArea({Key? key}) : super(key: key);
  @override
  AvatarAreaState createState() => AvatarAreaState();
}

class AvatarAreaState extends State<AvatarArea> {
  VideoPlayerController? _controller;
  bool _isLoading = false;

  Future<void> pickVideo() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) await Permission.storage.request();
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: false);
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        _controller?.dispose();
        _controller = VideoPlayerController.file(file, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
        await _controller!.initialize();
        await _controller!.setLooping(true);
        await _controller!.setVolume(1.0);
        await _controller!.play();
        _controller!.addListener(() {
          if (!_controller!.value.isPlaying && _controller!.value.position >= _controller!.value.duration) {
            _controller!.seekTo(Duration.zero);
            _controller!.play();
          }
        });
        if (mounted) setState(() {});
      }
    } catch (e) {
      print("AvatarArea Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            SizedBox.expand(child: FittedBox(fit: BoxFit.cover, child: SizedBox(width: _controller!.value.size.width, height: _controller!.value.size.height, child: VideoPlayer(_controller!))))
          else
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.movie_creation_outlined, size: 50, color: Colors.white54), SizedBox(height: 10), Text(_isLoading ? "Loading..." : "Select Avatar Video", style: TextStyle(color: Colors.white))]),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}