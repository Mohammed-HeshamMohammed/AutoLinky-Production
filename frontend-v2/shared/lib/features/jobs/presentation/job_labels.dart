import 'package:material_ui/material_ui.dart';

import '../../../core/utils/time_ago.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/apply_channel.dart';
import '../data/job.dart';

// The words and icons for a job's values and the ways to apply, in the user's language (the API sends codes).

String workModeLabel(AppLocalizations l10n, WorkMode mode) => switch (mode) {
  WorkMode.onsite => l10n.workOnsite,
  WorkMode.remote => l10n.workRemote,
  WorkMode.hybrid => l10n.workHybrid,
};

String employmentLabel(AppLocalizations l10n, EmploymentType type) => switch (type) {
  EmploymentType.fullTime => l10n.jobFullTime,
  EmploymentType.partTime => l10n.jobPartTime,
  EmploymentType.contract => l10n.jobContract,
  EmploymentType.temporary => l10n.jobTemporary,
  EmploymentType.internship => l10n.jobInternship,
  EmploymentType.freelance => l10n.jobFreelance,
  EmploymentType.volunteer => l10n.jobVolunteer,
};

/// "Hybrid · Full-time"; empty when the job says neither.
String workLabel(AppLocalizations l10n, Job job) => [
  if (job.workMode case final mode?) workModeLabel(l10n, mode),
  if (job.employmentType case final type?) employmentLabel(l10n, type),
].join(' · ');

/// The tab's name.
String channelName(AppLocalizations l10n, ApplyChannel channel) => switch (channel) {
  ApplyChannel.email => l10n.channelEmail,
  ApplyChannel.easyApply => l10n.channelEasyApply,
  ApplyChannel.whatsapp => l10n.channelWhatsapp,
  ApplyChannel.link => l10n.channelLink,
  ApplyChannel.companySite => l10n.channelCompanySite,
  ApplyChannel.message => l10n.channelMessage,
  ApplyChannel.comment => l10n.channelComment,
};

/// One sentence: which jobs the tab holds and how they are applied to.
String channelAbout(AppLocalizations l10n, ApplyChannel channel) => switch (channel) {
  ApplyChannel.email => l10n.channelEmailAbout,
  ApplyChannel.easyApply => l10n.channelEasyApplyAbout,
  ApplyChannel.whatsapp => l10n.channelWhatsappAbout,
  ApplyChannel.link => l10n.channelLinkAbout,
  ApplyChannel.companySite => l10n.channelCompanySiteAbout,
  ApplyChannel.message => l10n.channelMessageAbout,
  ApplyChannel.comment => l10n.channelCommentAbout,
};

/// The Apply button's words: what it will do.
String applyLabel(AppLocalizations l10n, ApplyChannel channel) => switch (channel) {
  ApplyChannel.email => l10n.applyEmail,
  ApplyChannel.easyApply => l10n.applyEasyApply,
  ApplyChannel.whatsapp => l10n.applyWhatsapp,
  ApplyChannel.link => l10n.applyLink,
  ApplyChannel.companySite => l10n.applyCompanySite,
  ApplyChannel.message => l10n.applyMessage,
  ApplyChannel.comment => l10n.applyComment,
};

IconData channelIcon(ApplyChannel channel) => switch (channel) {
  ApplyChannel.email => Icons.bolt_rounded,
  ApplyChannel.easyApply => Icons.touch_app_outlined,
  ApplyChannel.whatsapp => Icons.chat_outlined,
  ApplyChannel.link => Icons.link_rounded,
  ApplyChannel.companySite => Icons.language_rounded,
  ApplyChannel.message => Icons.forum_outlined,
  ApplyChannel.comment => Icons.mode_comment_outlined,
};

ApplyChannel channelOfMethod(ApplyMethod method) =>
    ApplyChannel.values.firstWhere((c) => c.methods.contains(method), orElse: () => ApplyChannel.link);

/// "Applied 2 days ago", or where an e-mail Autolinky sends is.
String applicationLabel(AppLocalizations l10n, ApplicationState state) => switch (state.status) {
  ApplicationStatus.applied => l10n.appliedAgo(timeAgo(l10n, state.appliedAt)),
  ApplicationStatus.queued => l10n.emailQueued,
  ApplicationStatus.sent => l10n.emailSent(timeAgo(l10n, state.appliedAt)),
  ApplicationStatus.failed => l10n.emailFailed,
};
