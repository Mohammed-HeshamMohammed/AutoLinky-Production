import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../auth/application/auth_providers.dart';
import '../data/models.dart';
import '../data/profile_repository.dart';

/// The signed-in user's profile; null before the first CV or save. Loaded again for another user.
class ProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final userId = ref.watch(currentUserProvider.select((user) => user?.uid));
    if (userId == null) return null;
    return ref.read(profileRepositoryProvider).profile();
  }

  /// Saves the fields given (PUT /v1/profile) and keeps the saved profile. Throws AppFailure.
  Future<Profile> save(Map<String, Object?> fields) async {
    final saved = await ref.read(profileRepositoryProvider).save(fields);
    state = AsyncData(saved);
    return saved;
  }

  /// The profile a CV upload / reading just filled.
  void replace(Profile profile) => state = AsyncData(profile);
}

final profileProvider = AsyncNotifierProvider<ProfileController, Profile?>(ProfileController.new);

/// The stored CV; null when there is none.
class CvController extends AsyncNotifier<CvInfo?> {
  @override
  Future<CvInfo?> build() async {
    final userId = ref.watch(currentUserProvider.select((user) => user?.uid));
    if (userId == null) return null;
    return ref.read(profileRepositoryProvider).cv();
  }

  Future<void> delete() async {
    await ref.read(profileRepositoryProvider).deleteCv();
    state = const AsyncData(null);
  }

  void replace(CvInfo cv) => state = AsyncData(cv);
}

final cvProvider = AsyncNotifierProvider<CvController, CvInfo?>(CvController.new);

/// Where an upload is: sending the file (with progress), then the API reading it.
enum CvUploadPhase { idle, sending, reading }

@immutable
class CvUploadState {
  const CvUploadState({this.phase = CvUploadPhase.idle, this.sent = 0, this.fileName});

  final CvUploadPhase phase;

  /// 0..1 while sending.
  final double sent;
  final String? fileName;

  bool get busy => phase != CvUploadPhase.idle;
}

/// Uploading a CV or reading it again. On success the CV and the profile providers hold the new values.
class CvUploadController extends Notifier<CvUploadState> {
  @override
  CvUploadState build() => const CvUploadState();

  /// Throws AppFailure (the API's codes: cv_too_large, cv_no_text, not_a_cv...).
  Future<CvResult> upload(PickedCv file) => _run(
    file.name,
    () => ref
        .read(profileRepositoryProvider)
        .uploadCv(
          file,
          onSent: (sent) {
            if (!ref.mounted) return;
            state = CvUploadState(
              phase: sent >= 1 ? CvUploadPhase.reading : CvUploadPhase.sending,
              sent: sent,
              fileName: file.name,
            );
          },
        ),
  );

  Future<CvResult> reanalyze() => _run(null, () => ref.read(profileRepositoryProvider).reanalyzeCv());

  Future<CvResult> _run(String? name, Future<CvResult> Function() call) async {
    if (state.busy) throw const CancelledFailure();
    state = CvUploadState(phase: name == null ? CvUploadPhase.reading : CvUploadPhase.sending, fileName: name);
    try {
      final result = await call();
      ref.read(cvProvider.notifier).replace(result.cv);
      ref.read(profileProvider.notifier).replace(result.profile);
      return result;
    } finally {
      if (ref.mounted) state = const CvUploadState();
    }
  }
}

final cvUploadProvider = NotifierProvider<CvUploadController, CvUploadState>(CvUploadController.new);

/// Picks a PDF or Word file on the phone; null when the user closes the picker. A provider, so tests pick a
/// file without the system dialog.
typedef CvPicker = Future<PickedCv?> Function();

final cvPickerProvider = Provider<CvPicker>((ref) => pickCvFile);

Future<PickedCv?> pickCvFile() async {
  final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['pdf', 'docx']);
  if (file == null) return null;
  final size = await file.length();
  if (size != null && size > PickedCv.maxBytes) {
    return PickedCv(name: file.name, bytes: Uint8List(0), size: size); // too big: not even read into memory
  }
  return PickedCv(name: file.name, bytes: await file.readAsBytes());
}
