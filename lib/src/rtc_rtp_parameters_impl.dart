import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:dart_webrtc_plus/dart_webrtc_plus.dart';

class RTCRtpParametersWeb {
  static RTCRtpParameters fromJsObject(Object object) {
    final jsObject = object as JSObject;
    final hasTransactionId = jsObject.hasProperty('transactionId'.toJS);

    return RTCRtpParameters(
        transactionId: jsObject.getProperty('transactionId'.toJS),
        rtcp: hasTransactionId.toDart
            ? RTCRTCPParametersWeb.fromJsObject(
                jsObject.getProperty('rtcp'.toJS))
            : null,
        headerExtensions: headerExtensionsFromJsObject(object),
        encodings: encodingsFromJsObject(object),
        codecs: codecsFromJsObject(object));
  }

  static List<RTCHeaderExtension> headerExtensionsFromJsObject(Object object) {
    final jsObject = object as JSObject;

    var headerExtensions = jsObject.hasProperty('headerExtensions'.toJS).toDart
        ? jsObject.getProperty('headerExtensions'.toJS)
        : [];
    var list = <RTCHeaderExtension>[];

    if (headerExtensions is! List) return list;

    headerExtensions.forEach((e) {
      list.add(RTCHeaderExtensionWeb.fromJsObject(e));
    });
    return list;
  }

  static List<RTCRtpEncoding> encodingsFromJsObject(Object object) {
    final jsObject = object as JSObject;

    var encodings = jsObject.hasProperty('encodings'.toJS).toDart
        ? jsObject.getProperty('encodings'.toJS)
        : [];
    var list = <RTCRtpEncoding>[];

    if (encodings is! List) return list;

    encodings.forEach((e) {
      list.add(RTCRtpEncodingWeb.fromJsObject(e));
    });
    return list;
  }

  static List<RTCRTPCodec> codecsFromJsObject(Object object) {
    final jsObject = object as JSObject;

    var encodings = jsObject.hasProperty('codecs'.toJS).toDart
        ? jsObject.getProperty('codecs'.toJS)
        : [];
    var list = <RTCRTPCodec>[];

    if (encodings is! List) return list;

    encodings.forEach((e) {
      list.add(RTCRTPCodecWeb.fromJsObject(e));
    });
    return list;
  }
}

class RTCRTCPParametersWeb {
  static RTCRTCPParameters fromJsObject(Object object) {
    final jsObject = object as JSObject;

    return RTCRTCPParameters.fromMap({
      'cname': jsObject.getProperty('cname'.toJS),
      'reducedSize': jsObject.getProperty('reducedSize'.toJS)
    });
  }
}

class RTCHeaderExtensionWeb {
  static RTCHeaderExtension fromJsObject(Object object) {
    final jsObject = object as JSObject;

    return RTCHeaderExtension.fromMap({
      'uri': jsObject.getProperty('uri'.toJS),
      'id': jsObject.getProperty('id'.toJS),
      'encrypted': jsObject.getProperty('encrypted'.toJS)
    });
  }
}

class RTCRtpEncodingWeb {
  static RTCRtpEncoding fromJsObject(Object object) {
    final jsObject = object as JSObject;

    return RTCRtpEncoding.fromMap({
      'rid': jsObject.getProperty('rid'.toJS),
      'active': jsObject.getProperty('active'.toJS),
      'maxBitrate': jsObject.getProperty('maxBitrate'.toJS),
      'maxFramerate': jsObject.getProperty('maxFramerate'.toJS),
      'minBitrate': jsObject.getProperty('minBitrate'.toJS),
      'numTemporalLayers': jsObject.getProperty('numTemporalLayers'.toJS),
      'scaleResolutionDownBy':
          jsObject.getProperty('scaleResolutionDownBy'.toJS),
      'ssrc': jsObject.getProperty('ssrc'.toJS)
    });
  }
}

class RTCRTPCodecWeb {
  static RTCRTPCodec fromJsObject(Object object) {
    final jsObject = object as JSObject;

    return RTCRTPCodec.fromMap({
      'payloadType': jsObject.getProperty('payloadType'.toJS),
      'name': jsObject.getProperty('name'.toJS),
      'kind': jsObject.getProperty('kind'.toJS),
      'clockRate': jsObject.getProperty('clockRate'.toJS),
      'numChannels': jsObject.getProperty('numChannels'.toJS),
      'parameters': jsObject.getProperty('parameters'.toJS)
    });
  }
}
