import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../user/data/models/user_model.dart';
import '../../../user/presentation/providers/user_provider.dart';

// ── Firebase Auth DataSource ─────────────────────────────────
final firebaseAuthDataSourceProvider =
    Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource();
});

// ── Auth Repository ──────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(firebaseAuthDataSourceProvider),
    userRepository: ref.read(userRepositoryProvider),
  );
});

// ── Auth State (bool) ────────────────────────────────────────
final authStateProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).isLoggedIn;
});

// ── Current User ID (raw UID stream) ────────────────────────
// Internally use hota hai kuch providers mein — screen pe mat use karo.
final currentUserIdProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance
      .authStateChanges()
      .map((user) => user?.uid);
});

// ── App User Provider (PERMANENT FIX) ───────────────────────
// Auth + Firestore dono combine — screens sirf yahi watch karein.
// Jab tak UserModel nahi milta, null emit karta hai — koi race condition nahi.
final appUserProvider = StreamProvider<UserModel?>((ref) {
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) return Stream.value(null);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  });
});