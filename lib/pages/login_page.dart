import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _auth = AuthService();

  bool _obscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Si ya hay sesión iniciada, pasa al Home
    _auth.currentUser().then((user) {
      if (!mounted) return;
      if (user != null) {
        Navigator.of(
          context,
        ).pushReplacement(CupertinoPageRoute(builder: (_) => const HomePage()));
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  // ================= VALIDACIONES =================
  bool _isValidEmail(String email) {
    final pattern = r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$';
    return RegExp(pattern).hasMatch(email.trim());
  }

  // ================= LOGIN =================
  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text;

    if (!_isValidEmail(email)) {
      return _alert('Por favor, escribe un correo válido.');
    }
    if (pass.isEmpty || pass.length < 8) {
      return _alert('La contraseña debe tener al menos 8 caracteres.');
    }

    setState(() => _isLoading = true);

    try {
      await _auth.loginWithPassword(email: email, password: pass);

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(CupertinoPageRoute(builder: (_) => const HomePage()));
    } on FirebaseAuthException catch (e) {
      _alert(_firebaseMsg(e));
    } catch (_) {
      _alert('Ocurrió un error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= RESET PASSWORD =================
  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!_isValidEmail(email)) {
      return _alert(
        'Por favor, escribe tu correo para enviarte un enlace de recuperación.',
      );
    }
    try {
      await _auth.sendPasswordResetEmail(email);
      await _alert(
        'Te enviamos un correo con un enlace para restablecer tu contraseña.\n'
        'Revisa tu bandeja de entrada o la carpeta de spam.',
      );
    } on FirebaseAuthException catch (e) {
      _alert(_firebaseMsg(e));
    }
  }

  // ================= MAPEO MENSAJES FIREBASE (EXTENDIDO) =================
  String _firebaseMsg(FirebaseAuthException e) {
    switch (e.code) {
      // Credenciales / Login
      case 'invalid-email':
        return 'El formato del correo es inválido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada. Contacta con soporte.';
      case 'user-not-found':
        return 'No existe un usuario con este correo.';
      case 'wrong-password':
        return 'La contraseña es incorrecta. Intenta de nuevo.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Correo o contraseña incorrectos. Verifica tus datos.';
      case 'missing-password':
        return 'Falta la contraseña. Escribe tu contraseña para continuar.';
      case 'missing-email':
        return 'Falta el correo electrónico. Escríbelo para continuar.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Espera un momento y vuelve a intentar.';
      case 'network-request-failed':
        return 'Error de conexión. Revisa tu internet e inténtalo otra vez.';
      case 'operation-not-allowed':
        return 'Este método de inicio de sesión no está habilitado en el proyecto.';

      // Registro / creación de cuenta
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña es demasiado débil. Usa al menos 8 caracteres con letras y números.';
      case 'invalid-password':
        return 'La contraseña no es válida. Intenta con otra diferente.';

      // Gestión de sesión / seguridad
      case 'requires-recent-login':
        return 'Por seguridad, vuelve a iniciar sesión para realizar esta acción.';
      case 'user-mismatch':
        return 'Las credenciales no corresponden al usuario actual.';
      case 'user-token-expired':
      case 'invalid-user-token':
      case 'id-token-expired':
      case 'id-token-revoked':
        return 'Tu sesión ha expirado. Inicia sesión de nuevo.';

      // Enlaces de acción (reset/verify) y Dynamic Links
      case 'invalid-action-code':
        return 'El enlace de acción es inválido o ya fue usado.';
      case 'expired-action-code':
        return 'El enlace ha expirado. Solicita uno nuevo.';
      case 'invalid-continue-uri':
        return 'La URL de continuación no es válida.';
      case 'unauthorized-continue-uri':
        return 'La URL de continuación no está autorizada para este proyecto.';
      case 'missing-continue-uri':
        return 'Falta la URL de continuación en la solicitud.';
      case 'invalid-dynamic-link-domain':
        return 'El dominio de Dynamic Links no es válido para este proyecto.';
      case 'invalid-recipient-email':
        return 'El correo del destinatario no es válido.';

      // Proveedores / credenciales externas (Google, etc.)
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este correo usando otro método de acceso.';
      case 'credential-already-in-use':
        return 'Estas credenciales ya están vinculadas a otra cuenta.';
      case 'provider-already-linked':
        return 'Este proveedor ya está vinculado a tu cuenta.';
      case 'no-such-provider':
        return 'El proveedor solicitado no está vinculado a esta cuenta.';
      case 'invalid-provider-id':
        return 'Identificador de proveedor inválido.';
      case 'auth-domain-config-required':
        return 'Falta la configuración del dominio de autenticación.';

      // Teléfono / verificación (por si lo usas)
      case 'invalid-verification-code':
        return 'El código de verificación es inválido.';
      case 'invalid-verification-id':
        return 'El ID de verificación es inválido.';
      case 'missing-verification-code':
        return 'Falta el código de verificación.';
      case 'missing-verification-id':
        return 'Falta el ID de verificación.';
      case 'invalid-phone-number':
        return 'El número de teléfono no es válido.';
      case 'captcha-check-failed':
        return 'No se pudo verificar el captcha. Intenta de nuevo.';

      // Multi-factor (MFA)
      case 'multi-factor-auth-required':
      case 'second-factor-required':
        return 'Se requiere un segundo factor de verificación para iniciar sesión.';

      // Tenants / persistencia (más avanzados)
      case 'tenant-id-mismatch':
        return 'El tenant del usuario no coincide con el solicitado.';
      case 'unsupported-tenant-operation':
        return 'Operación no soportada para el tenant actual.';
      case 'unsupported-persistence-type':
      case 'invalid-persistence-type':
        return 'Tipo de persistencia no soportado en este entorno.';

      // Admin / claims
      case 'admin-restricted-operation':
        return 'Operación restringida por políticas del servidor.';
      case 'invalid-claims':
        return 'Las claims personalizadas no son válidas.';
      case 'claims-too-large':
        return 'Las claims personalizadas superan el tamaño permitido.';

      // App / configuración del proyecto
      case 'app-not-authorized':
        return 'La aplicación no está autorizada para usar Firebase Authentication.';
      case 'app-deleted':
        return 'La aplicación se ha eliminado. Reiníciala o reinstálala.';
      case 'invalid-api-key':
        return 'La API Key es inválida o no corresponde al proyecto.';

      // Web-only (por si llegaran a aparecer en logs)
      case 'popup-closed-by-user':
        return 'Se cerró la ventana emergente antes de completar el proceso.';
      case 'popup-blocked':
        return 'El navegador bloqueó la ventana emergente necesaria.';
      case 'redirect-cancelled-by-user':
      case 'redirect-operation-pending':
        return 'Se canceló la redirección o ya hay una en proceso.';

      // Desconocidos / genéricos
      case 'internal-error':
      case 'unknown':
        return 'Ocurrió un error interno. Intenta nuevamente.';

      default:
        // Fallback en español, mostrando el code para depurar si es necesario
        return 'No se pudo completar la operación (${e.code}). Intenta nuevamente.';
    }
  }

  // ================= ALERTA SIMPLE =================
  Future<void> _alert(String msg) async {
    await showCupertinoDialog(
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bgColor = isDark
        ? CupertinoColors.black
        : CupertinoColors.systemGroupedBackground;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(
                CupertinoIcons.leaf_arrow_circlepath,
                size: 90,
                color: CupertinoColors.activeGreen,
              ),
              const SizedBox(height: 16),
              const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.activeGreen,
                ),
              ),
              const SizedBox(height: 26),

              // ------ EMAIL ------
              CupertinoTextField(
                controller: _email,
                placeholder: 'Correo electrónico',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                style: TextStyle(color: textColor),
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    CupertinoIcons.at,
                    color: CupertinoColors.activeGreen,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              const SizedBox(height: 14),

              // ------ PASSWORD ------
              CupertinoTextField(
                controller: _pass,
                placeholder: 'Contraseña',
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _isLoading ? null : _submit(),
                autofillHints: const [AutofillHints.password],
                style: TextStyle(color: textColor),
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    CupertinoIcons.lock,
                    color: CupertinoColors.activeGreen,
                  ),
                ),
                suffix: CupertinoButton(
                  padding: const EdgeInsets.all(6),
                  onPressed: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                    _obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    color: CupertinoColors.activeGreen,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              const SizedBox(height: 18),

              // ------ OLVIDASTE CONTRASEÑA (SIN SUBRAYADO) ------
              _GradientLinkButton(
                text: '¿Olvidaste tu contraseña?',
                gradientColors: const [Color(0xFF74EBD5), Color(0xFFACB6E5)],
                onTap: _isLoading ? null : _forgotPassword,
              ),

              const SizedBox(height: 28),

              // ------ ENTRAR ------
              _isLoading
                  ? const CupertinoActivityIndicator()
                  : CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(14),
                      onPressed: _isLoading ? null : _submit,
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
              const SizedBox(height: 24),

              // ------ REGISTRO (SIN SUBRAYADO) ------
              _GradientLinkButton(
                text: '¿No tienes cuenta? ¡Regístrate!',
                gradientColors: const [Color(0xFF00FF87), Color(0xFF60EFFF)],
                onTap: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ====== Link con texto degradado (SIN subrayado) ======
class _GradientLinkButton extends StatelessWidget {
  final String text;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _GradientLinkButton({
    required this.text,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final txt = Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.white, // cubierto por el shader
        decoration: TextDecoration.none,
      ),
      textAlign: TextAlign.center,
    );

    return GestureDetector(
      onTap: onTap,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) =>
            LinearGradient(colors: gradientColors).createShader(bounds),
        child: txt,
      ),
    );
  }
}
