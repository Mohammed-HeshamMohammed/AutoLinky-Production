import 'job.dart';

/// A way to apply, as the user sees it: a tab of "For you", a filter of Explore, an Apply button.
///   email        Autolinky sends the CV for the user (auto apply)
///   easyApply    LinkedIn's Easy Apply: the job's LinkedIn page
///   whatsapp     a WhatsApp chat with the number in the post (WhatsApp or a plain phone number)
///   link         the link in the post (a form, a careers page...)
///   companySite  a LinkedIn job applied for on the company's site: its LinkedIn page leads there
///   message      a message to the person who posted (their LinkedIn profile)
///   comment      a comment on the post
enum ApplyChannel {
  email([ApplyMethod.email]),
  easyApply([ApplyMethod.easyApply]),
  whatsapp([ApplyMethod.whatsapp, ApplyMethod.phone]),
  link([ApplyMethod.link]),
  companySite([ApplyMethod.external]),
  message([ApplyMethod.dm]),
  comment([ApplyMethod.comment]);

  const ApplyChannel(this.methods);

  /// The jobs of the channel: the ones offering any of these (the API's `apply` filter).
  final List<ApplyMethod> methods;

  List<String> get apiFilter => [for (final m in methods) m.api];

  /// Its target is in the job's contacts (GET /v1/jobs/{id}), not in the list.
  bool get needsDetail => this == whatsapp || this == link || this == message || this == comment;

  bool offeredBy(Job job) => methods.any(job.applyMethods.contains);

  /// The method saved when the user applied this way to [job].
  ApplyMethod methodFor(Job job) => methods.firstWhere(job.applyMethods.contains, orElse: () => methods.first);

  /// The ways [job] can be applied to, in the tabs' order. A LinkedIn job not read yet still has its page.
  static List<ApplyChannel> of(Job job) {
    final found = [
      for (final c in values)
        if (c.offeredBy(job)) c,
    ];
    if (found.isEmpty && job.source == JobSource.linkedinJob && job.url != null) return const [companySite];
    return found;
  }
}

/// Where the Apply button of [channel] takes the user for [job]; null when the job does not give it (any more).
/// [detail] is needed for the channels whose target is a contact; [message] is written in the WhatsApp chat.
/// Only web links (https / http) are opened: never another scheme from the data.
Uri? applyTarget(ApplyChannel channel, Job job, {JobDetail? detail, String? message}) {
  switch (channel) {
    case ApplyChannel.email:
      return null; // Autolinky sends it: nothing to open
    case ApplyChannel.easyApply || ApplyChannel.companySite:
      return webUri(job.url);
    case ApplyChannel.whatsapp:
      final number = detail?.contact(const [ApplyMethod.whatsapp, ApplyMethod.phone])?.value;
      final digits = number?.replaceAll(RegExp(r'\D'), '') ?? '';
      if (digits.length < 8 || digits.length > 15) return null;
      // %20 for spaces (not "+", which WhatsApp would show as it is)
      final text = message == null || message.isEmpty ? '' : '?text=${Uri.encodeComponent(message)}';
      return Uri.parse('https://wa.me/$digits$text');
    case ApplyChannel.link:
      return webUri(detail?.contact(const [ApplyMethod.link])?.value);
    case ApplyChannel.message:
      return webUri(detail?.contact(const [ApplyMethod.dm])?.value) ?? webUri(detail?.authorUrl);
    case ApplyChannel.comment:
      return webUri(detail?.contact(const [ApplyMethod.comment])?.value) ?? webUri(job.url);
  }
}

/// [value] as a web link, or null (another scheme, no host, not a link).
Uri? webUri(String? value) {
  final uri = value == null ? null : Uri.tryParse(value.trim());
  if (uri == null || !(uri.isScheme('https') || uri.isScheme('http')) || uri.host.isEmpty) return null;
  return uri;
}
