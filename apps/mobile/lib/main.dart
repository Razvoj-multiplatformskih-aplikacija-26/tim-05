import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() {
  // Svi ekrani počinju bordo zaglavljem, pa su sat i baterija na vrhu telefona beli.
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const ErasmusAplikacija());
}
