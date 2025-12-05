import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

class AvatarArea extends StatefulWidget {
  @override
  _AvatarAreaState createState() => _AvatarAreaState();
}

class _AvatarAreaState extends State<AvatarArea> {
  VideoPlayerController? _controller;

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      File file = File(result.files.single.path!);
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          _controller!.setLooping(true);
          _controller!.play();
          setState(() {});
        });
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
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            )
          else
            Text("Select Avatar Video", style: TextStyle(color: Colors.white)),
          
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _pickVideo,
              child: Icon(Icons.video_library),
            ),
          ),
        ],
      ),
    );
  }
}