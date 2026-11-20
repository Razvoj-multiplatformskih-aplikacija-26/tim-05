import 'package:api_client/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class BezbednoSkladisteTokena implements TokenStore {
  const BezbednoSkladisteTokena([this._skladiste = const FlutterSecureStorage()]);

  static const _kljuc = 'erasmusgo_sesija';

  final FlutterSecureStorage _skladiste;

  @override
  Future<String?> read() => _skladiste.read(key: _kljuc);

  @override
  Future<void> write(String token) => _skladiste.write(key: _kljuc, value: token);

  @override
  Future<void> clear() => _skladiste.delete(key: _kljuc);
}
