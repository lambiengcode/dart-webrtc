import 'dart:js_util' as jsutil;

import 'package:dart_webrtc_plus/dart_webrtc_plus.dart';

class RTCRtpCapabilitiesWeb {
  static RTCRtpCapabilities fromJsObject(Object object) {
    return RTCRtpCapabilities.fromMap({
      'codecs': jsutil.dartify(jsutil.getProperty(object, 'codecs')),
      'headerExtensions':
          jsutil.dartify(jsutil.getProperty(object, 'headerExtensions')),
      'fecMechanisms':
          jsutil.dartify(jsutil.getProperty(object, 'fecMechanisms')) ?? []
    });
  }
}
