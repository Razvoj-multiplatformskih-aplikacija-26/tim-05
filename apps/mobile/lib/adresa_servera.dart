import 'package:flutter/foundation.dart';


Uri adresaServera() {
  const zadata = String.fromEnvironment('SERVER_URL');
  if (zadata.isNotEmpty) return Uri.parse(zadata);
  final racunar = !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
  return Uri.parse('http://$racunar:8080');
}
