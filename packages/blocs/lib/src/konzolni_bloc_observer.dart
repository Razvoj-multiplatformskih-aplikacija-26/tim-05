import 'package:bloc/bloc.dart';

final class KonzolniBlocObserver extends BlocObserver {
  const KonzolniBlocObserver(this.ispisi);

  final void Function(String red) ispisi;

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    ispisi('${bloc.runtimeType} - napravljen');
  }

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    super.onTransition(bloc, transition);
    ispisi('${bloc.runtimeType} - ${transition.event.runtimeType} -> ${transition.nextState}');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    ispisi('${bloc.runtimeType} - greska: $error');
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    ispisi('${bloc.runtimeType} - zatvoren');
  }
}
