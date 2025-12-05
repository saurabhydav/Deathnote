import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Required for Timer
import '../providers/app_state.dart';
import '../services/native_bridge.dart';
import '../services/chat_service.dart';
import '../widgets/deathnote_area.dart';
import '../widgets/avatar_area.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _streamKeyController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _videoIdController = TextEditingController();
  
  Timer? _timer;
  ChatService? _chatService; // Keep this nullable

  @override
  void dispose() {
    _streamKeyController.dispose();
    _apiKeyController.dispose();
    _videoIdController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggleStreaming(AppState appState) async {
    if (appState.isStreaming) {
      // Stop Streaming
      await NativeBridge.stopStream();
      appState.setStreaming(false);
      appState.setPolling(false);
      _timer?.cancel();
    } else {
      // Start Streaming
      String streamKey = _streamKeyController.text.trim();
      String apiKey = _apiKeyController.text.trim();
      String videoId = _videoIdController.text.trim();

      if (streamKey.isEmpty || apiKey.isEmpty || videoId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }

      // Update State
      appState.updateStreamKey(streamKey);
      appState.updateApiKey(apiKey);
      appState.updateVideoId(videoId);

      // Start Native Stream
      String endpoint = "rtmp://a.rtmp.youtube.com/live2/$streamKey";
      try {
        await NativeBridge.startStream(endpoint);
        appState.setStreaming(true);

        // Start Chat Polling
        _startChatPolling(appState, apiKey, videoId);
        
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start stream: $e')),
        );
      }
    }
  }

  void _startChatPolling(AppState appState, String apiKey, String videoId) async {
    appState.setPolling(true);
    
    // Initialize Chat Service (No constructor arguments needed based on your service code)
    // If you need to pass API key, modify ChatService, but for now we pass it to methods directly
    _chatService = ChatService(); 

    // Verify Chat ID
    // Note: ensure your ChatService has this method. If not, we skip validation for now.
    // For this fix, I will assume simple fetching loop:
    
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!appState.isPolling) {
        timer.cancel();
        return;
      }

      // Fetch messages
      List<String> names = await ChatService.fetchChatMessages(videoId, apiKey);
      
      for (String name in names) {
         // Add to queue if not duplicate/already processed logic (simplified here)
         if (!appState.names.contains(name)) {
            appState.addName(name);
         }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Death Note Streamer")),
      body: Column(
        children: [
          // Inputs Area
          if (!appState.isStreaming)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(labelText: "YouTube API Key"),
                  ),
                  TextField(
                    controller: _videoIdController,
                    decoration: InputDecoration(labelText: "Video ID (Live Stream)"),
                  ),
                  TextField(
                    controller: _streamKeyController,
                    decoration: InputDecoration(labelText: "RTMP Stream Key"),
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _toggleStreaming(appState),
                    child: Text("Start Ritual (Stream)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  )
                ],
              ),
            ),

          // Main Visual Area (Always visible, but active when streaming)
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 1, child: DeathNoteArea()),
                Expanded(flex: 1, child: AvatarArea()),
              ],
            ),
          ),
          
          if (appState.isStreaming)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () => _toggleStreaming(appState),
                child: Text("Stop Ritual"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),
            )
        ],
      ),
    );
  }
}