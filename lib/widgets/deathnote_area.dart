import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class DeathNoteArea extends StatefulWidget {
  @override
  _DeathNoteAreaState createState() => _DeathNoteAreaState();
}

class _DeathNoteAreaState extends State<DeathNoteArea> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _textAnimation;
  String name = "Death Note"; // Default text

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 4));
    
    // FIX: We must initialize this immediately to prevent the "LateInitializationError" crash
    _textAnimation = IntTween(begin: 0, end: 0).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    
    // If we are polling (streaming) and have names in the queue, start writing
    if (appState.isPolling && appState.names.isNotEmpty) {
       _startWriting(appState.names.last);
    }
  }

  void _startWriting(String targetName) {
    setState(() {
      name = targetName;
      _textAnimation = IntTween(begin: 0, end: name.length).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    });
    _controller.forward().then((_) {
        // When animation finishes, tell AppState we are done
        Provider.of<AppState>(context, listen: false).finishedWriting();
        _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: EdgeInsets.all(20),
      child: CustomPaint(
        painter: NotebookPainter(),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Safety check to ensure we don't crash if text length changes
              int length = _textAnimation.value;
              if (length > name.length) length = name.length;
              
              String currentText = name.substring(0, length);
              
              return Text(
                currentText,
                style: TextStyle(
                  // fontFamily: 'DeathNote', // Uncomment if you added the font file
                  fontSize: 40,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  shadows: [Shadow(color: Colors.red, blurRadius: 10)],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class NotebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (double i = 40; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}