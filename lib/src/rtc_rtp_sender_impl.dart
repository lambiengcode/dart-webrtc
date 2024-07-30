import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:dart_webrtc_plus/src/media_stream_impl.dart';
import 'package:web/web.dart' as web;
import 'package:webrtc_interface_plus/webrtc_interface_plus.dart';

import 'media_stream_track_impl.dart';
import 'rtc_dtmf_sender_impl.dart';
import 'rtc_rtp_parameters_impl.dart';

class RTCRtpSenderWeb extends RTCRtpSender {
  RTCRtpSenderWeb(this._jsRtpSender, this._ownsTrack);

  factory RTCRtpSenderWeb.fromJsSender(web.RTCRtpSender jsRtpSender) {
    return RTCRtpSenderWeb(jsRtpSender, jsRtpSender.track != null);
  }

  final web.RTCRtpSender _jsRtpSender;
  bool _ownsTrack = false;

  @override
  Future<void> replaceTrack(MediaStreamTrack? track) async {
    try {
      if (track != null) {
        var nativeTrack = track as MediaStreamTrackWeb;
        _jsRtpSender.callMethod('replaceTrack'.toJS, nativeTrack.jsTrack);
      } else {
        _jsRtpSender.callMethod(
          'replaceTrack'.toJS,
        );
      }
    } on Exception catch (e) {
      throw 'Unable to RTCRtpSender::replaceTrack: ${e.toString()}';
    }
  }

  @override
  Future<void> setTrack(MediaStreamTrack? track,
      {bool takeOwnership = true}) async {
    try {
      if (track != null) {
        var nativeTrack = track as MediaStreamTrackWeb;
        _jsRtpSender.callMethod('setTrack'.toJS, nativeTrack.jsTrack);
      } else {
        _jsRtpSender.callMethod('setTrack'.toJS);
      }
    } on Exception catch (e) {
      throw 'Unable to RTCRtpSender::setTrack: ${e.toString()}';
    }
  }

  @override
  Future<void> setStreams(List<MediaStream> streams) async {
    try {
      final nativeStreams = streams.cast<MediaStreamWeb>();
      _jsRtpSender.callMethod('setStreams'.toJS,
          nativeStreams.map((e) => e.jsStream).toList().jsify());
    } on Exception catch (e) {
      throw 'Unable to RTCRtpSender::setStreams: ${e.toString()}';
    }
  }

  @override
  RTCRtpParameters get parameters {
    var parameters = _jsRtpSender.callMethod('getParameters'.toJS);
    return RTCRtpParametersWeb.fromJsObject(parameters.dartify()!);
  }

  @override
  Future<bool> setParameters(RTCRtpParameters parameters) async {
    try {
      var oldParameters =
          _jsRtpSender.callMethod('getParameters'.toJS) as JSObject?;
      oldParameters?.setProperty(
        'encodings'.toJS,
        (parameters.encodings?.map((e) => e.toMap()).toList() ?? []).jsify(),
      );
      await JSPromise(
              _jsRtpSender.callMethod('setParameters'.toJS, oldParameters))
          .toDart;
      return Future<bool>.value(true);
    } on Exception catch (e) {
      throw 'Unable to RTCRtpSender::setParameters: ${e.toString()}';
    }
  }

  @override
  Future<List<StatsReport>> getStats() async {
    var stats =
        await JSPromise(_jsRtpSender.callMethod('getStats'.toJS)).toDart;
    var report = <StatsReport>[];
    var statsDart = stats.dartify();

    if (statsDart is! Map) return report;

    statsDart.forEach((key, value) {
      report.add(
          StatsReport(value['id'], value['type'], value['timestamp'], value));
    });
    return report;
  }

  @override
  MediaStreamTrack? get track {
    if (null != _jsRtpSender.track) {
      return MediaStreamTrackWeb(_jsRtpSender.track!);
    }
    return null;
  }

  @override
  String get senderId => '${_jsRtpSender.hashCode}';

  @override
  bool get ownsTrack => _ownsTrack;

  @override
  RTCDTMFSender get dtmfSender =>
      RTCDTMFSenderWeb(_jsRtpSender.getProperty('dtmf'.toJS));

  @override
  Future<void> dispose() async {}

  web.RTCRtpSender get jsRtpSender => _jsRtpSender;
}
