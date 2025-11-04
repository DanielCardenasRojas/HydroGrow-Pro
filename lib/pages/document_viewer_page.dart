import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';

class DocumentViewerPage extends StatefulWidget {
  final String title;
  final String assetPath;
  const DocumentViewerPage({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  String _content = 'Cargando…';

  @override
  void initState() {
    super.initState();
    rootBundle.loadString(widget.assetPath).then((value) {
      if (mounted) setState(() => _content = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        previousPageTitle: 'Atrás',
      ),
      child: SafeArea(
        bottom: false,
        child: Markdown(
          data: _content,
          styleSheet:
              MarkdownStyleSheet.fromCupertinoTheme(
                CupertinoTheme.of(context),
              ).copyWith(
                h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                p: const TextStyle(fontSize: 15, height: 1.35),
              ),
        ),
      ),
    );
  }
}
