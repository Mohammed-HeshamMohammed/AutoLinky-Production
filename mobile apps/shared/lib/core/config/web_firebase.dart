import 'package:dio/dio.dart';

/// Public browser configuration. Native clients use their embedded registration.
class WebFirebaseSettings {
  const WebFirebaseSettings({
    required this.apiKey,
    required this.appId,
    required this.projectId,
    required this.senderId,
    required this.authDomain,
    required this.storageBucket,
    this.measurementId = '',
  });

  final String apiKey;
  final String appId;
  final String projectId;
  final String senderId;
  final String authDomain;
  final String storageBucket;
  final String measurementId;

  factory WebFirebaseSettings.fromResponse(Object? response) {
    if (response is! Map<String, dynamic> || response['firebase'] is! Map<String, dynamic>) {
      throw const FormatException('Web Firebase configuration is unavailable');
    }
    final fields = response['firebase'] as Map<String, dynamic>;
    String required(String key) {
      final value = fields[key];
      if (value is! String || value.isEmpty || value.length > 512 || RegExp(r'''[\s<>"']''').hasMatch(value)) {
        throw const FormatException('Web Firebase configuration is incomplete');
      }
      return value;
    }

    final settings = WebFirebaseSettings(
      apiKey: required('apiKey'),
      appId: required('appId'),
      projectId: required('projectId'),
      senderId: required('messagingSenderId'),
      authDomain: required('authDomain'),
      storageBucket: required('storageBucket'),
      measurementId: fields['measurementId'] is String ? fields['measurementId'] as String : '',
    );
    final domain = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$');
    if (!settings.appId.startsWith('1:${settings.senderId}:web:') ||
        !RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(settings.projectId) ||
        !RegExp(r'^\d+$').hasMatch(settings.senderId) ||
        !domain.hasMatch(settings.authDomain) ||
        !domain.hasMatch(settings.storageBucket) ||
        (settings.measurementId.isNotEmpty && !RegExp(r'^G-[A-Z0-9]+$').hasMatch(settings.measurementId))) {
      throw const FormatException('Invalid web Firebase configuration');
    }
    return settings;
  }
}

Future<WebFirebaseSettings> loadWebFirebase(Uri page, {Dio? client}) async {
  final transport = client ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 8)));
  try {
    final response = await transport.getUri<Object?>(
      page.resolve('/api/config'),
      options: Options(
        responseType: ResponseType.json,
        followRedirects: false,
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'Cache-Control': 'no-cache'},
      ),
    );
    if (response.statusCode != 200) throw const FormatException('Web Firebase configuration is unavailable');
    return WebFirebaseSettings.fromResponse(response.data);
  } finally {
    if (client == null) transport.close(force: true);
  }
}
