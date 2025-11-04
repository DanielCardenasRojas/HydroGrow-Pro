import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import '../theme_controller.dart'; // ⬅️ importa el controlador de tema

const String kUserHydroAssetPath = 'assets/icon/userhydro.png';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> _ensureUserDocExists(User user) async {
    try {
      final docRef = _db.collection('users').doc(user.uid);
      final snap = await docRef.get();
      if (!snap.exists) {
        await docRef.set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'deviceLinked': false,
        }, SetOptions(merge: true));
      } else {
        await docRef.set({
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } on FirebaseException catch (e) {
      debugPrint('ensureUserDocExists error: ${e.code}');
    }
  }

  Future<Map<String, String>> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      _goToLogin();
      return {};
    }

    String name = user.displayName ?? '';
    String email = user.email ?? '';

    try {
      await _ensureUserDocExists(user);

      final snap = await _db.collection('users').doc(user.uid).get();
      final data = snap.data() ?? {};

      final dbName = (data['name'] as String? ?? '').trim();
      final dbEmail = (data['email'] as String? ?? '').trim();

      if (dbName.isNotEmpty) name = dbName;
      if (dbEmail.isNotEmpty) email = dbEmail;

      if ((user.displayName == null || user.displayName!.isEmpty) &&
          name.isNotEmpty) {
        try {
          await user.updateDisplayName(name);
        } catch (_) {}
      }
    } on FirebaseException catch (e) {
      debugPrint('Firestore read error: ${e.code} / ${e.message}');
    } catch (e) {
      debugPrint('Unknown error loading profile: $e');
    }

    return {
      'name': name.isNotEmpty ? name : 'Sin nombre',
      'email': email.isNotEmpty ? email : 'sin-correo@desconocido',
    };
  }

  Future<void> _signOutAndBreakToLogin() async {
    try {
      await _auth.signOut();
    } finally {
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Perfil')),
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<Map<String, String>>(
          future: _loadProfile(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (snap.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      'No se pudo cargar el perfil.',
                      style: TextStyle(color: CupertinoColors.systemRed),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${snap.error}',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }

            final name = snap.data?['name'] ?? '—';
            final email = snap.data?['email'] ?? '—';

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 12),
                Align(
                  child: ClipOval(
                    child: Container(
                      width: 112,
                      height: 112,
                      color: CupertinoColors.systemGrey5,
                      child: Image.asset(
                        kUserHydroAssetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          CupertinoIcons.person_crop_circle,
                          size: 64,
                          color: CupertinoColors.inactiveGray,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== Apariencia (selector de tema) =====
                CupertinoFormSection.insetGrouped(
                  header: const Text('Apariencia'),
                  children: [
                    CupertinoFormRow(
                      prefix: const Text('Tema'),
                      child: ValueListenableBuilder<AppThemeMode>(
                        valueListenable: ThemeController.I.listenableMode,
                        builder: (context, mode, _) {
                          return CupertinoSlidingSegmentedControl<AppThemeMode>(
                            groupValue: mode,
                            children: const {
                              AppThemeMode.system: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('Auto'),
                              ),
                              AppThemeMode.light: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('Claro'),
                              ),
                              AppThemeMode.dark: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('Oscuro'),
                              ),
                            },
                            onValueChanged: (val) {
                              if (val != null) {
                                ThemeController.I.setMode(val);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // ===== Información de la cuenta =====
                CupertinoFormSection.insetGrouped(
                  header: const Text('Información de la cuenta'),
                  children: [
                    CupertinoFormRow(
                      prefix: const Text('Nombre'),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(name, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text('Correo'),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          email,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                CupertinoButton.filled(
                  onPressed: _signOutAndBreakToLogin,
                  child: const Text('Cerrar sesión'),
                ),

                const SizedBox(height: 8),
                const Text(
                  'Al cerrar sesión se te enviará al inicio de sesión y no se guardará información local. '
                  'Salir de la app NO cierra sesión automáticamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
