import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fuerza español para correos/flows (reset, verificación, etc.)
  /// Se ejecuta al crear el servicio.
  AuthService() {
    try {
      _auth.setLanguageCode('es'); // <- español siempre
      // Alternativa si prefieres seguir el idioma del sistema:
      // _auth.useAppLanguage();
    } catch (_) {
      // Ignorar si no está disponible (p. ej., en ciertos entornos de test)
    }
  }

  /// Usuario actual (si hay sesión)
  Future<User?> currentUser() async => _auth.currentUser;

  /// ===================== LOGIN =====================
  Future<void> loginWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = _auth.currentUser;
      if (user != null) {
        final docRef = _db.collection('users').doc(user.uid);
        await docRef.set({
          'name': user.displayName ?? '',
          'email': user.email ?? email.trim(),
          'role': 'user',
          'deviceLinked': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// ===================== REGISTRO =====================
  Future<void> registerSafe({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = cred.user!;

      final cleanName = name.trim();
      if (cleanName.isNotEmpty) {
        await user.updateDisplayName(cleanName);
      }

      await _db.collection('users').doc(user.uid).set({
        'name': cleanName,
        'email': email.trim(),
        'role': 'user',
        'deviceLinked': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      try {
        await user.sendEmailVerification(); // llegará en español
      } catch (_) {}
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// ===================== RESET PASSWORD =====================
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim()); // en español
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Confirmar restablecimiento (opcional, si usas código in-app)
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    await _auth.confirmPasswordReset(
      code: code,
      newPassword: newPassword.trim(),
    );
  }

  /// ===================== CAMBIAR CONTRASEÑA (reauth) =====================
  Future<void> updatePasswordWithReauth({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No hay sesión activa.',
      );
    }
    final cred = EmailAuthProvider.credential(
      email: email.trim(),
      password: oldPassword.trim(),
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword.trim());
  }

  /// ===================== CERRAR SESIÓN =====================
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// ===================== POLÍTICA DE CONTRASEÑAS =====================
  String? validatePasswordPolicy(String pass, String email) {
    if (pass.length < 8) return 'Debe tener al menos 8 caracteres.';
    if (!RegExp(r'[A-Z]').hasMatch(pass) || !RegExp(r'[a-z]').hasMatch(pass)) {
      return 'Debe incluir mayúsculas y minúsculas.';
    }
    if (!RegExp(r'[0-9]').hasMatch(pass)) {
      return 'Debe incluir al menos un número.';
    }
    if (!RegExp(r'[^A-Za-z0-9 ]').hasMatch(pass)) {
      return 'Debe incluir al menos un símbolo (!, @, #, etc.).';
    }
    if (pass.contains(' ')) return 'No debe contener espacios.';
    if (pass.toLowerCase() == email.toLowerCase()) {
      return 'No debe ser igual al correo electrónico.';
    }
    return null;
  }

  /// ===================== ELIMINAR CUENTA =====================
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
