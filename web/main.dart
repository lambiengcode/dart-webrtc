import 'dart:html' as html;

import 'package:dart_webrtc/dart_webrtc.dart';

/*
import 'test_media_devices.dart' as media_devices_tests;
import 'test_media_stream.dart' as media_stream_tests;
import 'test_media_stream_track.dart' as media_stream_track_tests;
import 'test_peerconnection.dart' as peerconnection_tests;
import 'test_video_element.dart' as video_elelment_tests;
*/
void main() {
  /*
  video_elelment_tests.testFunctions.forEach((Function func) => func());
  media_devices_tests.testFunctions.forEach((Function func) => func());
  media_stream_tests.testFunctions.forEach((Function func) => func());
  media_stream_track_tests.testFunctions.forEach((Function func) => func());
  peerconnection_tests.testFunctions.forEach((Function func) => func());
  */
  loopBackTest();
}

void loopBackTest() async {
  var local = html.document.querySelector('#local');
  var localVideo = RTCVideoElement();
  local!.append(localVideo.htmlElement);

  var remote = html.document.querySelector('#remote');
  var remotelVideo = RTCVideoElement();
  remote!.append(remotelVideo.htmlElement);

  var acaps = await getRtpSenderCapabilities('audio');
  print('sender audio capabilities: ${acaps.toMap()}');

  var vcaps = await getRtpSenderCapabilities('video');
  print('sender video capabilities: ${vcaps.toMap()}');
  /*
  capabilities = await getRtpReceiverCapabilities('audio');
  print('receiver audio capabilities: ${capabilities.toMap()}');

  capabilities = await getRtpReceiverCapabilities('video');
  print('receiver video capabilities: ${capabilities.toMap()}');
  */
  var pc2 = await createPeerConnection({});
  pc2.onTrack = (event) async {
    if (event.track.kind == 'video') {
      remotelVideo.srcObject = event.streams[0];
    }
  };
  pc2.onConnectionState = (state) {
    print('connectionState $state');
  };

  pc2.onIceConnectionState = (state) {
    print('iceConnectionState $state');
  };

  var pc1 = await createPeerConnection({});

  pc1.onIceCandidate = (candidate) => pc2.addCandidate(candidate);
  pc2.onIceCandidate = (candidate) => pc1.addCandidate(candidate);

  var stream =
      await navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});
  /*.getUserMedia(MediaStreamConstraints(audio: true, video: true))*/
  print('getDisplayMedia: stream.id => ${stream.id}');

  navigator.mediaDevices.ondevicechange = (event) async {
    var list = await navigator.mediaDevices.enumerateDevices();
    print('ondevicechange: ');
    list.where((element) => element.kind == 'audiooutput').forEach((e) {
      print('${e.runtimeType}: ${e.label}, type => ${e.kind}');
    });
  };

  var list = await navigator.mediaDevices.enumerateDevices();
  list.forEach((e) {
    print('${e.runtimeType}: ${e.label}, type => ${e.kind}');
  });
  var outputList = list.where((element) => element.kind == 'audiooutput');
  if (outputList.isNotEmpty) {
    var sinkId = outputList.last.deviceId;
    try {
      await navigator.mediaDevices
          .selectAudioOutput(AudioOutputOptions(deviceId: sinkId));
    } catch (e) {
      print('selectAudioOutput error: ${e.toString()}');
      await localVideo.setSinkId(sinkId);
    }
  }

  stream.getTracks().forEach((track) async {
    await pc1.addTrack(track, stream);
  });

  var transceivers = await pc1.getTransceivers();
  transceivers.forEach((transceiver) {
    print('transceiver: ${transceiver.sender.track!.kind!}');
    if (transceiver.sender.track!.kind! == 'video') {
      transceiver.setCodecPreferences([
        RTCRtpCodecCapability(
          mimeType: 'video/AV1',
          clockRate: 90000,
        )
      ]);
    } else if (transceiver.sender.track!.kind! == 'audio') {
      transceiver.setCodecPreferences([
        RTCRtpCodecCapability(
          mimeType: 'audio/PCMA',
          clockRate: 8000,
          channels: 1,
        )
      ]);
    }
  });

  var offer = await pc1.createOffer();

  await pc2.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly));
  await pc2.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly));

  await pc1.setLocalDescription(offer);
  await pc2.setRemoteDescription(offer);
  var answer = await pc2.createAnswer({});
  await pc2.setLocalDescription(answer);

  await pc1.setRemoteDescription(answer);

  localVideo.muted = true;
  localVideo.srcObject = stream;
}
