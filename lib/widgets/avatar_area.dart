import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart'; // Import this

class AvatarArea extends StatefulWidget {
  @override
  _AvatarAreaState createState() => _AvatarAreaState();
}

class _AvatarAreaState extends State<AvatarArea> {
  VideoPlayerController? _controller;
  bool _isLoading = false;

  Future<void> _pickVideo() async {
    if (_isLoading) return; // Prevent double clicks

    setState(() => _isLoading = true);
    print("AvatarArea: Pick Video button clicked.");

    try {
      // 1. Check Permissions Explicitly
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
           // Also check media permissions for Android 13+
           var videoStatus = await Permission.videos.status;
           if (!videoStatus.isGranted) {
              videoStatus = await Permission.videos.request();
           }
           
           if (!videoStatus.isGranted && !status.isGranted) {
             print("AvatarArea: Permission denied.");
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Permission needed to pick video')),
             );
             setState(() => _isLoading = false);
             return;
           }
        }
      }

      // 2. Pick File
      print("AvatarArea: Opening File Picker...");
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;
        print("AvatarArea: File picked at $path");

        File file = File(path);
        
        // Dispose old controller
        _controller?.dispose();

        // Initialize new controller
        _controller = VideoPlayerController.file(file);
        await _controller!.initialize();
        _controller!.setLooping(true);
        _controller!.play();
        
        print("AvatarArea: Video initialized and playing.");
        
        if (mounted) {
          setState(() {});
        }
      } else {
        print("AvatarArea: Picker cancelled or failed.");
      }
    } catch (e) {
      print("AvatarArea: Error picking video: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video Layer
          if (_controller != null && _controller!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            // Placeholder Layer
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_creation_outlined, size: 50, color: Colors.white54),
                SizedBox(height: 10),
                Text(
                  _isLoading ? "Loading..." : "Select Avatar Video",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          
          // Floating Button Layer (Ensured Z-Index is top)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: "avatar_fab", // Unique tag to avoid conflicts
              onPressed: _pickVideo,
              backgroundColor: _isLoading ? Colors.grey : Colors.red,
              child: _isLoading 
                  ? CircularProgressIndicator(color: Colors.white) 
                  : Icon(Icons.folder_open),
            ),
          ),
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