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
  String name = "Target Name"; // Placeholder

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 4));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    // You can listen to appState here if needed to trigger animations
    if (appState.isPolling) {
       // logic to start writing
       _startWriting(name);
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
              String currentText = name.substring(0, _textAnimation.value);
              return Text(
                currentText,
                style: TextStyle(
                  fontFamily: 'DeathNote', // Make sure this font is in pubspec.yaml
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