// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:camera_web/camera_web.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:sensors_plus/src/sensors_plus_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  CameraPlugin.registerWith(registrar);
  FirebaseCoreWeb.registerWith(registrar);
  WebSensorsPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
