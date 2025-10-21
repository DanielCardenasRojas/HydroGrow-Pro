import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final WebViewController _chartsController;
  late final WebViewController _switchesController;

  @override
  void initState() {
    super.initState();

    // Controlador del panel de gráficas
    _chartsController = WebViewController()
      ..setBackgroundColor(const Color(0x00000000))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _chartsController.runJavaScript(_hideNavbarJS);
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://hydrogrow.flowfuse.cloud/ui/#!/0?kiosk=1'),
      );

    // Controlador del panel de switches
    _switchesController = WebViewController()
      ..setBackgroundColor(const Color(0x00000000))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _switchesController.runJavaScript(_hideNavbarJS);
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://hydrogrow.flowfuse.cloud/ui/#!/2?kiosk=1'),
      );
  }

  // Script JS para ocultar barra superior en Node-RED Dashboard v1/v2
  final String _hideNavbarJS = r"""
    function hideTop() {
      // Dashboard v1 (Angular)
      var t1 = document.getElementById('nr-dashboard-toolbar');
      if (t1) { t1.style.display='none'; t1.style.height='0'; t1.style.minHeight='0'; }
      var t2 = document.querySelector('md-toolbar');
      if (t2) { t2.style.display='none'; t2.style.height='0'; t2.style.minHeight='0'; }

      // Dashboard v2 (Vue / FlowFuse)
      var t3 = document.querySelector('.nrdb-header, .dashboard-header, .v-app-bar');
      if (t3) { t3.style.display='none'; t3.style.height='0'; t3.style.minHeight='0'; }

      // Quita márgenes/rellenos superiores
      ['body','#ui-view','.nr-dashboard-container','main','#app'].forEach(sel=>{
        var n = document.querySelector(sel);
        if (n) { n.style.marginTop='0'; n.style.paddingTop='0'; }
      });

      // Ajusta el contenedor principal
      var content = document.querySelector('.nr-dashboard-template, .v-main, .nrdb-content, .nrdb-page');
      if (content) { content.style.paddingTop='0'; content.style.marginTop='0'; }
    }
    hideTop();
    // Observa cambios para volver a ocultar si se re-renderiza
    new MutationObserver(hideTop).observe(document.documentElement, {childList:true, subtree:true});
  """;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // === WebView superior: gráficas ===
            SliverToBoxAdapter(
              child: SizedBox(
                height: 320,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: WebViewWidget(controller: _chartsController),
                ),
              ),
            ),

            // === WebView inferior: switches ===
            SliverToBoxAdapter(
              child: SizedBox(
                height: 280, // ajusta según el tamaño del panel de switches
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: WebViewWidget(controller: _switchesController),
                ),
              ),
            ),

            // === Tarjeta placeholder (opcional) ===
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _Card(
                  height: 140,
                  child: const Center(
                    child: Text('Gráficas históricas (próximamente)'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta con esquinas iOS
class _Card extends StatelessWidget {
  final double? width, height;
  final Widget child;
  const _Card({this.width, this.height, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
