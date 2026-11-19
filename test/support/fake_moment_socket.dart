import 'package:vera/core/realtime/moment_realtime_service.dart';

class FakeMomentSocket implements MomentSocket {
  final handlers = <String, void Function(dynamic)>{};
  final emissions = <(String, Map<String, dynamic>)>[];
  bool disposed = false;
  @override
  bool connected = false;
  @override
  void on(String event, void Function(dynamic) listener) =>
      handlers[event] = listener;
  @override
  void emit(String event, Map<String, dynamic> payload) =>
      emissions.add((event, payload));
  @override
  void connect() {}
  void receive(String event, [dynamic payload]) {
    if (event == 'connect') connected = true;
    handlers[event]?.call(payload);
  }

  @override
  void dispose() {
    connected = false;
    disposed = true;
  }
}
