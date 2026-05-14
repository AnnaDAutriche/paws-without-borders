import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:paws_without_borders/config/admin_config.dart';

class AuthProvider extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  late final StreamSubscription<fb.User?> _sub;

  fb.User? _user;
  fb.User? get user => _user;
  bool get isSignedIn => _user != null;
  String? get email => _user?.email;
  String get uid => _user?.uid ?? '';

  /// Client-side UI gate only.
  ///
  /// This is used to show/hide admin-only screens and buttons in the app UI.
  /// It is NOT a security boundary. Firestore/Storage security must be enforced
  /// via server-side rules (not here).
  bool get isAdmin => (_user?.email ?? '').toLowerCase() == AdminConfig.adminEmail.toLowerCase();

  AuthProvider() {
    _user = _auth.currentUser;
    _sub = _auth.authStateChanges().listen((u) {
      _user = u;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Auth state changes error: $e');
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> registerWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async => _auth.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
