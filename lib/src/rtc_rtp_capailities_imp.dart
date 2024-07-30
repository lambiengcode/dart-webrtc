import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:dart_webrtc_plus/dart_webrtc_plus.dart';

class RTCRtpCapabilitiesWeb {
  static RTCRtpCapabilities fromJsObject(Object object) {
    final jsObject = object.jsify() as JSObject;

    return RTCRtpCapabilities.fromMap({
      'codecs': jsObject.getProperty('codecs'.toJS).dartify(),
      'headerExtensions':
          jsObject.getProperty('headerExtensions'.toJS).dartify(),
      'fecMechanisms':
          jsObject.getProperty('fecMechanisms'.toJS).dartify() ?? []
    });
  }
}
