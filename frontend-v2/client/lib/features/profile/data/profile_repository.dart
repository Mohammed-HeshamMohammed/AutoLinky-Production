import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import 'models.dart';

/// A CV picked on the phone, ready to send.
class PickedCv {
  PickedCv({required this.name, required this.bytes, int? size}) : size = size ?? bytes.length;

  final String name;
  final Uint8List bytes;

  /// The file's size (a file over the limit is not read: bytes stay empty).
  final int size;

  static const maxBytes = 4 * 1024 * 1024; // the API's limit (backend/cv_file.py)

  String get extension => name.contains('.') ? name.split('.').last.toLowerCase() : '';

  String? get contentType => switch (extension) {
    'pdf' => 'application/pdf',
    'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    _ => null,
  };

  /// What the API would refuse anyway, found before the upload: the same codes it answers with.
  ApiFailure? get problem {
    if (contentType == null) return const ApiFailure(statusCode: 415, code: 'cv_bad_type');
    if (size > maxBytes) return const ApiFailure(statusCode: 413, code: 'cv_too_large');
    if (bytes.isEmpty) return const ApiFailure(statusCode: 400, code: 'cv_empty');
    return null;
  }
}

/// The profile (GET / PUT /v1/profile) and the CV (/v1/cv) on the API.
class ProfileRepository {
  const ProfileRepository(this._api);

  final ApiClient _api;

  /// Null before the first CV or save (404 no_profile).
  Future<Profile?> profile() async {
    try {
      return await _api.get('/v1/profile', Profile.fromJson);
    } on ApiFailure catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Saves the fields given (the others keep their value) and returns the saved profile.
  Future<Profile> save(Map<String, Object?> fields) => _api.put('/v1/profile', fields, Profile.fromJson);

  /// Has the collector searched the user's job titles yet? New ones are searched within minutes.
  Future<SearchStatus> searchStatus() => _api.get('/v1/profile/search-status', SearchStatus.fromJson);

  /// Searches the user's job titles live, now, even those searched before (after the setup or a new CV): the
  /// same status, the titles being searched for this user.
  Future<SearchStatus> searchNow() => _api.post('/v1/profile/search-now', null, SearchStatus.fromJson);

  /// Null when there is no CV (404 no_cv).
  Future<CvInfo?> cv() async {
    try {
      return await _api.get('/v1/cv', (json) => CvInfo.fromJson((json! as Map<String, Object?>)['cv']));
    } on ApiFailure catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Sends the file; the API reads it (a few seconds) and fills the profile. [onSent]: 0..1 while it uploads.
  Future<CvResult> uploadCv(PickedCv file, {void Function(double sent)? onSent}) {
    final problem = file.problem;
    if (problem != null) return Future.error(problem);
    const chunk = 64 * 1024;
    final body = Stream<List<int>>.fromIterable([
      for (var i = 0; i < file.bytes.length; i += chunk)
        file.bytes.sublist(i, i + chunk > file.bytes.length ? file.bytes.length : i + chunk),
    ]);
    return _api.post(
      '/v1/cv',
      body,
      CvResult.fromJson,
      query: {'name': file.name},
      options: Options(contentType: file.contentType, headers: {Headers.contentLengthHeader: file.bytes.length}),
      onSendProgress: onSent == null ? null : (sent, total) => onSent(total > 0 ? sent / total : 0),
    );
  }

  /// Reads the stored CV again (after a partial reading).
  Future<CvResult> reanalyzeCv() => _api.post('/v1/cv/reanalyze', null, CvResult.fromJson);

  /// Removes the file, its text and its reading. The profile stays.
  Future<void> deleteCv() => _api.delete('/v1/cv');
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository(ref.watch(apiClientProvider)));
