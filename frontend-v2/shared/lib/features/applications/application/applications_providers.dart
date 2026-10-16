import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../jobs/application/paged.dart';
import '../../jobs/data/job.dart';
import '../data/applications_repository.dart';

/// The jobs the user applied to, newest first; `total` is the Applied tab's count.
class AppliedController extends PagedController<Application> {
  @override
  Future<Paged<Application>> build() async {
    final userId = ref.watch(currentUserProvider.select((user) => user?.uid));
    if (userId == null) return const Paged();
    return firstPage();
  }

  @override
  Future<PageOf<Application>> fetch(String? cursor) async {
    final page = await ref.read(applicationsRepositoryProvider).list(cursor: cursor);
    return (items: page.items, nextCursor: page.nextCursor, total: page.total);
  }

  @override
  String idOf(Application item) => item.job.id;
}

final appliedProvider = AsyncNotifierProvider<AppliedController, Paged<Application>>(AppliedController.new);

/// The applications changed in the app since the lists were loaded, by job id: applied (its state) or withdrawn
/// (null). Every card reads its job's state through it ([applicationOf]), so every tab shows a change at once,
/// without loading its list again.
class AppliedJobs extends Notifier<Map<String, ApplicationState?>> {
  @override
  Map<String, ApplicationState?> build() {
    ref.watch(currentUserProvider.select((user) => user?.uid)); // another user: nothing of the last one
    return const {};
  }

  /// The user applied to [job] this way (they said so, or Autolinky sent the e-mail: [letter] is its text as the
  /// user left it). Throws AppFailure.
  Future<Application> record(Job job, ApplyMethod method, {String? letter}) async {
    final saved = await ref.read(applicationsRepositoryProvider).record(job.id, method, letter: letter);
    if (ref.mounted) {
      state = {...state, job.id: saved.state};
      ref.invalidate(appliedProvider);
    }
    return saved;
  }

  /// What auto apply did (sent, or failed) shows on every card at once.
  void markAuto(List<ActivityItem> items) {
    state = {
      ...state,
      for (final item in items)
        item.jobId: ApplicationState(
          method: ApplyMethod.email,
          status: item.sent ? ApplicationStatus.sent : ApplicationStatus.failed,
          appliedAt: item.at,
        ),
    };
  }

  /// "I did not apply after all". Throws AppFailure (409 already_sent for an e-mail that went).
  Future<void> withdraw(String jobId) async {
    await ref.read(applicationsRepositoryProvider).withdraw(jobId);
    if (ref.mounted) {
      state = {...state, jobId: null};
      ref.invalidate(appliedProvider);
    }
  }
}

final appliedJobsProvider = NotifierProvider<AppliedJobs, Map<String, ApplicationState?>>(AppliedJobs.new);

/// [job]'s application now: a change made in the app, else what its list said.
ApplicationState? applicationOf(WidgetRef ref, Job job) =>
    ref.watch(appliedJobsProvider.select((changed) => changed.containsKey(job.id) ? changed[job.id] : job.application));

/// The user is done with this job: applied by any way, or its e-mail is queued or sent. An e-mail Gmail refused
/// (failed) is not done: it can be sent again. "For you" does not show the jobs the user is done with.
bool isDoneWith(ApplicationState? application) =>
    application != null && !(application.method == ApplyMethod.email && application.status == ApplicationStatus.failed);

/// The Gmail Autolinky sends from and auto apply (GET /v1/auto-apply): the Auto apply tab's head, "Send my CV",
/// the auto apply and Gmail screens.
final autoApplyProvider = FutureProvider<AutoApplyState>((ref) {
  ref.watch(currentUserProvider.select((user) => user?.uid));
  return ref.watch(applicationsRepositoryProvider).autoApply();
});
