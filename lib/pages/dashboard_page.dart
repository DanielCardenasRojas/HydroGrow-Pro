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

  /// Color de acento para tu marca (HEX con #)
  static const String _accentHex = '#34C759'; // verde iOS / cámbialo si quieres

  @override
  void initState() {
    super.initState();

    _chartsController = WebViewController()
      ..setBackgroundColor(const Color(0x00000000))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            await _chartsController.runJavaScript(_hideBarsJS);
            await _applyTheme(_chartsController);
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://hydrogrow.flowfuse.cloud/ui/#!/0?kiosk=1'),
      );

    _switchesController = WebViewController()
      ..setBackgroundColor(const Color(0x00000000))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            await _switchesController.runJavaScript(_hideBarsJS);
            await _applyTheme(_switchesController);
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://hydrogrow.flowfuse.cloud/ui/#!/2?kiosk=1'),
      );
  }

  /// Oculta toolbars/headers de Node-RED Dashboard (v1 y v2)
  final String _hideBarsJS = r"""
    (function hideTop() {
      var t1 = document.getElementById('nr-dashboard-toolbar');
      if (t1) { t1.style.display='none'; t1.style.height='0'; t1.style.minHeight='0'; }
      var t2 = document.querySelector('md-toolbar');
      if (t2) { t2.style.display='none'; t2.style.height='0'; t2.style.minHeight='0'; }

      var t3 = document.querySelector('.nrdb-header, .dashboard-header, .v-app-bar');
      if (t3) { t3.style.display='none'; t3.style.height='0'; t3.style.minHeight='0'; }

      ['body','#ui-view','.nr-dashboard-container','main','#app'].forEach(sel=>{
        var n = document.querySelector(sel);
        if (n) { n.style.marginTop='0'; n.style.paddingTop='0'; }
      });

      var content = document.querySelector('.nr-dashboard-template, .v-main, .nrdb-content, .nrdb-page');
      if (content) { content.style.paddingTop='0'; content.style.marginTop='0'; }
    })();
    new MutationObserver(()=>{ try { hideTop(); } catch(e){} })
      .observe(document.documentElement, {childList:true, subtree:true});
  """;

  /// Genera CSS para claro/oscuro con tu color de acento
  String _cssFor({required bool dark}) {
    final accent = _accentHex;
    // Colores base
    final bg = dark ? '#0B0B0C' : '#F2F2F7';
    final card = dark ? '#1C1C1E' : '#FFFFFF';
    final text = dark ? '#FFFFFF' : '#111111';
    final sub = dark ? '#9A9AA1' : '#6B7280';
    final border = dark ? '#2C2C2E' : '#E5E7EB';

    // CSS dirigido a clases comunes de Node-RED Dashboard v1/v2
    return """
      :root {
        --hydro-accent: $accent;
        --hydro-bg: $bg;
        --hydro-card: $card;
        --hydro-text: $text;
        --hydro-sub: $sub;
        --hydro-border: $border;
        --hydro-radius: 16px;
        --hydro-shadow: 0 6px 20px rgba(0,0,0,${dark ? '0.35' : '0.08'});
      }

      html, body, #app, .nr-dashboard-container, .nrdb-content, .v-application {
        background: var(--hydro-bg) !important;
        color: var(--hydro-text) !important;
        font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text',
                     'Helvetica Neue', Helvetica, Arial, 'Segoe UI', sans-serif !important;
      }

      /* Tarjetas / paneles */
      .nr-dashboard-template, .nrdb-card, .v-card, .card-panel, md-card, .nrdb-widget, .v-sheet {
        background: var(--hydro-card) !important;
        color: var(--hydro-text) !important;
        border-radius: var(--hydro-radius) !important;
        box-shadow: var(--hydro-shadow) !important;
        border: 1px solid var(--hydro-border) !important;
      }

      /* Títulos y subtítulos */
      .nr-dashboard-template h1, .nr-dashboard-template h2, .nr-dashboard-template h3,
      .v-card-title, .v-toolbar-title, .nrdb-card-title, .md-title {
        color: var(--hydro-text) !important;
        font-weight: 700 !important;
        letter-spacing: .2px;
      }
      .nrdb-subtitle, .v-card-subtitle, .md-subhead, .caption, .helper-text {
        color: var(--hydro-sub) !important;
      }

      /* Botones / toggles / sliders con color de acento */
      .md-button, .v-btn, .v-switch--inset .v-input--selection-controls__ripple,
      .v-slider .v-slider-track__fill, .v-slider .v-slider-thumb,
      .btn, .button, .nrdb-button {
        background: var(--hydro-accent) !important;
        color: #fff !important;
        border-radius: 12px !important;
      }
      .v-switch .v-input--selection-controls__ripple { background: var(--hydro-accent) !important; }
      .v-switch .v-selection-control__input:checked + .v-selection-control__wrapper .v-switch__track {
        background: var(--hydro-accent) !important;
      }

      /* Inputs */
      input, select, textarea, .v-text-field, .nrdb-input, .md-input {
        background: var(--hydro-card) !important;
        color: var(--hydro-text) !important;
        border-radius: 12px !important;
        border: 1px solid var(--hydro-border) !important;
      }

      /* Tablas */
      table, .v-table, .md-table-content {
        background: var(--hydro-card) !important;
        color: var(--hydro-text) !important;
        border-radius: 12px !important;
      }
      th, td { border-color: var(--hydro-border) !important; }

      /* Espaciado */
      .nrdb-card, .v-card, .v-sheet, .nr-dashboard-template, .card-panel {
        margin: 8px !important;
        padding: 12px !important;
      }

      /* Quita bordes y headers sobrantes */
      .nrdb-header, .dashboard-header, .v-app-bar, md-toolbar, #nr-dashboard-toolbar {
        display: none !important;
      }
    """;
  }

  /// Inyecta el CSS generado en la página
  Future<void> _applyTheme(WebViewController c) async {
    final isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;

    final css = _cssFor(
      dark: isDark,
    ).replaceAll('\n', ' ').replaceAll("'", r"\'");

    final js =
        """
      (function(){
        try {
          var old = document.getElementById('hydro-style');
          if (old) old.remove();
          var style = document.createElement('style');
          style.id = 'hydro-style';
          style.type = 'text/css';
          style.appendChild(document.createTextNode('$css'));
          document.head.appendChild(style);
        } catch(e) {}
      })();
    """;
    await c.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
      ),
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
                height: 280,
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
