import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PlantsPage extends StatefulWidget {
  const PlantsPage({super.key});
  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  late final WebViewController _webController;

  // Script JavaScript para ocultar la barra azul de Node-RED Dashboard
  final String _hideNavbarJS = r"""
    function hideTop() {
      // Node-RED Dashboard v1 (Angular)
      var t1 = document.getElementById('nr-dashboard-toolbar');
      if (t1) { t1.style.display='none'; t1.style.height='0'; t1.style.minHeight='0'; }
      var t2 = document.querySelector('md-toolbar');
      if (t2) { t2.style.display='none'; t2.style.height='0'; t2.style.minHeight='0'; }

      // Node-RED Dashboard v2 (Vue / FlowFuse)
      var t3 = document.querySelector('.nrdb-header, .dashboard-header, .v-app-bar');
      if (t3) { t3.style.display='none'; t3.style.height='0'; t3.style.minHeight='0'; }

      // Elimina márgenes/rellenos superiores
      ['body','#ui-view','.nr-dashboard-container','main','#app'].forEach(sel=>{
        var n = document.querySelector(sel);
        if (n) { n.style.marginTop='0'; n.style.paddingTop='0'; }
      });

      // Ajusta el contenedor principal
      var content = document.querySelector('.nr-dashboard-template, .v-main, .nrdb-content, .nrdb-page');
      if (content) { content.style.paddingTop='0'; content.style.marginTop='0'; }
    }
    hideTop();
    // Vuelve a ocultar si el dashboard se re-renderiza
    new MutationObserver(hideTop).observe(document.documentElement, {childList:true, subtree:true});
  """;

  @override
  void initState() {
    super.initState();

    _webController = WebViewController()
      ..setBackgroundColor(const Color(0x00000000))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _webController.runJavaScript(_hideNavbarJS);
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          // panel de plantas (monitoreo)
          'https://hydrogrow.flowfuse.cloud/ui/#!/1?kiosk=1',
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: WebViewWidget(controller: _webController),
        ),
      ),
    );
  }
}
