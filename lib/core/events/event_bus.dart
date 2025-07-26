import 'dart:async';

class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final StreamController<dynamic> _eventController = StreamController.broadcast();
  
  Stream<T> on<T>() => _eventController.stream.where((event) => event is T).cast<T>();
  
  void emit(dynamic event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }
  
  void dispose() {
    if (!_eventController.isClosed) {
      _eventController.close();
    }
  }
}