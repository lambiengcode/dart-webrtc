import 'dart:async';
import 'dart:convert';

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dart_webrtc_plus/src/e2ee.worker/e2ee.logger.dart';
import 'package:dart_webrtc_plus/src/event.dart';

import 'package:web/web.dart' as web;
import 'package:webrtc_interface_plus/webrtc_interface_plus.dart';
import 'rtc_rtp_receiver_impl.dart';
import 'rtc_rtp_sender_impl.dart';
import 'rtc_transform_stream.dart';
import 'utils.dart';

class WorkerResponse {
  WorkerResponse(this.msgId, this.data);
  String msgId;
  dynamic data;
}

extension RtcRtpReceiverExt on web.RTCRtpReceiver {
  static Map<int, ReadableStream> readableStreams_ = {};
  static Map<int, WritableStream> writableStreams_ = {};

  ReadableStream? get readable {
    if (readableStreams_.containsKey(hashCode)) {
      return readableStreams_[hashCode]!;
    }
    return null;
  }

  WritableStream? get writable {
    if (writableStreams_.containsKey(hashCode)) {
      return writableStreams_[hashCode]!;
    }
    return null;
  }

  set readableStream(ReadableStream stream) {
    readableStreams_[hashCode] = stream;
  }

  set writableStream(WritableStream stream) {
    writableStreams_[hashCode] = stream;
  }

  void closeStreams() {
    readableStreams_.remove(hashCode);
    writableStreams_.remove(hashCode);
  }
}

extension RtcRtpSenderExt on web.RTCRtpSender {
  static Map<int, ReadableStream> readableStreams_ = {};
  static Map<int, WritableStream> writableStreams_ = {};

  ReadableStream? get readable {
    if (readableStreams_.containsKey(hashCode)) {
      return readableStreams_[hashCode]!;
    }
    return null;
  }

  WritableStream? get writable {
    if (writableStreams_.containsKey(hashCode)) {
      return writableStreams_[hashCode]!;
    }
    return null;
  }

  set readableStream(ReadableStream stream) {
    readableStreams_[hashCode] = stream;
  }

  set writableStream(WritableStream stream) {
    writableStreams_[hashCode] = stream;
  }

  void closeStreams() {
    readableStreams_.remove(hashCode);
    writableStreams_.remove(hashCode);
  }
}

class FrameCryptorImpl extends FrameCryptor {
  FrameCryptorImpl(
      this._factory, this.worker, this._participantId, this._trackId,
      {this.jsSender, this.jsReceiver, required this.keyProvider});
  web.Worker worker;
  bool _enabled = false;
  int _keyIndex = 0;
  final String _participantId;
  final String _trackId;
  final web.RTCRtpSender? jsSender;
  final web.RTCRtpReceiver? jsReceiver;
  final FrameCryptorFactoryImpl _factory;
  final KeyProviderImpl keyProvider;

  JSObject get workerJSO => worker as JSObject;

  @override
  Future<void> dispose() async {
    var msgId = randomString(12);
    workerJSO.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'dispose',
          'msgId': msgId,
          'trackId': _trackId,
        }.jsify());
    _factory.removeFrameCryptor(_trackId);
    return;
  }

  @override
  Future<bool> get enabled => Future(() => _enabled);

  @override
  Future<int> get keyIndex => Future(() => _keyIndex);

  @override
  String get participantId => _participantId;

  String get trackId => _trackId;

  @override
  Future<bool> setEnabled(bool enabled) async {
    var msgId = randomString(12);
    workerJSO.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'enable',
          'msgId': msgId,
          'trackId': _trackId,
          'enabled': enabled
        }.jsify());
    _enabled = enabled;
    return true;
  }

  @override
  Future<bool> setKeyIndex(int index) async {
    var msgId = randomString(12);
    workerJSO.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'setKeyIndex',
          'msgId': msgId,
          'trackId': _trackId,
          'index': index,
        }.jsify());
    _keyIndex = index;
    return true;
  }

  @override
  Future<void> updateCodec(String codec) async {
    var msgId = randomString(12);
    workerJSO.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'updateCodec',
          'msgId': msgId,
          'trackId': _trackId,
          'codec': codec,
        }.jsify());
  }
}

class KeyProviderImpl implements KeyProvider {
  KeyProviderImpl(this._id, this.worker, this.options, this.events);
  final String _id;
  final web.Worker worker;
  final KeyProviderOptions options;
  final Map<String, List<Uint8List>> _keys = {};
  final EventsEmitter<WorkerResponse> events;

  @override
  String get id => _id;

  JSObject get workerJSO => worker as JSObject;

  Future<void> init() async {
    var msgId = randomString(12);
    workerJSO.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'keyProviderInit',
          'msgId': msgId,
          'keyProviderId': id,
          'keyOptions': {
            'sharedKey': options.sharedKey,
            'ratchetSalt': base64Encode(options.ratchetSalt),
            'ratchetWindowSize': options.ratchetWindowSize,
            'failureTolerance': options.failureTolerance,
            if (options.uncryptedMagicBytes != null)
              'uncryptedMagicBytes': base64Encode(options.uncryptedMagicBytes!),
            'keyRingSize': options.keyRingSize,
            'discardFrameWhenCryptorNotReady':
                options.discardFrameWhenCryptorNotReady,
          },
        }.jsify());

    await events.waitFor<WorkerResponse>(
        filter: (event) {
          logger.fine('waiting for init on msg: $msgId');
          return event.msgId == msgId;
        },
        duration: Duration(seconds: 15));
  }

  @override
  Future<void> dispose() async {
    var msgId = randomString(12);
    workerJSO.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'keyProviderDispose',
          'msgId': msgId,
          'keyProviderId': id,
        }.jsify());

    await events.waitFor<WorkerResponse>(
        filter: (event) {
          logger.fine('waiting for dispose on msg: $msgId');
          return event.msgId == msgId;
        },
        duration: Duration(seconds: 15));

    _keys.clear();
  }

  @override
  Future<bool> setKey(
      {required String participantId,
      required int index,
      required Uint8List key}) async {
    var msgId = randomString(12);
    workerJSO.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'setKey',
          'msgId': msgId,
          'keyProviderId': id,
          'participantId': participantId,
          'keyIndex': index,
          'key': base64Encode(key),
        }.jsify());

    await events.waitFor<WorkerResponse>(
      filter: (event) {
        logger.fine('waiting for setKey on msg: $msgId');
        return event.msgId == msgId;
      },
      duration: Duration(minutes: 15),
    );

    _keys[participantId] ??= [];
    if (_keys[participantId]!.length <= index) {
      _keys[participantId]!.add(key);
    } else {
      _keys[participantId]![index] = key;
    }
    return true;
  }

  @override
  Future<Uint8List> ratchetKey(
      {required String participantId, required int index}) async {
    var msgId = randomString(12);
    workerJSO.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'ratchetKey',
          'msgId': msgId,
          'keyProviderId': id,
          'participantId': participantId,
          'keyIndex': index,
        }.jsify());

    var res = await events.waitFor<WorkerResponse>(
        filter: (event) {
          logger.fine('waiting for ratchetKey on msg: $msgId');
          return event.msgId == msgId;
        },
        duration: Duration(seconds: 15));

    return base64Decode(res.data['newKey']);
  }

  @override
  Future<Uint8List> exportKey(
      {required String participantId, required int index}) async {
    var msgId = randomString(12);
    workerJSO.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'exportKey',
          'msgId': msgId,
          'keyProviderId': id,
          'participantId': participantId,
          'keyIndex': index,
        }.jsify());

    var res = await events.waitFor<WorkerResponse>(
        filter: (event) {
          logger.fine('waiting for exportKey on msg: $msgId');
          return event.msgId == msgId;
        },
        duration: Duration(seconds: 15));

    return base64Decode(res.data['exportedKey']);
  }

  @override
  Future<Uint8List> exportSharedKey({int index = 0}) async {
    var msgId = randomString(12);
    workerJSO.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'exportSharedKey',
          'msgId': msgId,
          'keyProviderId': id,
          'keyIndex': index,
        }.jsify());

    var res = await events.waitFor<WorkerResponse>(
        filter: (event) {
          logger.fine('waiting for exportSharedKey on msg: $msgId');
          return event.msgId == msgId;
        },
        duration: Duration(seconds: 15));

    return base64Decode(res.data['exportedKey']);
  }

  @override
  Future<Uint8List> ratchetSharedKey({int index = 0}) async {
    var msgId = randomString(12);
    workerJSO.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'ratchetSharedKey',
          'msgId': msgId,
          'keyProviderId': id,
          'keyIndex': index,
        }.jsify());
    var res = await events.waitFor<WorkerResponse>(
        filter: (event) {
          logger.fine('waiting for ratchetSharedKey on msg: $msgId');
          return event.msgId == msgId;
        },
        duration: Duration(seconds: 15));

    return base64Decode(res.data['newKey']);
  }

  @override
  Future<void> setSharedKey({required Uint8List key, int index = 0}) async {
    var msgId = randomString(12);
    workerJSO.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'setSharedKey',
          'msgId': msgId,
          'keyProviderId': id,
          'keyIndex': index,
          'key': base64Encode(key),
        }.jsify());

    await events.waitFor<WorkerResponse>(
        filter: (event) {
          logger.fine('waiting for setSharedKey on msg: $msgId');
          return event.msgId == msgId;
        },
        duration: Duration(seconds: 15));
  }

  @override
  Future<void> setSifTrailer({required Uint8List trailer}) async {
    var msgId = randomString(12);
    workerJSO.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'setSifTrailer',
          'msgId': msgId,
          'keyProviderId': id,
          'sifTrailer': base64Encode(trailer),
        }.jsify());

    await events.waitFor<WorkerResponse>(
        filter: (event) {
          logger.fine('waiting for setSifTrailer on msg: $msgId');
          return event.msgId == msgId;
        },
        duration: Duration(seconds: 15));
  }
}

class FrameCryptorFactoryImpl implements FrameCryptorFactory {
  FrameCryptorFactoryImpl._internal() {
    worker = web.Worker('e2ee.worker.dart.js');
    worker.addEventListener(
        'message',
        (web.MessageEvent msg) {
          final data = msg.data.dartify() as Map;
          //print('master got $data');
          var type = data['type'];
          var msgId = data['msgId'];
          var msgType = data['msgType'];

          if (msgType == 'response') {
            events.emit(WorkerResponse(msgId, data));
          } else if (msgType == 'event') {
            if (type == 'cryptorState') {
              var trackId = data['trackId'];
              var participantId = data['participantId'];
              var frameCryptor = _frameCryptors.values.firstWhereOrNull(
                  (element) =>
                      (element as FrameCryptorImpl).trackId == trackId);
              var state = data['state'];
              var frameCryptorState = FrameCryptorState.FrameCryptorStateNew;
              switch (state) {
                case 'ok':
                  frameCryptorState = FrameCryptorState.FrameCryptorStateOk;
                  break;
                case 'decryptError':
                  frameCryptorState =
                      FrameCryptorState.FrameCryptorStateDecryptionFailed;
                  break;
                case 'encryptError':
                  frameCryptorState =
                      FrameCryptorState.FrameCryptorStateEncryptionFailed;
                  break;
                case 'missingKey':
                  frameCryptorState =
                      FrameCryptorState.FrameCryptorStateMissingKey;
                  break;
                case 'internalError':
                  frameCryptorState =
                      FrameCryptorState.FrameCryptorStateInternalError;
                  break;
                case 'keyRatcheted':
                  frameCryptorState =
                      FrameCryptorState.FrameCryptorStateKeyRatcheted;
                  break;
              }
              frameCryptor?.onFrameCryptorStateChanged
                  ?.call(participantId, frameCryptorState);
            }
          }
        }.toJS,
        false.toJS);
    worker.addEventListener(
        'error',
        (web.ErrorEvent err) {
          print('worker error: $err');
        }.toJS,
        false.toJS);
  }

  static final FrameCryptorFactoryImpl instance =
      FrameCryptorFactoryImpl._internal();

  late web.Worker worker;
  final Map<String, FrameCryptor> _frameCryptors = {};
  final EventsEmitter<WorkerResponse> events = EventsEmitter<WorkerResponse>();

  @override
  Future<KeyProvider> createDefaultKeyProvider(
      KeyProviderOptions options) async {
    var keyProvider =
        KeyProviderImpl(randomString(12), worker, options, events);
    await keyProvider.init();
    return keyProvider;
  }

  @override
  Future<FrameCryptor> createFrameCryptorForRtpReceiver(
      {required String participantId,
      required RTCRtpReceiver receiver,
      required Algorithm algorithm,
      required KeyProvider keyProvider}) {
    var jsReceiver = (receiver as RTCRtpReceiverWeb).jsRtpReceiver;

    var trackId = jsReceiver.hashCode.toString();
    var kind = jsReceiver.track.kind;

    if (globalContext.has('RTCRtpScriptTransform')) {
      print('support RTCRtpScriptTransform');
      var msgId = randomString(12);
      var options = {
        'msgType': 'decode',
        'msgId': msgId,
        'keyProviderId': (keyProvider as KeyProviderImpl).id,
        'kind': kind,
        'participantId': participantId,
        'trackId': trackId,
      };
      jsReceiver.setProperty(
          'transform'.toJS,
          RTCRtpScriptTransform(
            worker,
            options.jsify(),
          ).jsify());
    } else {
      var writable = jsReceiver.writable;
      var readable = jsReceiver.readable;
      var exist = true;
      if (writable == null || readable == null) {
        final streams = jsReceiver.callMethod('createEncodedStreams'.toJS)
            as EncodedStreams;
        readable = streams.readable;
        jsReceiver.readableStream = readable;
        writable = streams.writable;
        jsReceiver.writableStream = writable;
        exist = false;
      }
      var msgId = randomString(12);
      worker.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'decode',
          'msgId': msgId,
          'keyProviderId': (keyProvider as KeyProviderImpl).id,
          'kind': kind,
          'exist': exist,
          'participantId': participantId,
          'trackId': trackId,
          'readableStream': readable,
          'writableStream': writable
        }.jsify(),
        [readable, writable].jsify(),
      );
    }
    FrameCryptor cryptor = FrameCryptorImpl(
        this, worker, participantId, trackId,
        jsReceiver: jsReceiver, keyProvider: keyProvider);
    _frameCryptors[trackId] = cryptor;
    return Future.value(cryptor);
  }

  @override
  Future<FrameCryptor> createFrameCryptorForRtpSender(
      {required String participantId,
      required RTCRtpSender sender,
      required Algorithm algorithm,
      required KeyProvider keyProvider}) {
    var jsSender = (sender as RTCRtpSenderWeb).jsRtpSender;
    var trackId = jsSender.hashCode.toString();
    var kind = jsSender.track!.kind;

    if (globalContext.has('RTCRtpScriptTransform')) {
      print('support RTCRtpScriptTransform');
      var msgId = randomString(12);
      var options = {
        'msgType': 'encode',
        'msgId': msgId,
        'keyProviderId': (keyProvider as KeyProviderImpl).id,
        'kind': kind,
        'participantId': participantId,
        'trackId': trackId,
        'options': keyProvider.options.toJson(),
      };
      print('object: ${options['keyProviderId']}');
      jsSender.setProperty(
        'transform'.toJS,
        RTCRtpScriptTransform(worker, options.jsify()).jsify(),
      );
    } else {
      var writable = jsSender.writable;
      var readable = jsSender.readable;
      var exist = true;
      if (writable == null || readable == null) {
        final streams = jsSender.callMethod(
          'createEncodedStreams'.toJS,
        ) as EncodedStreams;
        readable = streams.readable;
        jsSender.readableStream = readable;
        writable = streams.writable;
        jsSender.writableStream = writable;
        exist = false;
      }
      var msgId = randomString(12);
      worker.callMethod(
        'postMessage'.toJS,
        {
          'msgType': 'encode',
          'msgId': msgId,
          'keyProviderId': (keyProvider as KeyProviderImpl).id,
          'kind': kind,
          'exist': exist,
          'participantId': participantId,
          'trackId': trackId,
          'options': keyProvider.options.toJson(),
          'readableStream': readable,
          'writableStream': writable
        }.jsify(),
        [readable, writable].jsify(),
      );
    }
    FrameCryptor cryptor = FrameCryptorImpl(
        this, worker, participantId, trackId,
        jsSender: jsSender, keyProvider: keyProvider);
    _frameCryptors[trackId] = cryptor;
    return Future.value(cryptor);
  }

  void removeFrameCryptor(String trackId) {
    _frameCryptors.remove(trackId);
  }
}
