import 'dart:async';

import 'package:flutter/services.dart';

class FlutterBlueClassicObjc {
  static const MethodChannel _channel =
      const MethodChannel('com.bhtri.flutter_blue_classic_objc');

  Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<void> sendData(String printer, List<String> data) async {
    Map<String, String> map = new Map();
    map.putIfAbsent("printer", () => printer);
    map.putIfAbsent("length", () => data.length.toString());
    for (int idx = 0; idx < data.length; idx++) {
      map.putIfAbsent("data$idx", () => data[idx]);
    }

    try {
      await _channel.invokeMethod("sendData", map);
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future<void> list() async {
    await _channel.invokeMethod('list');
  }

  Future<Map<dynamic, dynamic>> getDriverList() async {
    var result = await _channel.invokeMethod("getDriverList");
    return Map<dynamic, dynamic>.from(result);
  }

  Future<void> dispose() async {
    await _channel.invokeMethod('unregis');
  }

  static FlutterBlueClassicObjc? _instance;
  FlutterBlueClassicObjc._internal() {
    // initialization and stuff
    _channel.invokeMethod('regis');
  }

  static FlutterBlueClassicObjc get instance {
    if (_instance == null) {
      _instance = FlutterBlueClassicObjc._internal();
    }
    return _instance!;
  }
}
