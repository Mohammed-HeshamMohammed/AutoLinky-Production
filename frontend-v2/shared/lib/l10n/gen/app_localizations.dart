import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Autolinky'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs that fit you, found for you'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your CV once. Autolinky reads it, watches LinkedIn around the clock and brings you the jobs that match.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomePointMatch.
  ///
  /// In en, this message translates to:
  /// **'Matched to your CV, with the reasons'**
  String get welcomePointMatch;

  /// No description provided for @welcomePointFresh.
  ///
  /// In en, this message translates to:
  /// **'New jobs every few minutes'**
  String get welcomePointFresh;

  /// No description provided for @welcomePointApply.
  ///
  /// In en, this message translates to:
  /// **'Apply by email, WhatsApp or link in one tap'**
  String get welcomePointApply;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get continueWithEmail;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @legalPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get legalPrefix;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @legalAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get legalAnd;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @emailTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get emailTitle;

  /// No description provided for @emailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a sign-in link. No password needed.'**
  String get emailSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send sign-in link'**
  String get sendCode;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get verifyTitle;

  /// No description provided for @verifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the sign-in link we sent to {email}. You can return here to request another link.'**
  String verifySubtitle(String email);

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend link'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend link in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @codeSent.
  ///
  /// In en, this message translates to:
  /// **'A new sign-in link is on its way'**
  String get codeSent;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get changeEmail;

  /// No description provided for @navMatches.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get navMatches;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @matchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs for you'**
  String get matchesTitle;

  /// No description provided for @matchesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your matches will appear here'**
  String get matchesEmptyTitle;

  /// No description provided for @matchesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Upload your CV and we\'ll find the jobs that fit you, with the reasons for each match.'**
  String get matchesEmptyBody;

  /// No description provided for @matchesMoreError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more jobs.'**
  String get matchesMoreError;

  /// No description provided for @tabApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get tabApplied;

  /// No description provided for @channelEmail.
  ///
  /// In en, this message translates to:
  /// **'Auto apply'**
  String get channelEmail;

  /// No description provided for @channelEasyApply.
  ///
  /// In en, this message translates to:
  /// **'Easy Apply'**
  String get channelEasyApply;

  /// No description provided for @channelWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get channelWhatsapp;

  /// No description provided for @channelLink.
  ///
  /// In en, this message translates to:
  /// **'Apply link'**
  String get channelLink;

  /// No description provided for @channelCompanySite.
  ///
  /// In en, this message translates to:
  /// **'Company site'**
  String get channelCompanySite;

  /// No description provided for @channelMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get channelMessage;

  /// No description provided for @channelComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get channelComment;

  /// No description provided for @channelEmailAbout.
  ///
  /// In en, this message translates to:
  /// **'Posts that ask for CVs by email: Autolinky sends yours for you.'**
  String get channelEmailAbout;

  /// No description provided for @channelEasyApplyAbout.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn jobs you apply to in a few taps, on LinkedIn.'**
  String get channelEasyApplyAbout;

  /// No description provided for @channelWhatsappAbout.
  ///
  /// In en, this message translates to:
  /// **'Posts with a number: message the recruiter on WhatsApp.'**
  String get channelWhatsappAbout;

  /// No description provided for @channelLinkAbout.
  ///
  /// In en, this message translates to:
  /// **'Posts with a form or a careers page to apply on.'**
  String get channelLinkAbout;

  /// No description provided for @channelCompanySiteAbout.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn jobs you apply to on the company\'s website.'**
  String get channelCompanySiteAbout;

  /// No description provided for @channelMessageAbout.
  ///
  /// In en, this message translates to:
  /// **'Posts that ask you to message the person who posted.'**
  String get channelMessageAbout;

  /// No description provided for @channelCommentAbout.
  ///
  /// In en, this message translates to:
  /// **'Posts that ask you to comment to apply.'**
  String get channelCommentAbout;

  /// No description provided for @bestFitFirst.
  ///
  /// In en, this message translates to:
  /// **'Best fit first.'**
  String get bestFitFirst;

  /// No description provided for @channelEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get channelEmptyTitle;

  /// No description provided for @emptyPullHint.
  ///
  /// In en, this message translates to:
  /// **'New jobs arrive every few minutes: pull down to check.'**
  String get emptyPullHint;

  /// No description provided for @applyEmail.
  ///
  /// In en, this message translates to:
  /// **'Send my CV'**
  String get applyEmail;

  /// No description provided for @applyEasyApply.
  ///
  /// In en, this message translates to:
  /// **'Easy Apply'**
  String get applyEasyApply;

  /// No description provided for @applyWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get applyWhatsapp;

  /// No description provided for @applyLink.
  ///
  /// In en, this message translates to:
  /// **'Open the link'**
  String get applyLink;

  /// No description provided for @applyCompanySite.
  ///
  /// In en, this message translates to:
  /// **'Apply on their site'**
  String get applyCompanySite;

  /// No description provided for @applyMessage.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get applyMessage;

  /// No description provided for @applyComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get applyComment;

  /// No description provided for @applyChoose.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyChoose;

  /// No description provided for @showDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get showDetails;

  /// No description provided for @thePost.
  ///
  /// In en, this message translates to:
  /// **'The post'**
  String get thePost;

  /// No description provided for @jobDescription.
  ///
  /// In en, this message translates to:
  /// **'Job description'**
  String get jobDescription;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description was given.'**
  String get noDescription;

  /// No description provided for @waysToApply.
  ///
  /// In en, this message translates to:
  /// **'Ways to apply'**
  String get waysToApply;

  /// No description provided for @openOnLinkedIn.
  ///
  /// In en, this message translates to:
  /// **'Open on LinkedIn'**
  String get openOnLinkedIn;

  /// No description provided for @appliedAgo.
  ///
  /// In en, this message translates to:
  /// **'Applied · {when}'**
  String appliedAgo(String when);

  /// No description provided for @emailQueued.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get emailQueued;

  /// No description provided for @emailSent.
  ///
  /// In en, this message translates to:
  /// **'CV sent · {when}'**
  String emailSent(String when);

  /// No description provided for @emailFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get emailFailed;

  /// No description provided for @appliedVia.
  ///
  /// In en, this message translates to:
  /// **'Via {way}'**
  String appliedVia(String way);

  /// No description provided for @appliedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 application} other{{count} applications}}'**
  String appliedCount(int count);

  /// No description provided for @appliedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No applications yet'**
  String get appliedEmptyTitle;

  /// No description provided for @appliedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Apply to a job and it shows here, so you always know where you applied.'**
  String get appliedEmptyBody;

  /// No description provided for @removeApplied.
  ///
  /// In en, this message translates to:
  /// **'Remove from Applied'**
  String get removeApplied;

  /// No description provided for @removedApplied.
  ///
  /// In en, this message translates to:
  /// **'Removed from Applied'**
  String get removedApplied;

  /// No description provided for @cannotRemoveSent.
  ///
  /// In en, this message translates to:
  /// **'Your CV was already emailed: it stays in Applied.'**
  String get cannotRemoveSent;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @didYouApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Did you apply?'**
  String get didYouApplyTitle;

  /// No description provided for @didYouApplyBody.
  ///
  /// In en, this message translates to:
  /// **'Say yes and we\'ll keep it in Applied, so you know where you applied.'**
  String get didYouApplyBody;

  /// No description provided for @yesApplied.
  ///
  /// In en, this message translates to:
  /// **'Yes, I applied'**
  String get yesApplied;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @savedApplied.
  ///
  /// In en, this message translates to:
  /// **'Added to Applied'**
  String get savedApplied;

  /// No description provided for @applyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This way to apply isn\'t in the job any more.'**
  String get applyUnavailable;

  /// No description provided for @applyCannotOpen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open it on this phone.'**
  String get applyCannotOpen;

  /// No description provided for @chooseWayTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you want to apply?'**
  String get chooseWayTitle;

  /// No description provided for @whatsappMessage.
  ///
  /// In en, this message translates to:
  /// **'Kindly find my attached CV for the position of {title}.'**
  String whatsappMessage(String title);

  /// No description provided for @sendCvTitle.
  ///
  /// In en, this message translates to:
  /// **'Send your CV?'**
  String get sendCvTitle;

  /// No description provided for @sendCvTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get sendCvTo;

  /// No description provided for @sendCvSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get sendCvSubject;

  /// No description provided for @sendCvAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get sendCvAttachment;

  /// No description provided for @sendCvButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendCvButton;

  /// No description provided for @autoApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto apply'**
  String get autoApplyTitle;

  /// No description provided for @autoApplyBody.
  ///
  /// In en, this message translates to:
  /// **'Turn it on and Autolinky emails your CV to every new job here that fits you, from your own Gmail.'**
  String get autoApplyBody;

  /// No description provided for @autoApplyTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get autoApplyTurnOn;

  /// No description provided for @autoApplyOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get autoApplyOn;

  /// No description provided for @connectEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect your Gmail'**
  String get connectEmailTitle;

  /// No description provided for @connectEmailBody.
  ///
  /// In en, this message translates to:
  /// **'Autolinky sends your applications from your own Gmail, with your CV attached.'**
  String get connectEmailBody;

  /// No description provided for @connectEmailPointAddress.
  ///
  /// In en, this message translates to:
  /// **'Sent from your address, so replies come straight to you'**
  String get connectEmailPointAddress;

  /// No description provided for @connectEmailPointLetter.
  ///
  /// In en, this message translates to:
  /// **'A short cover letter written for each job'**
  String get connectEmailPointLetter;

  /// No description provided for @connectEmailPointStop.
  ///
  /// In en, this message translates to:
  /// **'Pause it any time'**
  String get connectEmailPointStop;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @gmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Gmail'**
  String get gmailTitle;

  /// No description provided for @gmailIntroSend.
  ///
  /// In en, this message translates to:
  /// **'Your CV goes out from your own Gmail, so replies come straight to you. Connect it once: every \"Send my CV\" uses it.'**
  String get gmailIntroSend;

  /// No description provided for @gmailIntroAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto apply sends your CV from your own Gmail. Connect it once, then choose how auto apply works.'**
  String get gmailIntroAuto;

  /// No description provided for @gmailIntroSettings.
  ///
  /// In en, this message translates to:
  /// **'Autolinky sends your applications from your own Gmail with an app password: a separate password Google makes for one app, which you can delete any time.'**
  String get gmailIntroSettings;

  /// No description provided for @gmailInvalidBanner.
  ///
  /// In en, this message translates to:
  /// **'Gmail stopped accepting your app password (it may have been deleted, or 2-Step Verification turned off). Make a new one and paste it below.'**
  String get gmailInvalidBanner;

  /// No description provided for @gmailStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Get an app password (2 minutes)'**
  String get gmailStepsTitle;

  /// No description provided for @gmailStep1.
  ///
  /// In en, this message translates to:
  /// **'Turn on 2-Step Verification for your Google account: app passwords need it.'**
  String get gmailStep1;

  /// No description provided for @gmailStep1Button.
  ///
  /// In en, this message translates to:
  /// **'Open 2-Step Verification'**
  String get gmailStep1Button;

  /// No description provided for @gmailStep2.
  ///
  /// In en, this message translates to:
  /// **'Open App passwords, type Autolinky as the app\'s name, then tap Create.'**
  String get gmailStep2;

  /// No description provided for @gmailStep2Button.
  ///
  /// In en, this message translates to:
  /// **'Open App passwords'**
  String get gmailStep2Button;

  /// No description provided for @gmailStep3.
  ///
  /// In en, this message translates to:
  /// **'Copy the 16-letter password Google shows and paste it below. Use the Google account of the address below.'**
  String get gmailStep3;

  /// No description provided for @gmailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Gmail address'**
  String get gmailAddressLabel;

  /// No description provided for @gmailNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get gmailNameLabel;

  /// No description provided for @gmailNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Recruiters see this name, and your letter is signed with it.'**
  String get gmailNameHelper;

  /// No description provided for @gmailPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'App password'**
  String get gmailPasswordLabel;

  /// No description provided for @gmailPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'16 letters. Spaces are fine.'**
  String get gmailPasswordHelper;

  /// No description provided for @gmailPasswordKeep.
  ///
  /// In en, this message translates to:
  /// **'Leave it empty to keep the saved one.'**
  String get gmailPasswordKeep;

  /// No description provided for @gmailPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get gmailPaste;

  /// No description provided for @gmailShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get gmailShowPassword;

  /// No description provided for @gmailHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get gmailHidePassword;

  /// No description provided for @gmailConnect.
  ///
  /// In en, this message translates to:
  /// **'Check and connect'**
  String get gmailConnect;

  /// No description provided for @gmailSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get gmailSave;

  /// No description provided for @gmailChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking with Gmail…'**
  String get gmailChecking;

  /// No description provided for @gmailConnected.
  ///
  /// In en, this message translates to:
  /// **'Gmail connected'**
  String get gmailConnected;

  /// No description provided for @gmailSavedUnverified.
  ///
  /// In en, this message translates to:
  /// **'Saved. Gmail couldn\'t be reached to check it now: your first CV will.'**
  String get gmailSavedUnverified;

  /// No description provided for @gmailPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your app password is encrypted and used only to send your applications. Delete it here or from your Google account any time.'**
  String get gmailPrivacy;

  /// No description provided for @gmailSignatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get gmailSignatureLabel;

  /// No description provided for @gmailSignatureHelper.
  ///
  /// In en, this message translates to:
  /// **'Under your name in every e-mail. Taken from your CV: change it as you like.'**
  String get gmailSignatureHelper;

  /// No description provided for @gmailSignatureReset.
  ///
  /// In en, this message translates to:
  /// **'Use the one from my CV'**
  String get gmailSignatureReset;

  /// No description provided for @sendCvLetterAi.
  ///
  /// In en, this message translates to:
  /// **'Written for this job from your CV. You can change it before sending.'**
  String get sendCvLetterAi;

  /// No description provided for @sendCvLetterTemplate.
  ///
  /// In en, this message translates to:
  /// **'A short letter. You can change it before sending.'**
  String get sendCvLetterTemplate;

  /// No description provided for @sendCvLetterEmpty.
  ///
  /// In en, this message translates to:
  /// **'Write a few lines to the recruiter'**
  String get sendCvLetterEmpty;

  /// No description provided for @gmailStatusOk.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get gmailStatusOk;

  /// No description provided for @gmailStatusUnverified.
  ///
  /// In en, this message translates to:
  /// **'Saved, not checked yet'**
  String get gmailStatusUnverified;

  /// No description provided for @gmailStatusInvalid.
  ///
  /// In en, this message translates to:
  /// **'Needs a new app password'**
  String get gmailStatusInvalid;

  /// No description provided for @gmailDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Gmail'**
  String get gmailDisconnect;

  /// No description provided for @gmailDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Gmail?'**
  String get gmailDisconnectTitle;

  /// No description provided for @gmailDisconnectBody.
  ///
  /// In en, this message translates to:
  /// **'Autolinky forgets the app password and auto apply turns off. To cancel it at Google too, delete it in App passwords.'**
  String get gmailDisconnectBody;

  /// No description provided for @gmailDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Gmail disconnected'**
  String get gmailDisconnected;

  /// No description provided for @gmailErrorName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get gmailErrorName;

  /// No description provided for @gmailErrorFormat.
  ///
  /// In en, this message translates to:
  /// **'An app password is 16 letters, like abcd efgh ijkl mnop.'**
  String get gmailErrorFormat;

  /// No description provided for @gmailErrorWrong.
  ///
  /// In en, this message translates to:
  /// **'Gmail didn\'t accept this app password. Check it was made for this address, then try again.'**
  String get gmailErrorWrong;

  /// No description provided for @gmailErrorNotApp.
  ///
  /// In en, this message translates to:
  /// **'That looks like your Google password. Autolinky needs an app password (step 2), never your real password.'**
  String get gmailErrorNotApp;

  /// No description provided for @gmailErrorBlocked.
  ///
  /// In en, this message translates to:
  /// **'Google wants you to sign in to Gmail in a browser first. Do that, then try again.'**
  String get gmailErrorBlocked;

  /// No description provided for @gmailErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sending from Gmail isn\'t available right now. Try again later.'**
  String get gmailErrorUnavailable;

  /// No description provided for @gmailErrorNeedPassword.
  ///
  /// In en, this message translates to:
  /// **'Paste an app password for this address.'**
  String get gmailErrorNeedPassword;

  /// No description provided for @sendCvFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get sendCvFrom;

  /// No description provided for @sendCvLetter.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get sendCvLetter;

  /// No description provided for @cvSentTo.
  ///
  /// In en, this message translates to:
  /// **'CV sent to {address}'**
  String cvSentTo(String address);

  /// No description provided for @sendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get sendAgain;

  /// No description provided for @appliedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Sent by auto apply'**
  String get appliedAutomatically;

  /// No description provided for @emailErrorAddressRefused.
  ///
  /// In en, this message translates to:
  /// **'Not sent: the job\'s address refused it.'**
  String get emailErrorAddressRefused;

  /// No description provided for @emailErrorMessageRefused.
  ///
  /// In en, this message translates to:
  /// **'Not sent: Gmail refused the message.'**
  String get emailErrorMessageRefused;

  /// No description provided for @emailErrorInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Interrupted while sending: check your Gmail\'s Sent folder.'**
  String get emailErrorInterrupted;

  /// No description provided for @emailErrorGmailLimit.
  ///
  /// In en, this message translates to:
  /// **'Gmail\'s daily sending limit is reached. Try again tomorrow.'**
  String get emailErrorGmailLimit;

  /// No description provided for @emailErrorGmailBusy.
  ///
  /// In en, this message translates to:
  /// **'Gmail didn\'t answer. Try again in a minute.'**
  String get emailErrorGmailBusy;

  /// No description provided for @emailErrorDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'That\'s today\'s limit of CVs, to keep your Gmail safe. Try again tomorrow.'**
  String get emailErrorDailyLimit;

  /// No description provided for @emailErrorNoCv.
  ///
  /// In en, this message translates to:
  /// **'Upload your CV first: it\'s what gets attached.'**
  String get emailErrorNoCv;

  /// No description provided for @autoApplyOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto apply is off'**
  String get autoApplyOffTitle;

  /// No description provided for @autoApplyOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn it on and Autolinky sends your CV to the jobs that fit you, from your Gmail, a few at a time.'**
  String get autoApplyOffBody;

  /// No description provided for @autoApplyOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto apply is on'**
  String get autoApplyOnTitle;

  /// No description provided for @autoApplySentToday.
  ///
  /// In en, this message translates to:
  /// **'{sent} of {limit} CVs sent today'**
  String autoApplySentToday(int sent, int limit);

  /// No description provided for @autoApplyNextIn.
  ///
  /// In en, this message translates to:
  /// **'Next CV in about {minutes} min'**
  String autoApplyNextIn(int minutes);

  /// No description provided for @autoApplyNextSoon.
  ///
  /// In en, this message translates to:
  /// **'Next CV any moment'**
  String get autoApplyNextSoon;

  /// No description provided for @autoApplyWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No jobs waiting: it sends as new ones that fit you arrive} =1{1 job waiting} other{{count} jobs waiting}}'**
  String autoApplyWaiting(int count);

  /// No description provided for @autoApplyStart.
  ///
  /// In en, this message translates to:
  /// **'Start auto apply'**
  String get autoApplyStart;

  /// No description provided for @autoApplyStop.
  ///
  /// In en, this message translates to:
  /// **'Turn off auto apply'**
  String get autoApplyStop;

  /// No description provided for @autoApplyBackground.
  ///
  /// In en, this message translates to:
  /// **'Continue in background'**
  String get autoApplyBackground;

  /// No description provided for @autoApplyBackgroundNote.
  ///
  /// In en, this message translates to:
  /// **'You can close Autolinky: sending happens on our server, and you get a notification when a CV goes out.'**
  String get autoApplyBackgroundNote;

  /// No description provided for @autoApplyMinMatch.
  ///
  /// In en, this message translates to:
  /// **'Only jobs that fit you at least'**
  String get autoApplyMinMatch;

  /// No description provided for @autoApplyDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'CVs a day, at most'**
  String get autoApplyDailyLimit;

  /// No description provided for @autoApplyGap.
  ///
  /// In en, this message translates to:
  /// **'Minutes between two CVs, at least'**
  String get autoApplyGap;

  /// No description provided for @autoApplyGapSafety.
  ///
  /// In en, this message translates to:
  /// **'Gmail lets a personal account send up to 500 e-mails a day, but sending faster than about 20 an hour can get your sending stopped for up to a day. 3 minutes is the closest Autolinky goes.'**
  String get autoApplyGapSafety;

  /// No description provided for @autoApplyHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How it sends'**
  String get autoApplyHowTitle;

  /// No description provided for @autoApplyHowGap.
  ///
  /// In en, this message translates to:
  /// **'One at a time, at least the minutes you chose apart, plus a little at random, like a person'**
  String get autoApplyHowGap;

  /// No description provided for @autoApplyHowHours.
  ///
  /// In en, this message translates to:
  /// **'Day and night, at most 15 an hour'**
  String get autoApplyHowHours;

  /// No description provided for @autoApplyHowOnce.
  ///
  /// In en, this message translates to:
  /// **'Never the same recruiter twice in a month, never a job you applied to'**
  String get autoApplyHowOnce;

  /// No description provided for @autoApplyHowFresh.
  ///
  /// In en, this message translates to:
  /// **'Only jobs from the last 2 weeks, best fit first'**
  String get autoApplyHowFresh;

  /// No description provided for @autoApplyHowGmail.
  ///
  /// In en, this message translates to:
  /// **'From your Gmail: every e-mail is in your Sent folder'**
  String get autoApplyHowGmail;

  /// No description provided for @autoApplySendsFrom.
  ///
  /// In en, this message translates to:
  /// **'Sends from'**
  String get autoApplySendsFrom;

  /// No description provided for @autoApplyNotificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off: you\'ll find what was sent in Applied.'**
  String get autoApplyNotificationsOff;

  /// No description provided for @autoApplyProblemEmail.
  ///
  /// In en, this message translates to:
  /// **'Gmail stopped accepting your app password. Nothing is sent until you add a new one.'**
  String get autoApplyProblemEmail;

  /// No description provided for @autoApplyProblemNoCv.
  ///
  /// In en, this message translates to:
  /// **'Upload your CV: auto apply has nothing to attach.'**
  String get autoApplyProblemNoCv;

  /// No description provided for @autoApplyProblemLimit.
  ///
  /// In en, this message translates to:
  /// **'Gmail\'s daily limit was reached: auto apply carries on tomorrow.'**
  String get autoApplyProblemLimit;

  /// No description provided for @autoApplyProblemBusy.
  ///
  /// In en, this message translates to:
  /// **'Gmail asked to wait a little: auto apply carries on shortly.'**
  String get autoApplyProblemBusy;

  /// No description provided for @autoApplyProblemOffline.
  ///
  /// In en, this message translates to:
  /// **'Sending is paused for a moment: your CVs go out as soon as it\'s back.'**
  String get autoApplyProblemOffline;

  /// No description provided for @autoApplyFixGmail.
  ///
  /// In en, this message translates to:
  /// **'Fix Gmail'**
  String get autoApplyFixGmail;

  /// No description provided for @autoApplyUploadCv.
  ///
  /// In en, this message translates to:
  /// **'Upload CV'**
  String get autoApplyUploadCv;

  /// No description provided for @autoApplyManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get autoApplyManage;

  /// No description provided for @autoApplyBannerOn.
  ///
  /// In en, this message translates to:
  /// **'On · {sent} sent today'**
  String autoApplyBannerOn(int sent);

  /// No description provided for @autoApplyBannerProblem.
  ///
  /// In en, this message translates to:
  /// **'Needs your attention'**
  String get autoApplyBannerProblem;

  /// No description provided for @autoApplySentSnack.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Auto apply sent your CV to 1 job} other{Auto apply sent your CV to {count} jobs}}'**
  String autoApplySentSnack(int count);

  /// No description provided for @applyingSection.
  ///
  /// In en, this message translates to:
  /// **'Applying'**
  String get applyingSection;

  /// No description provided for @settingsGmail.
  ///
  /// In en, this message translates to:
  /// **'Gmail'**
  String get settingsGmail;

  /// No description provided for @settingsGmailNone.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settingsGmailNone;

  /// No description provided for @autoApplyOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get autoApplyOff;

  /// No description provided for @notifyChannel.
  ///
  /// In en, this message translates to:
  /// **'When auto apply sends your CV'**
  String get notifyChannel;

  /// No description provided for @notifySentOne.
  ///
  /// In en, this message translates to:
  /// **'CV sent to {company}'**
  String notifySentOne(String company);

  /// No description provided for @notifySentMany.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Auto apply sent {count} CVs}}'**
  String notifySentMany(int count);

  /// No description provided for @notifySeeApplied.
  ///
  /// In en, this message translates to:
  /// **'See them in Applied'**
  String get notifySeeApplied;

  /// No description provided for @notifyProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto apply stopped'**
  String get notifyProblemTitle;

  /// No description provided for @newJobsBar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new job} other{{count} new jobs}}'**
  String newJobsBar(int count);

  /// No description provided for @notifyNewMatches.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A new job fits you} other{{count} new jobs fit you}}'**
  String notifyNewMatches(int count);

  /// No description provided for @notifyNewMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Open Autolinky to see them and apply.'**
  String get notifyNewMatchesBody;

  /// No description provided for @exploreSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search jobs, companies or skills'**
  String get exploreSearchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSearch;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @exploreHeader.
  ///
  /// In en, this message translates to:
  /// **'Newest first, from the last 30 days'**
  String get exploreHeader;

  /// No description provided for @exploreNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No jobs found'**
  String get exploreNoResultsTitle;

  /// No description provided for @exploreNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try other words, or another way to apply.'**
  String get exploreNoResultsBody;

  /// No description provided for @listEnd.
  ///
  /// In en, this message translates to:
  /// **'That\'s all for now. New jobs arrive all the time.'**
  String get listEnd;

  /// No description provided for @matchPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% match'**
  String matchPercent(int percent);

  /// No description provided for @yourSkills.
  ///
  /// In en, this message translates to:
  /// **'Your skills'**
  String get yourSkills;

  /// No description provided for @missingSkills.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missingSkills;

  /// No description provided for @fitSameRole.
  ///
  /// In en, this message translates to:
  /// **'Your job'**
  String get fitSameRole;

  /// No description provided for @fitSimilarRole.
  ///
  /// In en, this message translates to:
  /// **'Close to your job'**
  String get fitSimilarRole;

  /// No description provided for @fitSameField.
  ///
  /// In en, this message translates to:
  /// **'In your field'**
  String get fitSameField;

  /// No description provided for @fitRelatedField.
  ///
  /// In en, this message translates to:
  /// **'A related field'**
  String get fitRelatedField;

  /// No description provided for @fitSkillsOnly.
  ///
  /// In en, this message translates to:
  /// **'Fits your skills'**
  String get fitSkillsOnly;

  /// No description provided for @levelFitMatch.
  ///
  /// In en, this message translates to:
  /// **'Your level'**
  String get levelFitMatch;

  /// No description provided for @levelFitClose.
  ///
  /// In en, this message translates to:
  /// **'Near your level'**
  String get levelFitClose;

  /// No description provided for @workOnsite.
  ///
  /// In en, this message translates to:
  /// **'On-site'**
  String get workOnsite;

  /// No description provided for @workRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get workRemote;

  /// No description provided for @workHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get workHybrid;

  /// No description provided for @placeNotGiven.
  ///
  /// In en, this message translates to:
  /// **'Place not given'**
  String get placeNotGiven;

  /// No description provided for @jobFullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get jobFullTime;

  /// No description provided for @jobPartTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get jobPartTime;

  /// No description provided for @jobContract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get jobContract;

  /// No description provided for @jobTemporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary'**
  String get jobTemporary;

  /// No description provided for @jobInternship.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get jobInternship;

  /// No description provided for @jobFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get jobFreelance;

  /// No description provided for @jobVolunteer.
  ///
  /// In en, this message translates to:
  /// **'Volunteer'**
  String get jobVolunteer;

  /// No description provided for @postedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get postedJustNow;

  /// No description provided for @postedMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String postedMinutes(int count);

  /// No description provided for @postedHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String postedHours(int count);

  /// No description provided for @postedDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String postedDays(int count);

  /// No description provided for @postedWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String postedWeeks(int count);

  /// No description provided for @postedMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String postedMonths(int count);

  /// No description provided for @uploadCv.
  ///
  /// In en, this message translates to:
  /// **'Upload your CV'**
  String get uploadCv;

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @signedInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google'**
  String get signedInWithGoogle;

  /// No description provided for @signedInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Signed in with email'**
  String get signedInWithEmail;

  /// No description provided for @cvSection.
  ///
  /// In en, this message translates to:
  /// **'Your CV'**
  String get cvSection;

  /// No description provided for @cvMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'No CV yet'**
  String get cvMissingTitle;

  /// No description provided for @cvMissingBody.
  ///
  /// In en, this message translates to:
  /// **'Add your CV so we can match you with jobs.'**
  String get cvMissingBody;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You can sign in again any time.'**
  String get signOutConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @versionWithUpdate.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · update {patch}'**
  String versionWithUpdate(String version, int patch);

  /// No description provided for @updatedTitle.
  ///
  /// In en, this message translates to:
  /// **'The app was updated'**
  String get updatedTitle;

  /// No description provided for @updatedBody.
  ///
  /// In en, this message translates to:
  /// **'A new update just arrived and is already running (update {patch}). Nothing else to do.'**
  String updatedBody(int patch);

  /// No description provided for @updatedOk.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get updatedOk;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something\'s not right'**
  String get errorTitle;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'This account can\'t use Autolinky right now. Please contact support.'**
  String get errorForbidden;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get errorRateLimited;

  /// No description provided for @errorRateLimitedFor.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds} seconds.'**
  String errorRateLimitedFor(int seconds);

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @errorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'This sign-in link is invalid or has expired. Request a new link.'**
  String get errorInvalidCode;

  /// No description provided for @errorNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'This sign-in option isn\'t available yet. Please use another one.'**
  String get errorNotConfigured;

  /// No description provided for @configMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'This build isn\'t set up'**
  String get configMissingTitle;

  /// No description provided for @configMissingBody.
  ///
  /// In en, this message translates to:
  /// **'Missing settings: {names}. Build with --dart-define-from-file=env/dev.json'**
  String configMissingBody(String names);

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @scopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to work?'**
  String get scopeTitle;

  /// No description provided for @scopeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll show you jobs there and keep searching for more. You can change it any time.'**
  String get scopeSubtitle;

  /// No description provided for @scopeEgypt.
  ///
  /// In en, this message translates to:
  /// **'Egypt only'**
  String get scopeEgypt;

  /// No description provided for @scopeEgyptBody.
  ///
  /// In en, this message translates to:
  /// **'Jobs in Egypt'**
  String get scopeEgyptBody;

  /// No description provided for @scopeEgyptGulf.
  ///
  /// In en, this message translates to:
  /// **'Egypt and the Gulf'**
  String get scopeEgyptGulf;

  /// No description provided for @scopeEgyptGulfBody.
  ///
  /// In en, this message translates to:
  /// **'Egypt, Saudi Arabia, the UAE, Qatar, Kuwait, Bahrain and Oman'**
  String get scopeEgyptGulfBody;

  /// No description provided for @scopeEgyptRemote.
  ///
  /// In en, this message translates to:
  /// **'Egypt + remote'**
  String get scopeEgyptRemote;

  /// No description provided for @scopeEgyptRemoteBody.
  ///
  /// In en, this message translates to:
  /// **'Jobs in Egypt, and remote jobs from any country'**
  String get scopeEgyptRemoteBody;

  /// No description provided for @scopeEgyptGulfRemote.
  ///
  /// In en, this message translates to:
  /// **'Egypt, the Gulf + remote'**
  String get scopeEgyptGulfRemote;

  /// No description provided for @scopeEgyptGulfRemoteBody.
  ///
  /// In en, this message translates to:
  /// **'Egypt and the Gulf, and remote jobs from any country'**
  String get scopeEgyptGulfRemoteBody;

  /// No description provided for @scopeRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get scopeRemote;

  /// No description provided for @scopeRemoteBody.
  ///
  /// In en, this message translates to:
  /// **'Remote jobs, from any country'**
  String get scopeRemoteBody;

  /// No description provided for @scopeWorldwide.
  ///
  /// In en, this message translates to:
  /// **'Anywhere in the world'**
  String get scopeWorldwide;

  /// No description provided for @scopeWorldwideBody.
  ///
  /// In en, this message translates to:
  /// **'Every job, in every country'**
  String get scopeWorldwideBody;

  /// No description provided for @cvTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your CV'**
  String get cvTitle;

  /// No description provided for @cvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We read it once to fill in your profile. Only you can see it.'**
  String get cvSubtitle;

  /// No description provided for @cvPick.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get cvPick;

  /// No description provided for @cvPickHint.
  ///
  /// In en, this message translates to:
  /// **'PDF or Word (.docx), up to 4 MB'**
  String get cvPickHint;

  /// No description provided for @cvUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading… {percent}%'**
  String cvUploading(int percent);

  /// No description provided for @cvReading.
  ///
  /// In en, this message translates to:
  /// **'Reading your CV'**
  String get cvReading;

  /// No description provided for @cvReadingSkills.
  ///
  /// In en, this message translates to:
  /// **'Finding your skills'**
  String get cvReadingSkills;

  /// No description provided for @cvReadingTitles.
  ///
  /// In en, this message translates to:
  /// **'Choosing the jobs to search for'**
  String get cvReadingTitles;

  /// No description provided for @cvReadingHint.
  ///
  /// In en, this message translates to:
  /// **'This takes a few seconds.'**
  String get cvReadingHint;

  /// No description provided for @cvUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'Continue with this CV'**
  String get cvUseCurrent;

  /// No description provided for @cvUploadNew.
  ///
  /// In en, this message translates to:
  /// **'Upload a new one'**
  String get cvUploadNew;

  /// No description provided for @cvReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get cvReplace;

  /// No description provided for @cvDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete CV'**
  String get cvDelete;

  /// No description provided for @cvDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your CV?'**
  String get cvDeleteConfirmTitle;

  /// No description provided for @cvDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The file and its text are deleted for good. Your profile stays as it is.'**
  String get cvDeleteConfirmBody;

  /// No description provided for @cvDeleted.
  ///
  /// In en, this message translates to:
  /// **'CV deleted'**
  String get cvDeleted;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cvPages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String cvPages(int count);

  /// No description provided for @cvUploadedOn.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {date}'**
  String cvUploadedOn(String date);

  /// No description provided for @cvPartial.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read your CV completely. Check your profile, or let us read it again.'**
  String get cvPartial;

  /// No description provided for @cvReanalyze.
  ///
  /// In en, this message translates to:
  /// **'Read it again'**
  String get cvReanalyze;

  /// No description provided for @cvErrTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is larger than 4 MB.'**
  String get cvErrTooLarge;

  /// No description provided for @cvErrBadType.
  ///
  /// In en, this message translates to:
  /// **'Only PDF or Word (.docx) files, please.'**
  String get cvErrBadType;

  /// No description provided for @cvErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'This file is empty.'**
  String get cvErrEmpty;

  /// No description provided for @cvErrUnreadable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open this file. Try saving it again as a PDF.'**
  String get cvErrUnreadable;

  /// No description provided for @cvErrEncrypted.
  ///
  /// In en, this message translates to:
  /// **'This PDF has a password. Upload a copy without one.'**
  String get cvErrEncrypted;

  /// No description provided for @cvErrNoText.
  ///
  /// In en, this message translates to:
  /// **'This PDF is a scanned picture with no text. Upload a PDF saved from Word or Google Docs.'**
  String get cvErrNoText;

  /// No description provided for @cvErrNotCv.
  ///
  /// In en, this message translates to:
  /// **'This doesn\'t look like a CV.'**
  String get cvErrNotCv;

  /// No description provided for @cvErrAiBusy.
  ///
  /// In en, this message translates to:
  /// **'We can\'t read CVs right now. Please try again in a few minutes.'**
  String get cvErrAiBusy;

  /// No description provided for @cvErrTooMany.
  ///
  /// In en, this message translates to:
  /// **'You\'ve uploaded a lot of CVs today. Please try again later.'**
  String get cvErrTooMany;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what we found'**
  String get reviewTitle;

  /// No description provided for @reviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check it and change anything you like. Your matches are built on it.'**
  String get reviewSubtitle;

  /// No description provided for @fieldHeadline.
  ///
  /// In en, this message translates to:
  /// **'Headline'**
  String get fieldHeadline;

  /// No description provided for @fieldHeadlineHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Network Engineer, 3 years at ISPs'**
  String get fieldHeadlineHint;

  /// No description provided for @fieldRoles.
  ///
  /// In en, this message translates to:
  /// **'The jobs you want'**
  String get fieldRoles;

  /// No description provided for @fieldRolesHelp.
  ///
  /// In en, this message translates to:
  /// **'Your matches and our LinkedIn searches are built on these. Up to 5. Not in the list? Type it and add it.'**
  String get fieldRolesHelp;

  /// No description provided for @fieldLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get fieldLevel;

  /// No description provided for @levelIntern.
  ///
  /// In en, this message translates to:
  /// **'Intern'**
  String get levelIntern;

  /// No description provided for @levelJunior.
  ///
  /// In en, this message translates to:
  /// **'Junior'**
  String get levelJunior;

  /// No description provided for @levelMid.
  ///
  /// In en, this message translates to:
  /// **'Mid-level'**
  String get levelMid;

  /// No description provided for @levelSenior.
  ///
  /// In en, this message translates to:
  /// **'Senior'**
  String get levelSenior;

  /// No description provided for @levelManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get levelManager;

  /// No description provided for @fieldYears.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get fieldYears;

  /// No description provided for @fieldSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get fieldSkills;

  /// No description provided for @fieldExtraSkills.
  ///
  /// In en, this message translates to:
  /// **'Also on your CV'**
  String get fieldExtraSkills;

  /// No description provided for @fieldExtraSkillsHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown on your profile; not used for matching yet.'**
  String get fieldExtraSkillsHelp;

  /// No description provided for @fieldScope.
  ///
  /// In en, this message translates to:
  /// **'Where you want to work'**
  String get fieldScope;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get noResults;

  /// No description provided for @rolesRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one job you want.'**
  String get rolesRequired;

  /// No description provided for @limitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the limit.'**
  String get limitReached;

  /// No description provided for @finishSetup.
  ///
  /// In en, this message translates to:
  /// **'Show my jobs'**
  String get finishSetup;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @errUnknownValues.
  ///
  /// In en, this message translates to:
  /// **'Some choices aren\'t available any more. Remove them and save again.'**
  String get errUnknownValues;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @jobPreferences.
  ///
  /// In en, this message translates to:
  /// **'Job preferences'**
  String get jobPreferences;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @setUpProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get setUpProfile;

  /// No description provided for @setUpProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us where you want to work and upload your CV. It takes a minute.'**
  String get setUpProfileBody;

  /// No description provided for @pickerAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add “{text}”'**
  String pickerAddTitle(String text);

  /// No description provided for @pickerAddSkill.
  ///
  /// In en, this message translates to:
  /// **'Add “{text}”'**
  String pickerAddSkill(String text);

  /// No description provided for @addedToExtraSkills.
  ///
  /// In en, this message translates to:
  /// **'Added to your skills'**
  String get addedToExtraSkills;

  /// No description provided for @jobsLimit.
  ///
  /// In en, this message translates to:
  /// **'You can choose up to {count} jobs. Remove one to add another.'**
  String jobsLimit(int count);

  /// No description provided for @firstJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Finding your first jobs'**
  String get firstJobsTitle;

  /// No description provided for @firstJobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re searching LinkedIn for your job titles right now. Jobs show up here the moment we find them.'**
  String get firstJobsSubtitle;

  /// No description provided for @firstJobsDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your jobs are ready'**
  String get firstJobsDoneTitle;

  /// No description provided for @firstJobsDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We searched for every one of your job titles. New jobs keep coming in, day and night.'**
  String get firstJobsDoneSubtitle;

  /// No description provided for @firstJobsSlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Still searching'**
  String get firstJobsSlowTitle;

  /// No description provided for @firstJobsSlowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is taking longer than usual. Your jobs will show up in For you as we find them.'**
  String get firstJobsSlowSubtitle;

  /// No description provided for @firstJobsFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No jobs yet} =1{1 job found so far} other{{count} jobs found so far}}'**
  String firstJobsFound(int count);

  /// No description provided for @firstJobsFoundDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No jobs found yet} =1{1 job found} other{{count} jobs found}}'**
  String firstJobsFoundDone(int count);

  /// No description provided for @firstJobsFoundMore.
  ///
  /// In en, this message translates to:
  /// **'More than {count} jobs found'**
  String firstJobsFoundMore(int count);

  /// No description provided for @firstJobsNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No match yet. We keep looking, and new jobs will show up in For you.'**
  String get firstJobsNoneYet;

  /// No description provided for @firstJobsTipPosts.
  ///
  /// In en, this message translates to:
  /// **'Reading the newest hiring posts on LinkedIn…'**
  String get firstJobsTipPosts;

  /// No description provided for @firstJobsTipJobs.
  ///
  /// In en, this message translates to:
  /// **'Looking through LinkedIn Jobs too…'**
  String get firstJobsTipJobs;

  /// No description provided for @firstJobsTipMatch.
  ///
  /// In en, this message translates to:
  /// **'Matching every job to your skills and level…'**
  String get firstJobsTipMatch;

  /// No description provided for @firstJobsTipApply.
  ///
  /// In en, this message translates to:
  /// **'Finding how to apply: e-mail, WhatsApp, Easy Apply…'**
  String get firstJobsTipApply;

  /// No description provided for @firstJobsSeeNow.
  ///
  /// In en, this message translates to:
  /// **'See my jobs now'**
  String get firstJobsSeeNow;

  /// No description provided for @firstJobsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all my jobs'**
  String get firstJobsSeeAll;

  /// No description provided for @errorCode.
  ///
  /// In en, this message translates to:
  /// **'Error code: {code}'**
  String errorCode(String code);

  /// No description provided for @upgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock unlimited applications'**
  String get upgradeTitle;

  /// No description provided for @upgradeUsedUp.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your {limit} free applications. Upgrade to send your CV to every job that fits you, by hand and with auto apply.'**
  String upgradeUsedUp(int limit);

  /// No description provided for @upgradeIntro.
  ///
  /// In en, this message translates to:
  /// **'Send your CV to every job that fits you, by hand and with auto apply, with no limit.'**
  String get upgradeIntro;

  /// No description provided for @upgradePerkUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited applications by e-mail'**
  String get upgradePerkUnlimited;

  /// No description provided for @upgradePerkAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto apply day and night, as many jobs as fit you'**
  String get upgradePerkAuto;

  /// No description provided for @upgradePerkLetters.
  ///
  /// In en, this message translates to:
  /// **'A cover letter written for every job'**
  String get upgradePerkLetters;

  /// No description provided for @upgradeButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeButton;

  /// No description provided for @upgradeHow.
  ///
  /// In en, this message translates to:
  /// **'You\'ll chat with us on WhatsApp to subscribe. Your plan is turned on for {email} as soon as it\'s paid.'**
  String upgradeHow(String email);

  /// No description provided for @upgradeHowNoEmail.
  ///
  /// In en, this message translates to:
  /// **'You\'ll chat with us on WhatsApp to subscribe. Your plan is turned on for the Gmail you signed in with as soon as it\'s paid.'**
  String get upgradeHowNoEmail;

  /// No description provided for @lockedJobsBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your {limit} free applications. New jobs that fit you keep coming: upgrade to apply to all of them.'**
  String lockedJobsBody(int limit);

  /// No description provided for @autoApplyProblemFreeLimit.
  ///
  /// In en, this message translates to:
  /// **'Your free applications are used up. Upgrade to keep applying.'**
  String get autoApplyProblemFreeLimit;

  /// No description provided for @freeUsedTitle.
  ///
  /// In en, this message translates to:
  /// **'Free applications used up'**
  String get freeUsedTitle;

  /// No description provided for @freeLeft.
  ///
  /// In en, this message translates to:
  /// **'{left, plural, =0{No free applications left} =1{1 of {limit} free applications left} other{{left} of {limit} free applications left}}'**
  String freeLeft(int left, int limit);

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planTitle;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @planPro.
  ///
  /// In en, this message translates to:
  /// **'Pro · unlimited applications'**
  String get planPro;

  /// No description provided for @planProUntil.
  ///
  /// In en, this message translates to:
  /// **'Pro · until {date}'**
  String planProUntil(String date);

  /// No description provided for @proWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Pro!'**
  String get proWelcomeTitle;

  /// No description provided for @proWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your plan is on. Thank you for joining! Every job that fits you is open to you now.'**
  String get proWelcomeBody;

  /// No description provided for @proWelcomeButton.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get proWelcomeButton;

  /// No description provided for @gmailAccountOnly.
  ///
  /// In en, this message translates to:
  /// **'The Gmail you signed in with. It sends your applications and holds your plan.'**
  String get gmailAccountOnly;

  /// No description provided for @gmailErrorNotAccount.
  ///
  /// In en, this message translates to:
  /// **'Use the Gmail you signed in with: {email}'**
  String gmailErrorNotAccount(String email);

  /// No description provided for @autoApplyHomeOff.
  ///
  /// In en, this message translates to:
  /// **'Off · Sends your CV to new jobs that fit you'**
  String get autoApplyHomeOff;

  /// No description provided for @autoApplyHomeSetup.
  ///
  /// In en, this message translates to:
  /// **'Off · One-time Gmail setup, about 2 minutes'**
  String get autoApplyHomeSetup;

  /// No description provided for @autoApplyHomeUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to turn it on'**
  String get autoApplyHomeUpgrade;

  /// No description provided for @autoApplyTurningOn.
  ///
  /// In en, this message translates to:
  /// **'Turning on…'**
  String get autoApplyTurningOn;

  /// No description provided for @autoApplyTurningOff.
  ///
  /// In en, this message translates to:
  /// **'Turning off…'**
  String get autoApplyTurningOff;

  /// No description provided for @autoApplyHomeError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load auto apply. Tap to try again.'**
  String get autoApplyHomeError;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @autoApplyReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get autoApplyReadyTitle;

  /// No description provided for @autoApplyReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Auto apply is on. Autolinky now sends your CV to new jobs that fit you, from your Gmail:'**
  String get autoApplyReadyBody;

  /// No description provided for @autoApplyReadyMatch.
  ///
  /// In en, this message translates to:
  /// **'Jobs that fit you {percent}% or more'**
  String autoApplyReadyMatch(int percent);

  /// No description provided for @autoApplyReadyPace.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} CVs a day, at least {minutes} min apart'**
  String autoApplyReadyPace(int count, int minutes);

  /// No description provided for @autoApplyAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust settings'**
  String get autoApplyAdjust;

  /// No description provided for @autoApplyConnectGmail.
  ///
  /// In en, this message translates to:
  /// **'Connect your Gmail'**
  String get autoApplyConnectGmail;

  /// No description provided for @autoApplyConnectGmailBody.
  ///
  /// In en, this message translates to:
  /// **'Auto apply sends from it. 3 quick steps.'**
  String get autoApplyConnectGmailBody;

  /// No description provided for @setupDuration.
  ///
  /// In en, this message translates to:
  /// **'3 quick steps · about 2 minutes'**
  String get setupDuration;

  /// No description provided for @setupTwoStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on 2-Step Verification'**
  String get setupTwoStepTitle;

  /// No description provided for @setupTwoStepBody.
  ///
  /// In en, this message translates to:
  /// **'Your CV goes out from your own Gmail, so replies come straight to you. For that, Google needs 2-Step Verification on your account.'**
  String get setupTwoStepBody;

  /// No description provided for @setupTwoStepHow1.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below: your Google account opens'**
  String get setupTwoStepHow1;

  /// No description provided for @setupTwoStepHow2.
  ///
  /// In en, this message translates to:
  /// **'Turn on 2-Step Verification and follow Google\'s steps'**
  String get setupTwoStepHow2;

  /// No description provided for @setupTwoStepHow3.
  ///
  /// In en, this message translates to:
  /// **'Come back to Autolinky when it\'s on'**
  String get setupTwoStepHow3;

  /// No description provided for @setupAlreadyOn.
  ///
  /// In en, this message translates to:
  /// **'It\'s already on'**
  String get setupAlreadyOn;

  /// No description provided for @setupWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! If 2-Step Verification is on now, go on to the next step.'**
  String get setupWelcomeBack;

  /// No description provided for @setupNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get setupNext;

  /// No description provided for @setupOpenAgain.
  ///
  /// In en, this message translates to:
  /// **'Open it again'**
  String get setupOpenAgain;

  /// No description provided for @setupAppPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an app password'**
  String get setupAppPasswordTitle;

  /// No description provided for @setupAppPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'A 16-letter key Google makes for one app. Autolinky uses it only to send your applications, and never sees your real password.'**
  String get setupAppPasswordBody;

  /// No description provided for @setupAppPasswordHow1.
  ///
  /// In en, this message translates to:
  /// **'Type Autolinky as the app name, then tap Create'**
  String get setupAppPasswordHow1;

  /// No description provided for @setupAppPasswordHow2.
  ///
  /// In en, this message translates to:
  /// **'Copy the 16-letter password Google shows'**
  String get setupAppPasswordHow2;

  /// No description provided for @setupAppPasswordHow3.
  ///
  /// In en, this message translates to:
  /// **'Come back here: Autolinky pastes it for you'**
  String get setupAppPasswordHow3;

  /// No description provided for @setupAppPasswordTip.
  ///
  /// In en, this message translates to:
  /// **'No App passwords page? Turn on 2-Step Verification first (step 1).'**
  String get setupAppPasswordTip;

  /// No description provided for @setupHaveOne.
  ///
  /// In en, this message translates to:
  /// **'I already have one'**
  String get setupHaveOne;

  /// No description provided for @setupCopied.
  ///
  /// In en, this message translates to:
  /// **'I copied it'**
  String get setupCopied;

  /// No description provided for @setupPreviewAppName.
  ///
  /// In en, this message translates to:
  /// **'App name'**
  String get setupPreviewAppName;

  /// No description provided for @setupPreviewCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get setupPreviewCreate;

  /// No description provided for @setupPasteTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste your app password'**
  String get setupPasteTitle;

  /// No description provided for @setupPasteBody.
  ///
  /// In en, this message translates to:
  /// **'Gmail checks it before it\'s saved. Nothing is sent.'**
  String get setupPasteBody;

  /// No description provided for @setupPastedForYou.
  ///
  /// In en, this message translates to:
  /// **'Pasted the app password you copied.'**
  String get setupPastedForYou;

  /// No description provided for @setupLetters.
  ///
  /// In en, this message translates to:
  /// **'{count} of 16 letters'**
  String setupLetters(int count);

  /// No description provided for @setupMakeNew.
  ///
  /// In en, this message translates to:
  /// **'Make a new one'**
  String get setupMakeNew;

  /// No description provided for @setupConnectTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Connect and turn on'**
  String get setupConnectTurnOn;

  /// No description provided for @setupReconnect.
  ///
  /// In en, this message translates to:
  /// **'Gmail stopped accepting your app password. Make a new one: it takes 2 minutes.'**
  String get setupReconnect;

  /// No description provided for @filterNotApplied.
  ///
  /// In en, this message translates to:
  /// **'Not applied'**
  String get filterNotApplied;

  /// No description provided for @exploreAllAppliedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve applied to all of these'**
  String get exploreAllAppliedTitle;

  /// No description provided for @exploreAllAppliedBody.
  ///
  /// In en, this message translates to:
  /// **'Turn off \"Not applied\" to see them again.'**
  String get exploreAllAppliedBody;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @upgradePromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Do you have a promo code?'**
  String get upgradePromoTitle;

  /// No description provided for @upgradePromoBody.
  ///
  /// In en, this message translates to:
  /// **'If you have one, it goes with your request on WhatsApp and you get the discount.'**
  String get upgradePromoBody;

  /// No description provided for @upgradePromoYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, I have a code'**
  String get upgradePromoYes;

  /// No description provided for @upgradePromoNo.
  ///
  /// In en, this message translates to:
  /// **'No, continue to WhatsApp'**
  String get upgradePromoNo;

  /// No description provided for @upgradePromoEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter your promo code'**
  String get upgradePromoEnter;

  /// No description provided for @upgradePromoLabel.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get upgradePromoLabel;

  /// No description provided for @upgradePromoHelper.
  ///
  /// In en, this message translates to:
  /// **'Type it exactly as you got it.'**
  String get upgradePromoHelper;

  /// No description provided for @upgradePromoContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to WhatsApp'**
  String get upgradePromoContinue;

  /// No description provided for @upgradePromoSkip.
  ///
  /// In en, this message translates to:
  /// **'Continue without a code'**
  String get upgradePromoSkip;

  /// No description provided for @emailLinkConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish signing in'**
  String get emailLinkConfirmTitle;

  /// No description provided for @emailLinkConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm the email address that received this link. On another device, enter the same address you used to request it.'**
  String get emailLinkConfirmBody;

  /// No description provided for @emailLinkConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get emailLinkConfirm;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @signedInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Apple'**
  String get signedInWithApple;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your profile, CV, applications, mail connection and device registrations. Any subscription remains on record; contact support about billing.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type {email} to confirm deletion.'**
  String deleteAccountConfirm(String email);

  /// No description provided for @deleteAccountSending.
  ///
  /// In en, this message translates to:
  /// **'An email is still being processed. Account deletion is paused until its delivery status is resolved.'**
  String get deleteAccountSending;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
