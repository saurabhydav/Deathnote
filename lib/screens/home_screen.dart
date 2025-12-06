import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; 
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
  ChatService? _chatService;
  bool _isPreviewMode = false;

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
      await NativeBridge.stopStream();
      appState.setStreaming(false);
      appState.setPolling(false);
      _timer?.cancel();
    } else {
      String streamKey = _streamKeyController.text.trim();
      String apiKey = _apiKeyController.text.trim();
      String videoId = _videoIdController.text.trim();

      if (streamKey.isEmpty || apiKey.isEmpty || videoId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }

      appState.updateStreamKey(streamKey);
      appState.updateApiKey(apiKey);
      appState.updateVideoId(videoId);

      String endpoint = "rtmp://a.rtmp.youtube.com/live2/$streamKey";
      try {
        await NativeBridge.startStream(endpoint);
        appState.setStreaming(true);
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
    _chatService = ChatService(apiKey); 

    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!appState.isPolling) {
        timer.cancel();
        return;
      }

      if (_chatService != null) {
        List<String> names = await _chatService!.fetchMessages(videoId);
        for (String name in names) {
           if (!appState.names.contains(name)) {
              appState.addName(name);
           }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    bool hideUI = appState.isStreaming || _isPreviewMode;

    return Scaffold(
      appBar: hideUI ? null : AppBar(title: Text("Death Note Streamer")),
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, 
      body: SafeArea(
        child: Stack(
          children: [
            // --- MAIN LAYOUT (50/50 Split) ---
            Column(
              children: [
                // TOP HALF: Death Note (50%)
                Expanded(
                  flex: 50, 
                  child: Stack(
                    children: [
                      // 1. Background Texture
                      Positioned.fill(
                        child: DeathNoteArea(isBackgroundOnly: true),
                      ),
                      
                      // 2. Text Overlay (INSIDE TOP HALF)
                      if (hideUI)
                        Positioned.fill(
                          child: DeathNoteArea(isTextOnly: true),
                        ),
                    ],
                  ),
                ),
                
                // BOTTOM HALF: Avatar Video (50%)
                Expanded(
                  flex: 50, 
                  child: AvatarArea()
                ),
              ],
            ),

            // --- CONTROLS OVERLAY ---
            if (!hideUI)
              Center(
                child: SingleChildScrollView(
                  child: Container(
                    margin: EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[900], 
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white24)
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        Text("STREAM SETUP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        SizedBox(height: 20),
                        TextField(
                          controller: _apiKeyController,
                          decoration: InputDecoration(labelText: "YouTube API Key", border: OutlineInputBorder()),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _videoIdController,
                          decoration: InputDecoration(labelText: "Video ID", border: OutlineInputBorder()),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _streamKeyController,
                          decoration: InputDecoration(labelText: "RTMP Stream Key", border: OutlineInputBorder()),
                          obscureText: true,
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _isPreviewMode = true),
                                child: Text("PREVIEW"),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  foregroundColor: Colors.white, 
                                  side: BorderSide(color: Colors.white54)
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _toggleStreaming(appState),
                                child: Text("GO LIVE"),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  backgroundColor: Colors.red, 
                                  foregroundColor: Colors.white
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),

            // --- STOP BUTTON (Fixed Position) ---
            if (hideUI)
              Positioned(
                top: 10, // moved slightly up but kept safe
                right: 10, // moved slightly right
                child: SafeArea( // Wrap in SafeArea to avoid notch/status bar overlap
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.red.withOpacity(0.4), // More transparent
                    elevation: 0, // remove shadow for cleaner look
                    onPressed: () {
                      if (_isPreviewMode) setState(() => _isPreviewMode = false);
                      else _toggleStreaming(appState);
                    },
                    child: Icon(Icons.stop, color: Colors.white70),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}