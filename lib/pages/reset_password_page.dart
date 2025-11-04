import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _email = TextEditingController();
  final _auth = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_email.text.contains('@')) {
      return _alert('Por favor, escribe un correo válido.');
    }

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(_email.text.trim());
      if (!mounted) return;
      await _alert(
        'Te hemos enviado un correo con un enlace para restablecer tu contraseña. '
        'Revisa tu bandeja de entrada o la carpeta de spam.',
      );
      Navigator.pop(context);
    } catch (e) {
      _alert(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Restablecer contraseña'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              const Icon(
                CupertinoIcons.lock_shield,
                size: 80,
                color: CupertinoColors.activeGreen,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 30),

              // Campo de correo
              CupertinoTextField(
                controller: _email,
                placeholder: 'Correo electrónico',
                keyboardType: TextInputType.emailAddress,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                prefix: const Icon(CupertinoIcons.at),
              ),
              const SizedBox(height: 24),

              // Botón
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(14),
                      onPressed: _submit,
                      child: const Text('Enviar enlace'),
                    ),
              const SizedBox(height: 16),

              // Botón para volver
              CupertinoButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Regresar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
