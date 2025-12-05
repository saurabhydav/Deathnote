import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'dart:async';
import '../widgets/deathnote_area.dart';
import '../widgets/avatar_area.dart';
import '../services/native_bridge.dart';
import '../services/chat_service.dart';
import '../providers/app_state.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _videoIdController = TextEditingController();

  Timer? _chatTimer;
  ChatService? _chatService;

  @override
  void initState() {
    super.initState();
 
    // Pre-fill a hint RTMP URL; user must replace <STREAM_KEY>
    _urlController.text = "rtmp://a.rtmp.youtube.com/live2/<YOUR_STREAM_KEY>";
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    _keyController.dispose();
    _urlController.dispose();
    _videoIdController.dispose();
    super.dispose();
  }

  void _toggleStream() async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.isStreaming) {
      await NativeBridge.stopStream();
      appState.setStreaming(false);
      appState.setPolling(false);
      _chatTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stream stopped')));
    } else {
      final endpoint = _urlController.text.trim();
      if (endpoint.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter RTMP URL')));
        return;
      }
      // Save in app state
      appState.updateStreamKey(endpoint);

      // Start native stream (this will request media projection permission)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Requesting screen capture permission...')));
      bool success = await NativeBridge.startStream(endpoint);
      if (success) {
        appState.setStreaming(true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stream started')));
        // Start polling chat if keys are present
        _startChatPolling();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start stream')));
      }
    }
  }

  void _startChatPolling() async {
    final appState = Provider.of<AppState>(context, listen: false);

    final apiKey = _keyController.text.trim();
    final videoId = _videoIdController.text.trim();

    if (apiKey.isEmpty || videoId.isEmpty) {
      // Do not start polling if missing details
      return;
    }

    appState.updateApiKey(apiKey);
    appState.updateVideoId(videoId);

    _chatService = ChatService(apiKey);
    bool connected = await _chatService!.resolveLiveChatId(videoId);

    if (connected) {
      appState.setPolling(true);
      // Poll every 2 seconds (YouTube allows moderate polling; consider using the provided pollIntervalSeconds from API)
      _chatTimer?.cancel();
      _chatTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
        try {
          List<String> names = await _chatService!.fetchMessages();
          final appState = Provider.of<AppState>(context, listen: false);
          for (var name in names) {
            appState.addName(name);
          }
        } catch (e) {
          print('Chat polling error: \$e');
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat polling started')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not resolve liveChatId for the video')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // TOP: Death Note Animation
              Expanded(flex: 1, child: DeathNoteArea()),

              // BOTTOM: Avatar Video
              Expanded(flex: 1, child: AvatarArea()),
            ],
          ),

          // Controls Overlay (visible when not streaming)
          if (!appState.isStreaming)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                padding: EdgeInsets.all(20),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _keyController,
                          decoration: InputDecoration(
                            labelText: 'YouTube API Key',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _videoIdController,
                          decoration: InputDecoration(
                            labelText: 'Live Video ID',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: 'RTMP URL (rtmp://a.rtmp.youtube.com/live2/<STREAM_KEY>)',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _toggleStream,
                          child: Text("START RITUAL"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Stop Button (Small)
          if (appState.isStreaming)
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.stop_circle, color: Colors.red, size: 40),
                onPressed: _toggleStream,
              ),
            )
        ],
      ),
    );
  }
}
