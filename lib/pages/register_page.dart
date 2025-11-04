import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();

  bool _acceptPrivacy = false;
  bool _acceptProtection = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _success = false;

  late AnimationController _popController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _popController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    _popController.dispose();
    super.dispose();
  }

  // ================== VALIDACIONES ==================
  bool get hasLetter => RegExp(r'[a-zA-Z]').hasMatch(_pass.text);
  bool get hasUpper => RegExp(r'[A-Z]').hasMatch(_pass.text);
  bool get hasNumber => RegExp(r'[0-9]').hasMatch(_pass.text);
  bool get hasSpecial =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(_pass.text);
  bool get hasMinLength => _pass.text.length >= 8;
  bool get hasNoSpaces => !_pass.text.contains(' ');
  bool get passwordsMatch =>
      _confirm.text.isNotEmpty && _pass.text == _confirm.text;

  // ================== REGISTRO ==================
  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) return _alert('Escribe tu nombre.');
    if (!_email.text.contains('@')) return _alert('Correo inválido.');
    if (!hasLetter ||
        !hasUpper ||
        !hasNumber ||
        !hasSpecial ||
        !hasMinLength ||
        !hasNoSpaces ||
        !passwordsMatch) {
      return _alert('La contraseña no cumple con los requisitos establecidos.');
    }
    if (!_acceptPrivacy || !_acceptProtection) {
      return _alert('Debes aceptar ambos documentos antes de continuar.');
    }

    try {
      setState(() {
        _loading = true;
        _success = false;
      });

      await _auth.registerSafe(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _pass.text,
      );

      if (!mounted) return;

      // ✅ Animación
      setState(() => _success = true);
      _popController.forward();
      HapticFeedback.mediumImpact();

      // Espera un poco para mostrar la palomita antes de redirigir
      await Future.delayed(const Duration(milliseconds: 1800));

      // ✅ Cierra sesión y redirige al LoginPage
      await _auth.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _alert(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _popController.reset();
      }
    }
  }

  // ================== ALERTAS ==================
  void _alert(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Aviso'),
        content: Text('\n$msg'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ================== CHECKLIST ==================
  Widget _checkItem(bool valid, String text, Color color) {
    return Row(
      children: [
        Icon(
          valid
              ? CupertinoIcons.check_mark_circled_solid
              : CupertinoIcons.clear_circled_solid,
          size: 18,
          color: valid
              ? CupertinoColors.activeGreen
              : CupertinoColors.systemRed,
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }

  Widget _buildChecklist(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'La contraseña debe cumplir los siguientes requisitos:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        _checkItem(hasLetter, 'Al menos una letra', color),
        _checkItem(hasUpper, 'Al menos una letra mayúscula', color),
        _checkItem(hasNumber, 'Al menos un número', color),
        _checkItem(
          hasSpecial,
          'Al menos un carácter especial (@, #, !, etc.)',
          color,
        ),
        _checkItem(hasMinLength, 'Mínimo 8 caracteres', color),
        _checkItem(passwordsMatch, 'Las contraseñas deben coincidir', color),
        _checkItem(hasNoSpaces, 'Sin espacios', color),
      ],
    );
  }

  // ================== DOCUMENTOS ==================
  Future<void> _openAssetDialog(String title, String assetPath) async {
    try {
      final text = await DefaultAssetBundle.of(context).loadString(assetPath);
      await showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(text, style: const TextStyle(fontSize: 13)),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (_) {
      _alert('No se pudo cargar el documento $title.');
    }
  }

  // ================== INTERFAZ ==================
  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark
        ? CupertinoColors.black
        : CupertinoColors.systemGroupedBackground;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;

    return Stack(
      children: [
        CupertinoPageScaffold(
          backgroundColor: bgColor,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    CupertinoIcons.leaf_arrow_circlepath,
                    size: 80,
                    color: CupertinoColors.activeGreen,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Registro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.activeGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInput(
                    _name,
                    'Nombre completo',
                    CupertinoIcons.person,
                    textColor,
                  ),
                  const SizedBox(height: 14),
                  _buildInput(
                    _email,
                    'Correo electrónico',
                    CupertinoIcons.at,
                    textColor,
                    keyboard: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _buildPasswordField(textColor),
                  const SizedBox(height: 14),
                  _buildConfirmPasswordField(textColor),
                  const SizedBox(height: 20),
                  _buildChecklist(textColor),
                  const SizedBox(height: 24),
                  _DocRow(
                    label: 'Política de Privacidad',
                    accepted: _acceptPrivacy,
                    onChanged: (v) => setState(() => _acceptPrivacy = v),
                    onView: () => _openAssetDialog(
                      'Política de Privacidad',
                      'assets/privacy.txt',
                    ),
                    textColor: textColor,
                  ),
                  const SizedBox(height: 10),
                  _DocRow(
                    label: 'Protección de Datos Personales',
                    accepted: _acceptProtection,
                    onChanged: (v) => setState(() => _acceptProtection = v),
                    onView: () => _openAssetDialog(
                      'Protección de Datos Personales',
                      'assets/data_protection.txt',
                    ),
                    textColor: textColor,
                  ),
                  const SizedBox(height: 24),
                  _loading
                      ? const SizedBox.shrink()
                      : CupertinoButton.filled(
                          borderRadius: BorderRadius.circular(16),
                          onPressed: (_acceptPrivacy && _acceptProtection)
                              ? _submit
                              : null,
                          child: const Text('Crear cuenta'),
                        ),
                ],
              ),
            ),
          ),
        ),

        // === ANIMACIÓN FACE ID ===
        if (_loading)
          AnimatedOpacity(
            opacity: _loading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: CupertinoColors.black.withValues(alpha: 0.6),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _success
                      ? ScaleTransition(
                          scale: _scaleAnim,
                          child: const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: CupertinoColors.activeGreen,
                            size: 90,
                            key: ValueKey('check'),
                          ),
                        )
                      : const CupertinoActivityIndicator(
                          radius: 22,
                          color: CupertinoColors.activeGreen,
                          key: ValueKey('loader'),
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ================== CAMPOS ==================
  Widget _buildInput(
    TextEditingController controller,
    String placeholder,
    IconData icon,
    Color textColor, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboard,
      style: TextStyle(color: textColor),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Icon(icon, color: CupertinoColors.activeGreen),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _buildPasswordField(Color textColor) {
    return CupertinoTextField(
      controller: _pass,
      placeholder: 'Contraseña',
      obscureText: _obscure,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: textColor),
      prefix: const Padding(
        padding: EdgeInsets.only(left: 8),
        child: Icon(CupertinoIcons.lock, color: CupertinoColors.activeGreen),
      ),
      suffix: CupertinoButton(
        padding: const EdgeInsets.all(6),
        onPressed: () => setState(() => _obscure = !_obscure),
        child: Icon(
          _obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
          color: CupertinoColors.activeGreen,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _buildConfirmPasswordField(Color textColor) {
    return CupertinoTextField(
      controller: _confirm,
      placeholder: 'Confirmar contraseña',
      obscureText: _obscureConfirm,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: textColor),
      prefix: const Padding(
        padding: EdgeInsets.only(left: 8),
        child: Icon(
          CupertinoIcons.lock_shield,
          color: CupertinoColors.activeGreen,
        ),
      ),
      suffix: CupertinoButton(
        padding: const EdgeInsets.all(6),
        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        child: Icon(
          _obscureConfirm ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
          color: CupertinoColors.activeGreen,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}

// ================== SWITCH DOCUMENTOS ==================
class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.label,
    required this.accepted,
    required this.onChanged,
    required this.onView,
    required this.textColor,
  });

  final String label;
  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onView;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CupertinoSwitch(
          value: accepted,
          onChanged: onChanged,
          activeTrackColor: CupertinoColors.activeGreen,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(color: textColor)),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          onPressed: onView,
          child: const Text('Ver'),
        ),
      ],
    );
  }
}
