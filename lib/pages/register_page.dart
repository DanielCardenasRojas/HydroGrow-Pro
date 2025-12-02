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

  // ✅ Mostrar/ocultar checklist (tarjeta)
  bool _showChecklist = false;

  // ✅ Estado de cada requisito
  bool _hasLetter = false;
  bool _hasUpper = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;
  bool _hasMinLength = false;
  bool _hasNoSpaces = false;
  bool _passwordsMatch = false;

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

  // ================== HELPERS DE VALIDACIÓN ==================
  int get _validChecksCount => [
    _hasLetter,
    _hasUpper,
    _hasNumber,
    _hasSpecial,
    _hasMinLength,
    _hasNoSpaces,
    _passwordsMatch,
  ].where((v) => v).length;

  void _onPasswordChanged(String value) {
    final prevCount = _validChecksCount;

    setState(() {
      _showChecklist = value.isNotEmpty;

      _hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
      _hasUpper = RegExp(r'[A-Z]').hasMatch(value);
      _hasNumber = RegExp(r'[0-9]').hasMatch(value);
      _hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value);
      _hasMinLength = value.length >= 8;
      _hasNoSpaces = !value.contains(' ');
      _passwordsMatch = _confirm.text.isNotEmpty && value == _confirm.text;
    });

    final newCount = _validChecksCount;
    if (newCount > prevCount) {
      HapticFeedback.lightImpact();
    }
  }

  void _onConfirmPasswordChanged(String value) {
    final prevCount = _validChecksCount;

    setState(() {
      _passwordsMatch = value.isNotEmpty && value == _pass.text;
    });

    final newCount = _validChecksCount;
    if (newCount > prevCount) {
      HapticFeedback.lightImpact();
    }
  }

  // ================== REGISTRO ==================
  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) return _alert('Escribe tu nombre.');
    if (!_email.text.contains('@')) return _alert('Correo inválido.');

    if (!_hasLetter ||
        !_hasUpper ||
        !_hasNumber ||
        !_hasSpecial ||
        !_hasMinLength ||
        !_hasNoSpaces ||
        !_passwordsMatch) {
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

      // ✅ Animación de éxito
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
        setState(() {
          _loading = false;
          _popController.reset();
        });
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

  // ================== CHECKLIST BONITA ==================

  /// Requisito que **solo se muestra cuando está cumplido**,
  /// y entra con animación (scale + fade) la primera vez.
  Widget _animatedRequirement(bool valid, String text) {
    if (!valid) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Opacity(
          opacity: scale.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.centerLeft,
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            size: 18,
            color: CupertinoColors.activeGreen,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: CupertinoColors.activeGreen,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(Color textColor, bool isDark) {
    if (!_showChecklist) {
      // 🔹 Mientras no se escriba contraseña, no se muestra nada
      return const SizedBox.shrink();
    }

    // ✅ Qué falta (para el mensaje)
    final missing = <String>[];
    if (!_hasLetter) missing.add('una letra');
    if (!_hasUpper) missing.add('una letra mayúscula');
    if (!_hasNumber) missing.add('un número');
    if (!_hasSpecial) missing.add('un carácter especial');
    if (!_hasMinLength) missing.add('mínimo 8 caracteres');
    if (!_passwordsMatch) missing.add('que las contraseñas coincidan');
    if (!_hasNoSpaces) missing.add('quitar los espacios');

    String? missingText;
    if (missing.isNotEmpty && _pass.text.isNotEmpty) {
      missingText = 'Te falta: ${missing.join(', ')}.';
    }

    final cardColor = isDark
        ? CupertinoColors.darkBackgroundGray
        : CupertinoColors.white;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
            ),
          ],
          border: Border.all(
            color: CupertinoColors.activeGreen.withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Requisitos de la contraseña',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),

            // ✅ Requisitos cumplidos que se van desplegando uno por uno
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _animatedRequirement(_hasLetter, 'Al menos una letra'),
                const SizedBox(height: 4),
                _animatedRequirement(_hasUpper, 'Al menos una letra mayúscula'),
                const SizedBox(height: 4),
                _animatedRequirement(_hasNumber, 'Al menos un número'),
                const SizedBox(height: 4),
                _animatedRequirement(
                  _hasSpecial,
                  'Al menos un carácter especial (@, #, !, etc.)',
                ),
                const SizedBox(height: 4),
                _animatedRequirement(_hasMinLength, 'Mínimo 8 caracteres'),
                const SizedBox(height: 4),
                _animatedRequirement(
                  _passwordsMatch,
                  'Las contraseñas coinciden',
                ),
                const SizedBox(height: 4),
                _animatedRequirement(_hasNoSpaces, 'Sin espacios'),
              ],
            ),

            const SizedBox(height: 6),

            // ✅ Mensaje de lo que falta
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: (missingText != null)
                  ? Text(
                      missingText,
                      key: const ValueKey('missing_text'),
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 13,
                      ),
                    )
                  : const SizedBox(key: ValueKey('no_missing_text')),
            ),
          ],
        ),
      ),
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

                  // 🔹 Tarjeta de requisitos (solo aparece al escribir)
                  _buildChecklistCard(textColor, isDark),

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

        // === OVERLAY DE CARGA / ÉXITO ===
        if (_loading)
          AnimatedOpacity(
            opacity: _loading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: CupertinoColors.black.withOpacity(0.6),
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
      onChanged: _onPasswordChanged,
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
      onChanged: _onConfirmPasswordChanged,
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
