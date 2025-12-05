void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'DeathNote Streamer',
        theme: ThemeData.dark(),
        home: HomeScreen(),
      ),
    );
  }
}

6. Build Instructions
Place Font: Download a "Death Note" style font (TTF) and place it in assets/fonts/deathnote.ttf.
API Key: Get a Google Cloud API Key with YouTube Data API v3 enabled.
Run:
flutter pub get
flutter build apk --release

Install: Install the APK on a physical Android device.
Permissions: When you tap "Start Ritual", allow the "Start recording or casting with DeathNote Streamer?" prompt.
How it works effectively:
Frontend: Flutter renders the UI. DeathNoteArea draws the writing animation. AvatarArea plays a looping video.
Backend: When you click start, Flutter calls Native Android.
Capture: Android launches MediaProjection. It captures the entire screen (which is displaying your Flutter UI).
Stream: The StreamService (Foreground Service) takes those screen frames, encodes them to H.264, and pushes them to the YouTube RTMP URL.
Loop: Chat messages are fetched via HTTP in Dart -> Added to Queue -> Displayed on Screen -> Captured by Native -> Streamed to YouTube.