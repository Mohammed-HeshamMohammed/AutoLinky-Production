import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'env.dart';

/// Ready before the first frame (app/bootstrap.dart overrides them), so every screen can read them synchronously.
final envProvider = Provider<Env>((ref) => throw UnimplementedError('envProvider: set in bootstrap'));

final preferencesProvider = Provider<SharedPreferencesWithCache>(
  (ref) => throw UnimplementedError('preferencesProvider: set in bootstrap'),
);

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// "1.0.0 (1)"
final appVersionProvider = Provider<String>((ref) => throw UnimplementedError('appVersionProvider: set in bootstrap'));
