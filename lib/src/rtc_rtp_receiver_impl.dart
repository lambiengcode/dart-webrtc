import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;
import 'package:webrtc_interface_plus/webrtc_interface_plus.dart';

import 'media_stream_track_impl.dart';
import 'rtc_rtp_parameters_impl.dart';

class RTCRtpReceiverWeb extends RTCRtpReceiver {
  RTCRtpReceiverWeb(this._jsRtpReceiver);

  /// private:
  final web.RTCRtpReceiver _jsRtpReceiver;

  @override
  Future<List<StatsReport>> getStats() async {
    var stats =
        await JSPromise(_jsRtpReceiver.callMethod('getStats'.toJS)).toDart;
    var report = <StatsReport>[];

    var statsDart = stats.dartify();

    if (statsDart is! Map) return report;

    statsDart.forEach((key, value) {
      report.add(
          StatsReport(value['id'], value['type'], value['timestamp'], value));
    });
    return report;
  }

  /// The WebRTC specification only defines RTCRtpParameters in terms of senders,
  /// but this API also applies them to receivers, similar to ORTC:
  /// http://ortc.org/wp-content/uploads/2016/03/ortc.html#rtcrtpparameters*.
  @override
  RTCRtpParameters get parameters {
    var parameters = _jsRtpReceiver.callMethod('getParameters'.toJS);
    return RTCRtpParametersWeb.fromJsObject(parameters.dartify()!);
  }

  @override
  MediaStreamTrack get track => MediaStreamTrackWeb(_jsRtpReceiver.track);

  @override
  String get receiverId => '${_jsRtpReceiver.hashCode}';

  web.RTCRtpReceiver get jsRtpReceiver => _jsRtpReceiver;
}
