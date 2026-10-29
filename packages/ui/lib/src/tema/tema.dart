import 'package:flutter/material.dart';

import 'boje.dart';
import 'tipografija.dart';

export 'boje.dart';

abstract final class AppTema {
  static ThemeData svetla() {
    final shema = ColorScheme.fromSeed(
      seedColor: Boje.bordo,
      primary: Boje.bordo,
      onPrimary: Boje.bela,
      primaryContainer: Boje.bordoSvetla,
      onPrimaryContainer: Boje.naBordoSvetloj,
      secondary: Boje.zuta,
      onSecondary: Boje.naZutoj,
      surface: Boje.pozadina,
      onSurface: Boje.tekst,
      onSurfaceVariant: Boje.sporedniTekst,
      outlineVariant: Boje.ivica,
      error: Boje.greska,
    );
    final tekst = Tipografija.tema(shema);
    final zaobljeno = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final ivicaPolja = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Boje.ivica),
    );

    return ThemeData(
      colorScheme: shema,
      textTheme: tekst,
      fontFamily: 'packages/${Tipografija.paket}/${Tipografija.fontTeksta}',
      scaffoldBackgroundColor: Boje.pozadina,
      appBarTheme: AppBarTheme(
        backgroundColor: Boje.bordo,
        foregroundColor: Boje.bela,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: tekst.headlineSmall?.copyWith(color: Boje.bela),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
      ),
      cardTheme: CardThemeData(
        color: Boje.kartica,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Boje.ivica),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 52), shape: zaobljeno, textStyle: tekst.labelLarge),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: zaobljeno,
          side: const BorderSide(color: Boje.bordo, width: 1.5),
          textStyle: tekst.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48), textStyle: tekst.labelLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Boje.bela,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: ivicaPolja,
        enabledBorder: ivicaPolja,
        focusedBorder: ivicaPolja.copyWith(borderSide: const BorderSide(color: Boje.bordo, width: 2)),
        errorBorder: ivicaPolja.copyWith(borderSide: const BorderSide(color: Boje.greska)),
        focusedErrorBorder: ivicaPolja.copyWith(borderSide: const BorderSide(color: Boje.greska, width: 2)),
        labelStyle: tekst.bodyMedium?.copyWith(color: Boje.sporedniTekst),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Boje.bordo,
        foregroundColor: Boje.zuta,
        sizeConstraints: const BoxConstraints.tightFor(width: 64, height: 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Boje.bela,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Boje.tekst,
        contentTextStyle: tekst.bodyMedium?.copyWith(color: Boje.bela),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Boje.bela,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: tekst.headlineSmall,
        contentTextStyle: tekst.bodyMedium,
      ),
      dividerTheme: const DividerThemeData(color: Boje.ivica, space: 1),
    );
  }
}
