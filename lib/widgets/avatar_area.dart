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
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              mini: true,
              onPressed: _pickVideo,
              child: Icon(Icons.video_library),
            ),
          )
        ],
      ),
    );
  }
}