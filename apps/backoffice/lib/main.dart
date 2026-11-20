import 'package:api_client/api_client.dart';
import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'podaci/bezbedno_skladiste_tokena.dart';
import 'zavisnosti.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) BrowserContextMenu.disableContextMenu();
  usePathUrlStrategy();
  if (kDebugMode) Bloc.observer = KonzolniBlocObserver(debugPrint);
  runApp(
    BackofficeAplikacija(
      zavisnosti: ZavisnostiBackoffice.server(
        adresa: Uri.parse(const String.fromEnvironment('SERVER_URL', defaultValue: 'http://localhost:8080')),
        tokeni: kIsWeb ? MemoryTokenStore() : const BezbednoSkladisteTokena(),
      ),
    ),
  );
}
