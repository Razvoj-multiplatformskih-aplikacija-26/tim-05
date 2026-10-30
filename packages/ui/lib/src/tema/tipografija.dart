import 'package:flutter/material.dart';

abstract final class Tipografija {
  static const fontNaslova = 'Outfit';
  static const fontTeksta = 'Manrope';
  static const paket = 'ui';

  static TextTheme tema(ColorScheme shema) {
    const naslov = TextStyle(fontFamily: fontNaslova, package: paket, fontWeight: FontWeight.w600, height: 1.15);
    const obican = TextStyle(fontFamily: fontTeksta, package: paket, fontWeight: FontWeight.w400, height: 1.45);
    const oznaka = TextStyle(fontFamily: fontTeksta, package: paket, fontWeight: FontWeight.w700, height: 1.2);

    return TextTheme(
      displayLarge: naslov.copyWith(fontSize: 48),
      displayMedium: naslov.copyWith(fontSize: 40),
      displaySmall: naslov.copyWith(fontSize: 34),
      headlineLarge: naslov.copyWith(fontSize: 28),
      headlineMedium: naslov.copyWith(fontSize: 25),
      headlineSmall: naslov.copyWith(fontSize: 21),
      titleLarge: naslov.copyWith(fontSize: 19),
      titleMedium: oznaka.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: oznaka.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: obican.copyWith(fontSize: 16),
      bodyMedium: obican.copyWith(fontSize: 14),
      bodySmall: obican.copyWith(fontSize: 12.5),
      labelLarge: oznaka.copyWith(fontSize: 15),
      labelMedium: oznaka.copyWith(fontSize: 12),
      labelSmall: oznaka.copyWith(fontSize: 11, letterSpacing: 0.4),
    ).apply(bodyColor: shema.onSurface, displayColor: shema.onSurface);
  }
}
