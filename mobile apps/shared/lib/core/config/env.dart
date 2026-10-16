// ignore_for_file: avoid_redundant_argument_values
import 'package:firebase_core/firebase_core.dart';

/// Public build settings. Use a separate define file for each registered platform.
/// Firebase Admin credentials and mail/AI secrets belong only on the server.
class Env {
  const Env({
    required this.apiBaseUrl,
    required this.firebaseApiKey,
    required this.firebaseAppId,
    this.firebaseProjectId = '',
    this.firebaseSenderId = '',
    this.firebaseAuthDomain = '',
    this.firebaseLinkHost = '',
    this.emailLinkContinueUrl = '',
    this.emailLinkDomain = '',
    this.googleWebClientId = '',
    this.googleIosClientId = '',
    this.emailSignIn = true,
    this.appleSignIn = false,
    this.termsUrl = '',
    this.privacyUrl = '',
  });

  factory Env.fromDefines() => const Env(
    apiBaseUrl: String.fromEnvironment('API_BASE_URL'),
    firebaseApiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    firebaseAppId: String.fromEnvironment('FIREBASE_APP_ID'),
    firebaseProjectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    firebaseSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    firebaseAuthDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    firebaseLinkHost: String.fromEnvironment('FIREBASE_LINK_HOST'),
    emailLinkContinueUrl: String.fromEnvironment('EMAIL_LINK_CONTINUE_URL'),
    emailLinkDomain: String.fromEnvironment('EMAIL_LINK_CUSTOM_DOMAIN'),
    googleWebClientId: String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    googleIosClientId: String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
    emailSignIn: bool.fromEnvironment('EMAIL_SIGN_IN', defaultValue: true),
    appleSignIn: bool.fromEnvironment('APPLE_SIGN_IN'),
    termsUrl: String.fromEnvironment('TERMS_URL'),
    privacyUrl: String.fromEnvironment('PRIVACY_URL'),
  );

  final String apiBaseUrl;
  final String firebaseApiKey;
  final String firebaseAppId;
  final String firebaseProjectId;
  final String firebaseSenderId;
  final String firebaseAuthDomain;
  final String firebaseLinkHost;
  final String emailLinkContinueUrl;

  /// Only a custom Hosting domain. Leave empty for Firebase's default domain.
  final String emailLinkDomain;
  final String googleWebClientId;
  final String googleIosClientId;
  final bool emailSignIn;
  final bool appleSignIn;
  final String termsUrl;
  final String privacyUrl;
  bool get googleSignInConfigured => googleWebClientId.isNotEmpty;

  FirebaseOptions get firebaseOptions => FirebaseOptions(
    apiKey: firebaseApiKey,
    appId: firebaseAppId,
    messagingSenderId: firebaseSenderId,
    projectId: firebaseProjectId,
    authDomain: firebaseAuthDomain,
    iosClientId: googleIosClientId.isEmpty ? null : googleIosClientId,
    iosBundleId: 'com.autolinky.ios',
  );

  List<String> get missing => [
    if (apiBaseUrl.isEmpty) 'API_BASE_URL',
    if (firebaseApiKey.isEmpty) 'FIREBASE_API_KEY',
    if (firebaseAppId.isEmpty) 'FIREBASE_APP_ID',
    if (firebaseProjectId.isEmpty) 'FIREBASE_PROJECT_ID',
    if (firebaseSenderId.isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
    if (emailSignIn && Uri.tryParse(emailLinkContinueUrl)?.scheme != 'https') 'EMAIL_LINK_CONTINUE_URL',
    if (emailLinkDomain.endsWith('.web.app') || emailLinkDomain.endsWith('.firebaseapp.com'))
      'EMAIL_LINK_CUSTOM_DOMAIN (custom domains only)',
  ];
}
