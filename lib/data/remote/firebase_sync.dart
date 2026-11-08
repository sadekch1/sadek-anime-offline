import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/library_entry.dart';
import '../local/database_helper.dart';

/// Google sign-in + Firestore sync for My Library (v2, user only).
///
/// Local SQLite is ALWAYS the source of truth. When Firebase is not
/// configured (no google-services.json / no Firebase project) every method
/// here fails soft: [available] stays false, sign-in returns false, and
/// the library keeps working fully offline. Nothing in the app crashes
/// without Firebase.
class FirebaseSync extends ChangeNotifier {
  FirebaseSync(this._db);
  final DatabaseHelper _db;

  bool _available = false;
  bool get available => _available;

  String? _email;
  String? get userEmail => _email;
  bool get signedIn => _email != null;

  /// Call once at startup. Never throws.
  ///
  /// Firebase options come from --dart-define values, extracted in CI from
  /// the GOOGLE_SERVICES_JSON secret (see .github/workflows/build_apk.yml).
  /// No google-services.json file and no Gradle plugin are needed. When no
  /// options are baked in, it tries the default initialisation (works if a
  /// google-services.json was added locally), and if that also fails the
  /// app simply runs without sync.
  Future<void> init() async {
    try {
      const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
      const appId = String.fromEnvironment('FIREBASE_APP_ID');
      const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
      const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
      const bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
      if (apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: senderId,
            projectId: projectId,
            storageBucket: bucket.isNotEmpty ? bucket : null,
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      _available = true;
      final u = FirebaseAuth.instance.currentUser;
      _email = u?.email;
      notifyListeners();
    } catch (_) {
      _available = false;
    }
  }

  /// Returns true on success. Returns false (no throw) when Firebase is
  /// not configured, the user cancels, or sign-in fails for any reason
  /// (e.g. SHA-1 not registered in the Firebase console).
  Future<bool> signInWithGoogle() async {
    if (!_available) return false;
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false; // user cancelled
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      _email = cred.user?.email;
      notifyListeners();
      if (_email != null) await syncNow();
      return _email != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    _email = null;
    notifyListeners();
  }

  CollectionReference<Map<String, dynamic>>? _listsRef() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('lists');
  }

  /// Merge remote <-> local, last-write-wins by updated_at, then push.
  /// Returns false when not signed in / offline / not configured.
  Future<bool> syncNow() async {
    if (!_available || !signedIn) return false;
    try {
      final ref = _listsRef();
      if (ref == null) return false;
      final local = await _db.getLibrary();
      final snap = await ref.get();
      final remote = <int, LibraryEntry>{};
      for (final d in snap.docs) {
        final data = d.data();
        final malId = int.tryParse(d.id) ?? (data['mal_id'] as int? ?? 0);
        if (malId == 0) continue;
        remote[malId] = LibraryEntry(
          malId: malId,
          status: (data['status'] as String?) ?? 'plan',
          lastEpisode: (data['last_episode'] as int?) ?? 0,
          updatedAt: (data['updated_at'] as int?) ?? 0,
        );
      }
      // Remote wins where it is newer; otherwise local wins and is pushed.
      for (final e in remote.values) {
        final l = local[e.malId];
        if (l == null || e.updatedAt > l.updatedAt) {
          await _db.upsertLibraryEntry(e);
        }
      }
      final merged = await _db.getLibrary();
      final batch = FirebaseFirestore.instance.batch();
      for (final e in merged.values) {
        batch.set(ref.doc('${e.malId}'), {
          'mal_id': e.malId,
          'status': e.status,
          'last_episode': e.lastEpisode,
          'updated_at': e.updatedAt,
        });
      }
      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Best-effort push after a local library change. Never throws.
  Future<void> pushLocal() async {
    if (!_available || !signedIn) return;
    try {
      await syncNow();
    } catch (_) {}
  }
}
