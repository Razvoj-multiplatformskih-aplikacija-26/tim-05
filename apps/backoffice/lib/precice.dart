import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class PrihvatiIntent extends Intent {
  const PrihvatiIntent();
}

class ListaCekanjaIntent extends Intent {
  const ListaCekanjaIntent();
}

class OdbijIntent extends Intent {
  const OdbijIntent();
}

class ZatvoriDetaljIntent extends Intent {
  const ZatvoriDetaljIntent();
}

class PregledPrecicaIntent extends Intent {
  const PregledPrecicaIntent();
}

class ZasticenaAkcija<T extends Intent> extends CallbackAction<T> {
  ZasticenaAkcija({required this.dozvoljena, required super.onInvoke});

  final bool Function() dozvoljena;

  @override
  bool isEnabled(T intent) => dozvoljena();
}

Map<ShortcutActivator, Intent> precicePrijava() => {
  const SingleActivator(LogicalKeyboardKey.keyP): const PrihvatiIntent(),
  const SingleActivator(LogicalKeyboardKey.keyL): const ListaCekanjaIntent(),
  const SingleActivator(LogicalKeyboardKey.keyO): const OdbijIntent(),
  const SingleActivator(LogicalKeyboardKey.escape): const ZatvoriDetaljIntent(),
  const CharacterActivator('?'): const PregledPrecicaIntent(),
};

final class OpisPrecice {
  const OpisPrecice(this.tasteri, this.opis);

  final String tasteri;
  final String opis;
}

const opisiPrecica = [
  OpisPrecice('↑  ↓', 'Kretanje kroz prijave'),
  OpisPrecice('Enter', 'Otvori prijavu pod kursorom'),
  OpisPrecice('Esc', 'Zatvori detalj'),
  OpisPrecice('P', 'Prihvati izabranu prijavu'),
  OpisPrecice('L', 'Stavi izabranu prijavu na listu čekanja'),
  OpisPrecice('O', 'Odbij izabranu prijavu, uz razlog'),
  OpisPrecice('Tab', 'Sledeće dugme ili polje'),
  OpisPrecice('?', 'Pregled prečica'),
];
