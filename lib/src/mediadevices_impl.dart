import 'dart:async';

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;
import 'package:webrtc_interface_plus/webrtc_interface_plus.dart';

import 'media_stream_impl.dart';
import 'utils.dart';

@JS('navigator.mediaDevices.getUserMedia')
external JSPromise<web.MediaStream> _getUserMedia(JSAny? constraints);

@JS('navigator.mediaDevices.getDisplayMedia')
external JSPromise<web.MediaStream> _getDisplayMedia(JSAny? constraints);

class MediaDevicesWeb extends MediaDevices {
  @override
  Future<MediaStream> getUserMedia(
      Map<String, dynamic> mediaConstraints) async {
    try {
      try {
        if (!isMobile) {
          if (mediaConstraints['video'] is Map &&
              mediaConstraints['video']['facingMode'] != null) {
            mediaConstraints['video'].remove('facingMode');
          }
        }
        mediaConstraints.putIfAbsent('video', () => false);
        mediaConstraints.putIfAbsent('audio', () => false);
      } catch (e) {
        print(
            '[getUserMedia] failed to remove facingMode from mediaConstraints');
      }
      try {
        if (mediaConstraints['audio'] is Map<String, dynamic> &&
            Map.from(mediaConstraints['audio']).containsKey('optional') &&
            mediaConstraints['audio']['optional']
                is List<Map<String, dynamic>>) {
          List<Map<String, dynamic>> optionalValues =
              mediaConstraints['audio']['optional'];
          final audioMap = <String, dynamic>{};

          optionalValues.forEach((option) {
            option.forEach((key, value) {
              audioMap[key] = value;
            });
          });

          mediaConstraints['audio'].remove('optional');
          mediaConstraints['audio'].addAll(audioMap);
        }
      } catch (e, s) {
        print(
            '[getUserMedia] failed to translate optional audio constraints, $e, $s');
      }

      final mediaDevices = web.window.navigator.mediaDevices as JSObject;
      final hasGetUserMedia = mediaDevices.hasProperty('getUserMedia'.toJS);

      if (hasGetUserMedia.toDart) {
        var args = mediaConstraints.jsify();
        final jsStream = await _getUserMedia(args).toDart;
        return MediaStreamWeb(jsStream, 'local');
      } else {
        final streamCompleter = Completer<web.MediaStream>();

        web.window.navigator.getUserMedia(
            web.MediaStreamConstraints(
              audio: mediaConstraints['audio'],
              video: mediaConstraints['video'],
            ),
            (web.MediaStream stream) {
              streamCompleter.complete(stream);
            }.toJS,
            (JSAny err) {
              streamCompleter.completeError(err);
            }.toJS);

        final jsStream = await streamCompleter.future;
        return MediaStreamWeb(jsStream, 'local');
      }
    } catch (e) {
      throw 'Unable to getUserMedia: ${e.toString()}';
    }
  }

  @override
  Future<MediaStream> getDisplayMedia(
      Map<String, dynamic> mediaConstraints) async {
    try {
      final mediaDevices = web.window.navigator.mediaDevices as JSObject;
      final hasDisplayMedia = mediaDevices.hasProperty('getDisplayMedia'.toJS);

      if (hasDisplayMedia.toDart) {
        final args = mediaConstraints.jsify();
        final jsStream = await _getDisplayMedia(args).toDart;

        return MediaStreamWeb(jsStream, 'local');
      } else {
        final streamCompleter = Completer<web.MediaStream>();

        final video = {'mediaSource': 'screen'}.jsify()!;

        web.window.navigator.getUserMedia(
            web.MediaStreamConstraints(
                video: video, audio: mediaConstraints['audio'] ?? false),
            (web.MediaStream stream) {
              streamCompleter.complete(stream);
            }.toJS,
            (JSAny err) {
              streamCompleter.completeError(err);
            }.toJS);
        final jsStream = await streamCompleter.future;
        return MediaStreamWeb(jsStream, 'local');
      }
    } catch (e) {
      throw 'Unable to getDisplayMedia: ${e.toString()}';
    }
  }

  @override
  Future<List<MediaDeviceInfo>> enumerateDevices() async {
    final devices = await getSources();

    return devices.map((e) {
      var input = e;
      return MediaDeviceInfo(
        deviceId: input.deviceId,
        groupId: input.groupId,
        kind: input.kind,
        label: input.label,
      );
    }).toList();
  }

  @override
  Future<List<web.MediaDeviceInfo>> getSources() async {
    final devices =
        await web.window.navigator.mediaDevices.enumerateDevices().toDart;
    return devices.toDart;
  }

  @override
  MediaTrackSupportedConstraints getSupportedConstraints() {
    final mediaDevices = web.window.navigator.mediaDevices;

    var _mapConstraints = mediaDevices.getSupportedConstraints();

    return MediaTrackSupportedConstraints(
        aspectRatio: _mapConstraints.aspectRatio,
        autoGainControl: _mapConstraints.autoGainControl,
        brightness: _mapConstraints.brightness,
        channelCount: _mapConstraints.channelCount,
        colorTemperature: _mapConstraints.colorTemperature,
        contrast: _mapConstraints.contrast,
        deviceId: _mapConstraints.deviceId,
        echoCancellation: _mapConstraints.echoCancellation,
        exposureCompensation: _mapConstraints.exposureCompensation,
        exposureMode: _mapConstraints.exposureMode,
        exposureTime: _mapConstraints.exposureTime,
        facingMode: _mapConstraints.facingMode,
        focusDistance: _mapConstraints.focusDistance,
        focusMode: _mapConstraints.focusMode,
        frameRate: _mapConstraints.frameRate,
        groupId: _mapConstraints.groupId,
        height: _mapConstraints.height,
        iso: _mapConstraints.iso,
        latency: _mapConstraints.latency,
        noiseSuppression: _mapConstraints.noiseSuppression,
        pan: _mapConstraints.pan,
        pointsOfInterest: _mapConstraints.pointsOfInterest,
        resizeMode: _mapConstraints.resizeMode,
        saturation: _mapConstraints.saturation,
        sampleRate: _mapConstraints.sampleRate,
        sampleSize: _mapConstraints.sampleSize,
        sharpness: _mapConstraints.sharpness,
        tilt: _mapConstraints.tilt,
        torch: _mapConstraints.torch,
        whiteBalanceMode: _mapConstraints.whiteBalanceMode,
        width: _mapConstraints.width,
        zoom: _mapConstraints.zoom);
  }

  @override
  Future<MediaDeviceInfo> selectAudioOutput(
      [AudioOutputOptions? options]) async {
    try {
      final mediaDevices = web.window.navigator.mediaDevices as JSObject;

      final hasSelectAudioOutput =
          mediaDevices.hasProperty('selectAudioOutput'.toJS);

      if (hasSelectAudioOutput.toDart) {
        if (options != null) {
          final arg = options.jsify();
          final deviceInfo = await JSPromise<web.MediaDeviceInfo>(
                  mediaDevices.callMethod('selectAudioOutput'.toJS, arg))
              .toDart;
          return MediaDeviceInfo(
            kind: deviceInfo.kind,
            label: deviceInfo.label,
            deviceId: deviceInfo.deviceId,
            groupId: deviceInfo.groupId,
          );
        } else {
          final deviceInfo =
              await JSPromise<web.MediaDeviceInfo>(mediaDevices.callMethod(
            'selectAudioOutput'.toJS,
          )).toDart;
          return MediaDeviceInfo(
            kind: deviceInfo.kind,
            label: deviceInfo.label,
            deviceId: deviceInfo.deviceId,
            groupId: deviceInfo.groupId,
          );
        }
      } else {
        throw UnimplementedError('selectAudioOutput is missing');
      }
    } catch (e) {
      throw 'Unable to selectAudioOutput: ${e.toString()}, Please try to use MediaElement.setSinkId instead.';
    }
  }

  @override
  set ondevicechange(Function(dynamic event)? listener) {
    try {
      final mediaDevices = web.window.navigator.mediaDevices;

      mediaDevices.setProperty(
        'ondevicechange'.toJS,
        ((evt) => listener?.call(evt)).jsify(),
      );
    } catch (e) {
      throw 'Unable to set ondevicechange: ${e.toString()}';
    }
  }

  @override
  Function(dynamic event)? get ondevicechange {
    try {
      final mediaDevices = web.window.navigator.mediaDevices;

      mediaDevices.getProperty('ondevicechange'.toJS);
    } catch (e) {
      throw 'Unable to get ondevicechange: ${e.toString()}';
    }
    return null;
  }
}

extension _MediaTrackConstraints on web.MediaTrackSupportedConstraints {
  external bool get brightness;
  external bool get colorTemperature;
  external bool get contrast;
  external bool get exposureCompensation;
  external bool get exposureMode;
  external bool get exposureTime;
  external bool get focusDistance;
  external bool get focusMode;
  external bool get iso;
  external bool get pan;
  external bool get pointsOfInterest;
  external bool get saturation;
  external bool get sharpness;
  external bool get tilt;
  external bool get torch;
  external bool get whiteBalanceMode;
  external bool get zoom;
}
