// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Autolinky';

  @override
  String get welcomeTitle => 'Jobs that fit you, found for you';

  @override
  String get welcomeSubtitle =>
      'Upload your CV once. Autolinky reads it, watches LinkedIn around the clock and brings you the jobs that match.';

  @override
  String get welcomePointMatch => 'Matched to your CV, with the reasons';

  @override
  String get welcomePointFresh => 'New jobs every few minutes';

  @override
  String get welcomePointApply => 'Apply by email, WhatsApp or link in one tap';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithEmail => 'Continue with email';

  @override
  String get orDivider => 'or';

  @override
  String get legalPrefix => 'By continuing, you agree to our';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get legalAnd => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get emailTitle => 'Continue with email';

  @override
  String get emailSubtitle => 'We\'ll email you a sign-in link. No password needed.';

  @override
  String get emailLabel => 'Email address';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get sendCode => 'Send sign-in link';

  @override
  String get verifyTitle => 'Check your email';

  @override
  String verifySubtitle(String email) {
    return 'Open the sign-in link we sent to $email. You can return here to request another link.';
  }

  @override
  String get verifyButton => 'Verify';

  @override
  String get resendCode => 'Resend link';

  @override
  String resendIn(int seconds) {
    return 'Resend link in ${seconds}s';
  }

  @override
  String get codeSent => 'A new sign-in link is on its way';

  @override
  String get changeEmail => 'Use a different email';

  @override
  String get navMatches => 'For you';

  @override
  String get navExplore => 'Explore';

  @override
  String get navProfile => 'Profile';

  @override
  String get matchesTitle => 'Jobs for you';

  @override
  String get matchesEmptyTitle => 'Your matches will appear here';

  @override
  String get matchesEmptyBody =>
      'Upload your CV and we\'ll find the jobs that fit you, with the reasons for each match.';

  @override
  String get matchesMoreError => 'Couldn\'t load more jobs.';

  @override
  String get tabApplied => 'Applied';

  @override
  String get channelEmail => 'Auto apply';

  @override
  String get channelEasyApply => 'Easy Apply';

  @override
  String get channelWhatsapp => 'WhatsApp';

  @override
  String get channelLink => 'Apply link';

  @override
  String get channelCompanySite => 'Company site';

  @override
  String get channelMessage => 'Message';

  @override
  String get channelComment => 'Comment';

  @override
  String get channelEmailAbout => 'Posts that ask for CVs by email: Autolinky sends yours for you.';

  @override
  String get channelEasyApplyAbout => 'LinkedIn jobs you apply to in a few taps, on LinkedIn.';

  @override
  String get channelWhatsappAbout => 'Posts with a number: message the recruiter on WhatsApp.';

  @override
  String get channelLinkAbout => 'Posts with a form or a careers page to apply on.';

  @override
  String get channelCompanySiteAbout => 'LinkedIn jobs you apply to on the company\'s website.';

  @override
  String get channelMessageAbout => 'Posts that ask you to message the person who posted.';

  @override
  String get channelCommentAbout => 'Posts that ask you to comment to apply.';

  @override
  String get bestFitFirst => 'Best fit first.';

  @override
  String get channelEmptyTitle => 'Nothing here yet';

  @override
  String get emptyPullHint => 'New jobs arrive every few minutes: pull down to check.';

  @override
  String get applyEmail => 'Send my CV';

  @override
  String get applyEasyApply => 'Easy Apply';

  @override
  String get applyWhatsapp => 'WhatsApp';

  @override
  String get applyLink => 'Open the link';

  @override
  String get applyCompanySite => 'Apply on their site';

  @override
  String get applyMessage => 'Send a message';

  @override
  String get applyComment => 'Comment';

  @override
  String get applyChoose => 'Apply';

  @override
  String get showDetails => 'Show details';

  @override
  String get thePost => 'The post';

  @override
  String get jobDescription => 'Job description';

  @override
  String get noDescription => 'No description was given.';

  @override
  String get waysToApply => 'Ways to apply';

  @override
  String get openOnLinkedIn => 'Open on LinkedIn';

  @override
  String appliedAgo(String when) {
    return 'Applied · $when';
  }

  @override
  String get emailQueued => 'Sending…';

  @override
  String emailSent(String when) {
    return 'CV sent · $when';
  }

  @override
  String get emailFailed => 'Not sent';

  @override
  String appliedVia(String way) {
    return 'Via $way';
  }

  @override
  String appliedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count applications',
      one: '1 application',
    );
    return '$_temp0';
  }

  @override
  String get appliedEmptyTitle => 'No applications yet';

  @override
  String get appliedEmptyBody => 'Apply to a job and it shows here, so you always know where you applied.';

  @override
  String get removeApplied => 'Remove from Applied';

  @override
  String get removedApplied => 'Removed from Applied';

  @override
  String get cannotRemoveSent => 'Your CV was already emailed: it stays in Applied.';

  @override
  String get moreOptions => 'More options';

  @override
  String get didYouApplyTitle => 'Did you apply?';

  @override
  String get didYouApplyBody => 'Say yes and we\'ll keep it in Applied, so you know where you applied.';

  @override
  String get yesApplied => 'Yes, I applied';

  @override
  String get notYet => 'Not yet';

  @override
  String get savedApplied => 'Added to Applied';

  @override
  String get applyUnavailable => 'This way to apply isn\'t in the job any more.';

  @override
  String get applyCannotOpen => 'Couldn\'t open it on this phone.';

  @override
  String get chooseWayTitle => 'How do you want to apply?';

  @override
  String whatsappMessage(String title) {
    return 'Kindly find my attached CV for the position of $title.';
  }

  @override
  String get sendCvTitle => 'Send your CV?';

  @override
  String get sendCvTo => 'To';

  @override
  String get sendCvSubject => 'Subject';

  @override
  String get sendCvAttachment => 'Attachment';

  @override
  String get sendCvButton => 'Send';

  @override
  String get autoApplyTitle => 'Auto apply';

  @override
  String get autoApplyBody =>
      'Turn it on and Autolinky emails your CV to every new job here that fits you, from your own Gmail.';

  @override
  String get autoApplyTurnOn => 'Turn on';

  @override
  String get autoApplyOn => 'On';

  @override
  String get connectEmailTitle => 'Connect your Gmail';

  @override
  String get connectEmailBody => 'Autolinky sends your applications from your own Gmail, with your CV attached.';

  @override
  String get connectEmailPointAddress => 'Sent from your address, so replies come straight to you';

  @override
  String get connectEmailPointLetter => 'A short cover letter written for each job';

  @override
  String get connectEmailPointStop => 'Pause it any time';

  @override
  String get gotIt => 'Got it';

  @override
  String get gmailTitle => 'Connect Gmail';

  @override
  String get gmailIntroSend =>
      'Your CV goes out from your own Gmail, so replies come straight to you. Connect it once: every \"Send my CV\" uses it.';

  @override
  String get gmailIntroAuto =>
      'Auto apply sends your CV from your own Gmail. Connect it once, then choose how auto apply works.';

  @override
  String get gmailIntroSettings =>
      'Autolinky sends your applications from your own Gmail with an app password: a separate password Google makes for one app, which you can delete any time.';

  @override
  String get gmailInvalidBanner =>
      'Gmail stopped accepting your app password (it may have been deleted, or 2-Step Verification turned off). Make a new one and paste it below.';

  @override
  String get gmailStepsTitle => 'Get an app password (2 minutes)';

  @override
  String get gmailStep1 => 'Turn on 2-Step Verification for your Google account: app passwords need it.';

  @override
  String get gmailStep1Button => 'Open 2-Step Verification';

  @override
  String get gmailStep2 => 'Open App passwords, type Autolinky as the app\'s name, then tap Create.';

  @override
  String get gmailStep2Button => 'Open App passwords';

  @override
  String get gmailStep3 =>
      'Copy the 16-letter password Google shows and paste it below. Use the Google account of the address below.';

  @override
  String get gmailAddressLabel => 'Gmail address';

  @override
  String get gmailNameLabel => 'Your name';

  @override
  String get gmailNameHelper => 'Recruiters see this name, and your letter is signed with it.';

  @override
  String get gmailPasswordLabel => 'App password';

  @override
  String get gmailPasswordHelper => '16 letters. Spaces are fine.';

  @override
  String get gmailPasswordKeep => 'Leave it empty to keep the saved one.';

  @override
  String get gmailPaste => 'Paste';

  @override
  String get gmailShowPassword => 'Show password';

  @override
  String get gmailHidePassword => 'Hide password';

  @override
  String get gmailConnect => 'Check and connect';

  @override
  String get gmailSave => 'Save';

  @override
  String get gmailChecking => 'Checking with Gmail…';

  @override
  String get gmailConnected => 'Gmail connected';

  @override
  String get gmailSavedUnverified => 'Saved. Gmail couldn\'t be reached to check it now: your first CV will.';

  @override
  String get gmailPrivacy =>
      'Your app password is encrypted and used only to send your applications. Delete it here or from your Google account any time.';

  @override
  String get gmailSignatureLabel => 'Signature';

  @override
  String get gmailSignatureHelper => 'Under your name in every e-mail. Taken from your CV: change it as you like.';

  @override
  String get gmailSignatureReset => 'Use the one from my CV';

  @override
  String get sendCvLetterAi => 'Written for this job from your CV. You can change it before sending.';

  @override
  String get sendCvLetterTemplate => 'A short letter. You can change it before sending.';

  @override
  String get sendCvLetterEmpty => 'Write a few lines to the recruiter';

  @override
  String get gmailStatusOk => 'Connected';

  @override
  String get gmailStatusUnverified => 'Saved, not checked yet';

  @override
  String get gmailStatusInvalid => 'Needs a new app password';

  @override
  String get gmailDisconnect => 'Disconnect Gmail';

  @override
  String get gmailDisconnectTitle => 'Disconnect Gmail?';

  @override
  String get gmailDisconnectBody =>
      'Autolinky forgets the app password and auto apply turns off. To cancel it at Google too, delete it in App passwords.';

  @override
  String get gmailDisconnected => 'Gmail disconnected';

  @override
  String get gmailErrorName => 'Enter your name';

  @override
  String get gmailErrorFormat => 'An app password is 16 letters, like abcd efgh ijkl mnop.';

  @override
  String get gmailErrorWrong =>
      'Gmail didn\'t accept this app password. Check it was made for this address, then try again.';

  @override
  String get gmailErrorNotApp =>
      'That looks like your Google password. Autolinky needs an app password (step 2), never your real password.';

  @override
  String get gmailErrorBlocked => 'Google wants you to sign in to Gmail in a browser first. Do that, then try again.';

  @override
  String get gmailErrorUnavailable => 'Sending from Gmail isn\'t available right now. Try again later.';

  @override
  String get gmailErrorNeedPassword => 'Paste an app password for this address.';

  @override
  String get sendCvFrom => 'From';

  @override
  String get sendCvLetter => 'Letter';

  @override
  String cvSentTo(String address) {
    return 'CV sent to $address';
  }

  @override
  String get sendAgain => 'Send again';

  @override
  String get appliedAutomatically => 'Sent by auto apply';

  @override
  String get emailErrorAddressRefused => 'Not sent: the job\'s address refused it.';

  @override
  String get emailErrorMessageRefused => 'Not sent: Gmail refused the message.';

  @override
  String get emailErrorInterrupted => 'Interrupted while sending: check your Gmail\'s Sent folder.';

  @override
  String get emailErrorGmailLimit => 'Gmail\'s daily sending limit is reached. Try again tomorrow.';

  @override
  String get emailErrorGmailBusy => 'Gmail didn\'t answer. Try again in a minute.';

  @override
  String get emailErrorDailyLimit => 'That\'s today\'s limit of CVs, to keep your Gmail safe. Try again tomorrow.';

  @override
  String get emailErrorNoCv => 'Upload your CV first: it\'s what gets attached.';

  @override
  String get autoApplyOffTitle => 'Auto apply is off';

  @override
  String get autoApplyOffBody =>
      'Turn it on and Autolinky sends your CV to the jobs that fit you, from your Gmail, a few at a time.';

  @override
  String get autoApplyOnTitle => 'Auto apply is on';

  @override
  String autoApplySentToday(int sent, int limit) {
    return '$sent of $limit CVs sent today';
  }

  @override
  String autoApplyNextIn(int minutes) {
    return 'Next CV in about $minutes min';
  }

  @override
  String get autoApplyNextSoon => 'Next CV any moment';

  @override
  String autoApplyWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs waiting',
      one: '1 job waiting',
      zero: 'No jobs waiting: it sends as new ones that fit you arrive',
    );
    return '$_temp0';
  }

  @override
  String get autoApplyStart => 'Start auto apply';

  @override
  String get autoApplyStop => 'Turn off auto apply';

  @override
  String get autoApplyBackground => 'Continue in background';

  @override
  String get autoApplyBackgroundNote =>
      'You can close Autolinky: sending happens on our server, and you get a notification when a CV goes out.';

  @override
  String get autoApplyMinMatch => 'Only jobs that fit you at least';

  @override
  String get autoApplyDailyLimit => 'CVs a day, at most';

  @override
  String get autoApplyGap => 'Minutes between two CVs, at least';

  @override
  String get autoApplyGapSafety =>
      'Gmail lets a personal account send up to 500 e-mails a day, but sending faster than about 20 an hour can get your sending stopped for up to a day. 3 minutes is the closest Autolinky goes.';

  @override
  String get autoApplyHowTitle => 'How it sends';

  @override
  String get autoApplyHowGap =>
      'One at a time, at least the minutes you chose apart, plus a little at random, like a person';

  @override
  String get autoApplyHowHours => 'Day and night, at most 15 an hour';

  @override
  String get autoApplyHowOnce => 'Never the same recruiter twice in a month, never a job you applied to';

  @override
  String get autoApplyHowFresh => 'Only jobs from the last 2 weeks, best fit first';

  @override
  String get autoApplyHowGmail => 'From your Gmail: every e-mail is in your Sent folder';

  @override
  String get autoApplySendsFrom => 'Sends from';

  @override
  String get autoApplyNotificationsOff => 'Notifications are off: you\'ll find what was sent in Applied.';

  @override
  String get autoApplyProblemEmail =>
      'Gmail stopped accepting your app password. Nothing is sent until you add a new one.';

  @override
  String get autoApplyProblemNoCv => 'Upload your CV: auto apply has nothing to attach.';

  @override
  String get autoApplyProblemLimit => 'Gmail\'s daily limit was reached: auto apply carries on tomorrow.';

  @override
  String get autoApplyProblemBusy => 'Gmail asked to wait a little: auto apply carries on shortly.';

  @override
  String get autoApplyProblemOffline => 'Sending is paused for a moment: your CVs go out as soon as it\'s back.';

  @override
  String get autoApplyFixGmail => 'Fix Gmail';

  @override
  String get autoApplyUploadCv => 'Upload CV';

  @override
  String get autoApplyManage => 'Manage';

  @override
  String autoApplyBannerOn(int sent) {
    return 'On · $sent sent today';
  }

  @override
  String get autoApplyBannerProblem => 'Needs your attention';

  @override
  String autoApplySentSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Auto apply sent your CV to $count jobs',
      one: 'Auto apply sent your CV to 1 job',
    );
    return '$_temp0';
  }

  @override
  String get applyingSection => 'Applying';

  @override
  String get settingsGmail => 'Gmail';

  @override
  String get settingsGmailNone => 'Not connected';

  @override
  String get autoApplyOff => 'Off';

  @override
  String get notifyChannel => 'When auto apply sends your CV';

  @override
  String notifySentOne(String company) {
    return 'CV sent to $company';
  }

  @override
  String notifySentMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Auto apply sent $count CVs');
    return '$_temp0';
  }

  @override
  String get notifySeeApplied => 'See them in Applied';

  @override
  String get notifyProblemTitle => 'Auto apply stopped';

  @override
  String newJobsBar(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count new jobs', one: '1 new job');
    return '$_temp0';
  }

  @override
  String notifyNewMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new jobs fit you',
      one: 'A new job fits you',
    );
    return '$_temp0';
  }

  @override
  String get notifyNewMatchesBody => 'Open Autolinky to see them and apply.';

  @override
  String get exploreSearchHint => 'Search jobs, companies or skills';

  @override
  String get clearSearch => 'Clear';

  @override
  String get filterAll => 'All';

  @override
  String get exploreHeader => 'Newest first, from the last 30 days';

  @override
  String get exploreNoResultsTitle => 'No jobs found';

  @override
  String get exploreNoResultsBody => 'Try other words, or another way to apply.';

  @override
  String get listEnd => 'That\'s all for now. New jobs arrive all the time.';

  @override
  String matchPercent(int percent) {
    return '$percent% match';
  }

  @override
  String get yourSkills => 'Your skills';

  @override
  String get missingSkills => 'Missing';

  @override
  String get fitSameRole => 'Your job';

  @override
  String get fitSimilarRole => 'Close to your job';

  @override
  String get fitSameField => 'In your field';

  @override
  String get fitRelatedField => 'A related field';

  @override
  String get fitSkillsOnly => 'Fits your skills';

  @override
  String get levelFitMatch => 'Your level';

  @override
  String get levelFitClose => 'Near your level';

  @override
  String get workOnsite => 'On-site';

  @override
  String get workRemote => 'Remote';

  @override
  String get workHybrid => 'Hybrid';

  @override
  String get placeNotGiven => 'Place not given';

  @override
  String get jobFullTime => 'Full-time';

  @override
  String get jobPartTime => 'Part-time';

  @override
  String get jobContract => 'Contract';

  @override
  String get jobTemporary => 'Temporary';

  @override
  String get jobInternship => 'Internship';

  @override
  String get jobFreelance => 'Freelance';

  @override
  String get jobVolunteer => 'Volunteer';

  @override
  String get postedJustNow => 'Just now';

  @override
  String postedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count minutes ago', one: '1 minute ago');
    return '$_temp0';
  }

  @override
  String postedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count hours ago', one: '1 hour ago');
    return '$_temp0';
  }

  @override
  String postedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days ago', one: '1 day ago');
    return '$_temp0';
  }

  @override
  String postedWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count weeks ago', one: '1 week ago');
    return '$_temp0';
  }

  @override
  String postedMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count months ago', one: '1 month ago');
    return '$_temp0';
  }

  @override
  String get uploadCv => 'Upload your CV';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get profileTitle => 'Profile';

  @override
  String get accountSection => 'Account';

  @override
  String get signedInWithGoogle => 'Signed in with Google';

  @override
  String get signedInWithEmail => 'Signed in with email';

  @override
  String get cvSection => 'Your CV';

  @override
  String get cvMissingTitle => 'No CV yet';

  @override
  String get cvMissingBody => 'Add your CV so we can match you with jobs.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody => 'You can sign in again any time.';

  @override
  String get cancel => 'Cancel';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get about => 'About';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String versionWithUpdate(String version, int patch) {
    return 'Version $version · update $patch';
  }

  @override
  String get updatedTitle => 'The app was updated';

  @override
  String updatedBody(int patch) {
    return 'A new update just arrived and is already running (update $patch). Nothing else to do.';
  }

  @override
  String get updatedOk => 'Got it';

  @override
  String get retry => 'Try again';

  @override
  String get errorTitle => 'Something\'s not right';

  @override
  String get errorNetwork => 'No internet connection. Check your connection and try again.';

  @override
  String get errorSessionExpired => 'Your session has ended. Please sign in again.';

  @override
  String get errorForbidden => 'This account can\'t use Autolinky right now. Please contact support.';

  @override
  String get errorRateLimited => 'Too many attempts. Wait a moment and try again.';

  @override
  String errorRateLimitedFor(int seconds) {
    return 'Too many attempts. Try again in $seconds seconds.';
  }

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get errorInvalidCode => 'This sign-in link is invalid or has expired. Request a new link.';

  @override
  String get errorNotConfigured => 'This sign-in option isn\'t available yet. Please use another one.';

  @override
  String get configMissingTitle => 'This build isn\'t set up';

  @override
  String configMissingBody(String names) {
    return 'Missing settings: $names. Build with --dart-define-from-file=env/dev.json';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get skip => 'Skip';

  @override
  String get scopeTitle => 'Where do you want to work?';

  @override
  String get scopeSubtitle => 'We\'ll show you jobs there and keep searching for more. You can change it any time.';

  @override
  String get scopeEgypt => 'Egypt only';

  @override
  String get scopeEgyptBody => 'Jobs in Egypt';

  @override
  String get scopeEgyptGulf => 'Egypt and the Gulf';

  @override
  String get scopeEgyptGulfBody => 'Egypt, Saudi Arabia, the UAE, Qatar, Kuwait, Bahrain and Oman';

  @override
  String get scopeEgyptRemote => 'Egypt + remote';

  @override
  String get scopeEgyptRemoteBody => 'Jobs in Egypt, and remote jobs from any country';

  @override
  String get scopeEgyptGulfRemote => 'Egypt, the Gulf + remote';

  @override
  String get scopeEgyptGulfRemoteBody => 'Egypt and the Gulf, and remote jobs from any country';

  @override
  String get scopeRemote => 'Remote';

  @override
  String get scopeRemoteBody => 'Remote jobs, from any country';

  @override
  String get scopeWorldwide => 'Anywhere in the world';

  @override
  String get scopeWorldwideBody => 'Every job, in every country';

  @override
  String get cvTitle => 'Upload your CV';

  @override
  String get cvSubtitle => 'We read it once to fill in your profile. Only you can see it.';

  @override
  String get cvPick => 'Choose a file';

  @override
  String get cvPickHint => 'PDF or Word (.docx), up to 4 MB';

  @override
  String cvUploading(int percent) {
    return 'Uploading… $percent%';
  }

  @override
  String get cvReading => 'Reading your CV';

  @override
  String get cvReadingSkills => 'Finding your skills';

  @override
  String get cvReadingTitles => 'Choosing the jobs to search for';

  @override
  String get cvReadingHint => 'This takes a few seconds.';

  @override
  String get cvUseCurrent => 'Continue with this CV';

  @override
  String get cvUploadNew => 'Upload a new one';

  @override
  String get cvReplace => 'Replace';

  @override
  String get cvDelete => 'Delete CV';

  @override
  String get cvDeleteConfirmTitle => 'Delete your CV?';

  @override
  String get cvDeleteConfirmBody => 'The file and its text are deleted for good. Your profile stays as it is.';

  @override
  String get cvDeleted => 'CV deleted';

  @override
  String get delete => 'Delete';

  @override
  String cvPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pages', one: '1 page');
    return '$_temp0';
  }

  @override
  String cvUploadedOn(String date) {
    return 'Uploaded $date';
  }

  @override
  String get cvPartial => 'We couldn\'t read your CV completely. Check your profile, or let us read it again.';

  @override
  String get cvReanalyze => 'Read it again';

  @override
  String get cvErrTooLarge => 'This file is larger than 4 MB.';

  @override
  String get cvErrBadType => 'Only PDF or Word (.docx) files, please.';

  @override
  String get cvErrEmpty => 'This file is empty.';

  @override
  String get cvErrUnreadable => 'We couldn\'t open this file. Try saving it again as a PDF.';

  @override
  String get cvErrEncrypted => 'This PDF has a password. Upload a copy without one.';

  @override
  String get cvErrNoText => 'This PDF is a scanned picture with no text. Upload a PDF saved from Word or Google Docs.';

  @override
  String get cvErrNotCv => 'This doesn\'t look like a CV.';

  @override
  String get cvErrAiBusy => 'We can\'t read CVs right now. Please try again in a few minutes.';

  @override
  String get cvErrTooMany => 'You\'ve uploaded a lot of CVs today. Please try again later.';

  @override
  String get reviewTitle => 'Here\'s what we found';

  @override
  String get reviewSubtitle => 'Check it and change anything you like. Your matches are built on it.';

  @override
  String get fieldHeadline => 'Headline';

  @override
  String get fieldHeadlineHint => 'e.g. Network Engineer, 3 years at ISPs';

  @override
  String get fieldRoles => 'The jobs you want';

  @override
  String get fieldRolesHelp =>
      'Your matches and our LinkedIn searches are built on these. Up to 5. Not in the list? Type it and add it.';

  @override
  String get fieldLevel => 'Level';

  @override
  String get levelIntern => 'Intern';

  @override
  String get levelJunior => 'Junior';

  @override
  String get levelMid => 'Mid-level';

  @override
  String get levelSenior => 'Senior';

  @override
  String get levelManager => 'Manager';

  @override
  String get fieldYears => 'Years of experience';

  @override
  String get fieldSkills => 'Skills';

  @override
  String get fieldExtraSkills => 'Also on your CV';

  @override
  String get fieldExtraSkillsHelp => 'Shown on your profile; not used for matching yet.';

  @override
  String get fieldScope => 'Where you want to work';

  @override
  String get add => 'Add';

  @override
  String get change => 'Change';

  @override
  String get searchHint => 'Search';

  @override
  String get noResults => 'Nothing found';

  @override
  String get rolesRequired => 'Add at least one job you want.';

  @override
  String get limitReached => 'You\'ve reached the limit.';

  @override
  String get finishSetup => 'Show my jobs';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get errUnknownValues => 'Some choices aren\'t available any more. Remove them and save again.';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get jobPreferences => 'Job preferences';

  @override
  String get notSet => 'Not set';

  @override
  String get setUpProfile => 'Set up your profile';

  @override
  String get setUpProfileBody => 'Tell us where you want to work and upload your CV. It takes a minute.';

  @override
  String pickerAddTitle(String text) {
    return 'Add “$text”';
  }

  @override
  String pickerAddSkill(String text) {
    return 'Add “$text”';
  }

  @override
  String get addedToExtraSkills => 'Added to your skills';

  @override
  String jobsLimit(int count) {
    return 'You can choose up to $count jobs. Remove one to add another.';
  }

  @override
  String get firstJobsTitle => 'Finding your first jobs';

  @override
  String get firstJobsSubtitle =>
      'We\'re searching LinkedIn for your job titles right now. Jobs show up here the moment we find them.';

  @override
  String get firstJobsDoneTitle => 'Your jobs are ready';

  @override
  String get firstJobsDoneSubtitle =>
      'We searched for every one of your job titles. New jobs keep coming in, day and night.';

  @override
  String get firstJobsSlowTitle => 'Still searching';

  @override
  String get firstJobsSlowSubtitle =>
      'This is taking longer than usual. Your jobs will show up in For you as we find them.';

  @override
  String firstJobsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs found so far',
      one: '1 job found so far',
      zero: 'No jobs yet',
    );
    return '$_temp0';
  }

  @override
  String firstJobsFoundDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs found',
      one: '1 job found',
      zero: 'No jobs found yet',
    );
    return '$_temp0';
  }

  @override
  String firstJobsFoundMore(int count) {
    return 'More than $count jobs found';
  }

  @override
  String get firstJobsNoneYet => 'No match yet. We keep looking, and new jobs will show up in For you.';

  @override
  String get firstJobsTipPosts => 'Reading the newest hiring posts on LinkedIn…';

  @override
  String get firstJobsTipJobs => 'Looking through LinkedIn Jobs too…';

  @override
  String get firstJobsTipMatch => 'Matching every job to your skills and level…';

  @override
  String get firstJobsTipApply => 'Finding how to apply: e-mail, WhatsApp, Easy Apply…';

  @override
  String get firstJobsSeeNow => 'See my jobs now';

  @override
  String get firstJobsSeeAll => 'See all my jobs';

  @override
  String errorCode(String code) {
    return 'Error code: $code';
  }

  @override
  String get upgradeTitle => 'Unlock unlimited applications';

  @override
  String upgradeUsedUp(int limit) {
    return 'You\'ve used your $limit free applications. Upgrade to send your CV to every job that fits you, by hand and with auto apply.';
  }

  @override
  String get upgradeIntro => 'Send your CV to every job that fits you, by hand and with auto apply, with no limit.';

  @override
  String get upgradePerkUnlimited => 'Unlimited applications by e-mail';

  @override
  String get upgradePerkAuto => 'Auto apply day and night, as many jobs as fit you';

  @override
  String get upgradePerkLetters => 'A cover letter written for every job';

  @override
  String get upgradeButton => 'Upgrade';

  @override
  String upgradeHow(String email) {
    return 'You\'ll chat with us on WhatsApp to subscribe. Your plan is turned on for $email as soon as it\'s paid.';
  }

  @override
  String get upgradeHowNoEmail =>
      'You\'ll chat with us on WhatsApp to subscribe. Your plan is turned on for the Gmail you signed in with as soon as it\'s paid.';

  @override
  String lockedJobsBody(int limit) {
    return 'You\'ve used your $limit free applications. New jobs that fit you keep coming: upgrade to apply to all of them.';
  }

  @override
  String get autoApplyProblemFreeLimit => 'Your free applications are used up. Upgrade to keep applying.';

  @override
  String get freeUsedTitle => 'Free applications used up';

  @override
  String freeLeft(int left, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: '$left of $limit free applications left',
      one: '1 of $limit free applications left',
      zero: 'No free applications left',
    );
    return '$_temp0';
  }

  @override
  String get planTitle => 'Plan';

  @override
  String get planFree => 'Free';

  @override
  String get planPro => 'Pro · unlimited applications';

  @override
  String planProUntil(String date) {
    return 'Pro · until $date';
  }

  @override
  String get proWelcomeTitle => 'Welcome to Pro!';

  @override
  String get proWelcomeBody => 'Your plan is on. Thank you for joining! Every job that fits you is open to you now.';

  @override
  String get proWelcomeButton => 'Let\'s go';

  @override
  String get gmailAccountOnly => 'The Gmail you signed in with. It sends your applications and holds your plan.';

  @override
  String gmailErrorNotAccount(String email) {
    return 'Use the Gmail you signed in with: $email';
  }

  @override
  String get autoApplyHomeOff => 'Off · Sends your CV to new jobs that fit you';

  @override
  String get autoApplyHomeSetup => 'Off · One-time Gmail setup, about 2 minutes';

  @override
  String get autoApplyHomeUpgrade => 'Upgrade to turn it on';

  @override
  String get autoApplyTurningOn => 'Turning on…';

  @override
  String get autoApplyTurningOff => 'Turning off…';

  @override
  String get autoApplyHomeError => 'Couldn\'t load auto apply. Tap to try again.';

  @override
  String get undo => 'Undo';

  @override
  String get done => 'Done';

  @override
  String get autoApplyReadyTitle => 'You\'re all set!';

  @override
  String get autoApplyReadyBody =>
      'Auto apply is on. Autolinky now sends your CV to new jobs that fit you, from your Gmail:';

  @override
  String autoApplyReadyMatch(int percent) {
    return 'Jobs that fit you $percent% or more';
  }

  @override
  String autoApplyReadyPace(int count, int minutes) {
    return 'Up to $count CVs a day, at least $minutes min apart';
  }

  @override
  String get autoApplyAdjust => 'Adjust settings';

  @override
  String get autoApplyConnectGmail => 'Connect your Gmail';

  @override
  String get autoApplyConnectGmailBody => 'Auto apply sends from it. 3 quick steps.';

  @override
  String get setupDuration => '3 quick steps · about 2 minutes';

  @override
  String get setupTwoStepTitle => 'Turn on 2-Step Verification';

  @override
  String get setupTwoStepBody =>
      'Your CV goes out from your own Gmail, so replies come straight to you. For that, Google needs 2-Step Verification on your account.';

  @override
  String get setupTwoStepHow1 => 'Tap the button below: your Google account opens';

  @override
  String get setupTwoStepHow2 => 'Turn on 2-Step Verification and follow Google\'s steps';

  @override
  String get setupTwoStepHow3 => 'Come back to Autolinky when it\'s on';

  @override
  String get setupAlreadyOn => 'It\'s already on';

  @override
  String get setupWelcomeBack => 'Welcome back! If 2-Step Verification is on now, go on to the next step.';

  @override
  String get setupNext => 'Next';

  @override
  String get setupOpenAgain => 'Open it again';

  @override
  String get setupAppPasswordTitle => 'Create an app password';

  @override
  String get setupAppPasswordBody =>
      'A 16-letter key Google makes for one app. Autolinky uses it only to send your applications, and never sees your real password.';

  @override
  String get setupAppPasswordHow1 => 'Type Autolinky as the app name, then tap Create';

  @override
  String get setupAppPasswordHow2 => 'Copy the 16-letter password Google shows';

  @override
  String get setupAppPasswordHow3 => 'Come back here: Autolinky pastes it for you';

  @override
  String get setupAppPasswordTip => 'No App passwords page? Turn on 2-Step Verification first (step 1).';

  @override
  String get setupHaveOne => 'I already have one';

  @override
  String get setupCopied => 'I copied it';

  @override
  String get setupPreviewAppName => 'App name';

  @override
  String get setupPreviewCreate => 'Create';

  @override
  String get setupPasteTitle => 'Paste your app password';

  @override
  String get setupPasteBody => 'Gmail checks it before it\'s saved. Nothing is sent.';

  @override
  String get setupPastedForYou => 'Pasted the app password you copied.';

  @override
  String setupLetters(int count) {
    return '$count of 16 letters';
  }

  @override
  String get setupMakeNew => 'Make a new one';

  @override
  String get setupConnectTurnOn => 'Connect and turn on';

  @override
  String get setupReconnect => 'Gmail stopped accepting your app password. Make a new one: it takes 2 minutes.';

  @override
  String get filterNotApplied => 'Not applied';

  @override
  String get exploreAllAppliedTitle => 'You\'ve applied to all of these';

  @override
  String get exploreAllAppliedBody => 'Turn off \"Not applied\" to see them again.';

  @override
  String get showAll => 'Show all';

  @override
  String get upgradePromoTitle => 'Do you have a promo code?';

  @override
  String get upgradePromoBody => 'If you have one, it goes with your request on WhatsApp and you get the discount.';

  @override
  String get upgradePromoYes => 'Yes, I have a code';

  @override
  String get upgradePromoNo => 'No, continue to WhatsApp';

  @override
  String get upgradePromoEnter => 'Enter your promo code';

  @override
  String get upgradePromoLabel => 'Promo code';

  @override
  String get upgradePromoHelper => 'Type it exactly as you got it.';

  @override
  String get upgradePromoContinue => 'Continue to WhatsApp';

  @override
  String get upgradePromoSkip => 'Continue without a code';

  @override
  String get emailLinkConfirmTitle => 'Finish signing in';

  @override
  String get emailLinkConfirmBody =>
      'Confirm the email address that received this link. On another device, enter the same address you used to request it.';

  @override
  String get emailLinkConfirm => 'Sign in';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get signedInWithApple => 'Signed in with Apple';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your profile, CV, applications, mail connection and device registrations. Any subscription remains on record; contact support about billing.';

  @override
  String deleteAccountConfirm(String email) {
    return 'Type $email to confirm deletion.';
  }

  @override
  String get deleteAccountSending =>
      'An email is still being processed. Account deletion is paused until its delivery status is resolved.';
}
