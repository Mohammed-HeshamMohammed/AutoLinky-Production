import 'package:autolinky/app/bootstrap.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() {
  usePathUrlStrategy();
  return bootstrap();
}
