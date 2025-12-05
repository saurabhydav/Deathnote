class DeathNoteArea extends StatefulWidget {
  @override
  _DeathNoteAreaState createState() => _DeathNoteAreaState();
}

class _DeathNoteAreaState extends State<DeathNoteArea> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _textAnimation;
  String _activeText = "";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 4));
    // Start listening to state changes
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);
    
    // Detect new name
    if (appState.currentName != null && appState.currentName != _activeText && !_controller.isAnimating) {
      _startWriting(appState.currentName!);
    }
  }

  void _startWriting(String name) {
    setState(() {
      _activeText = name;
    });

    _textAnimation = IntTween(begin: 0, end: name.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.reset();
    _controller.forward().then((_) {
      // Delay before next name
      Future.delayed(Duration(seconds: 2), () {
        Provider.of<AppState>(context, listen: false).finishedWriting();
      });
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
              int len = _activeText.isEmpty ? 0 : _textAnimation.value;
              return Text(
                _activeText.substring(0, len),
                style: TextStyle(
                  fontFamily: 'DeathNoteFont', // Ensure this matches pubspec
                  fontSize: 50,
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

    // Draw horizontal lines
    for (double i = 40; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}