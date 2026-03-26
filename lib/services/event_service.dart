import 'dart:async';
import '../data/local/hive_service.dart';
import '../data/models/device_event.dart';

class EventService {
  static final _controller = StreamController<DeviceEvent>.broadcast();
  static Stream<DeviceEvent> get stream => _controller.stream;

  static Future<void> addEvent(DeviceEvent event) async {
    await HiveService.addEvent(event);
    _controller.add(event);
  }

  static List<DeviceEvent> getRecent({int limit = 50, DeviceEventType? type}) {
    return HiveService.getEvents(limit: limit, type: type);
  }

  static void dispose() => _controller.close();
}
