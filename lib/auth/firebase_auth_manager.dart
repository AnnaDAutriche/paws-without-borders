import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:paws_without_borders/auth/auth_manager.dart';

class FirebaseAuthManager extends AuthManager with EmailSignInManager {
  final fb.FirebaseAuth _auth;

  FirebaseAuthManager({fb.FirebaseAuth? auth}) : _auth = auth ?? fb.FirebaseAuth.instance;

  @override
  Future<void> signOut() async => _auth.signOut();

  @override
  Future<void> deleteUser(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
  }

  @override
  Future<void> updateEmail({required String email, required BuildContext context}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.verifyBeforeUpdateEmail(email);
  }

  @override
  Future<void> resetPassword({required String email, required BuildContext context}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<fb.User?> signInWithEmail(BuildContext context, String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } catch (e) {
      debugPrint('Email sign-in failed: $e');
      rethrow;
    }
  }

  @override
  Future<fb.User?> createAccountWithEmail(BuildContext context, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } catch (e) {
      debugPrint('Email registration failed: $e');
      rethrow;
    }
  }
}
