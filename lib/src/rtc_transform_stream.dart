import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';

@JS('WritableStream')
extension type WritableStream._(JSObject _) implements JSObject {
  external void abort();
  external void close();
  external bool locked();
  external WritableStream clone();
}

// ReadableStream class with instance members
@JS('ReadableStream')
extension type ReadableStream._(JSObject _) implements JSObject {
  external void cancel();
  external bool locked();
  external ReadableStream pipeThrough(TransformStream transformStream);
  external void pipeTo(WritableStream writableStream);
  external ReadableStream clone();
}

// TransformStream class with generative constructor and instance members
@JS('TransformStream')
extension type TransformStream._(JSObject _) implements JSObject {
  external factory TransformStream(JSAny? arg);
  external ReadableStream get readable;
  external WritableStream get writable;
}

// Abstract class with instance methods
@JS()
extension type TransformStreamDefaultController._(JSObject _)
    implements JSObject {
  external void enqueue(JSAny? chunk);
  external void error(JSAny? error);
  external void terminate();
}

// EncodedStreams class with instance members
@JS()
extension type EncodedStreams._(JSObject _) implements JSObject {
  external ReadableStream get readable;
  external WritableStream get writable;
}

// RTCEncodedFrame class with instance members
@JS()
extension type RTCEncodedFrame._(JSObject _) implements JSObject {
  external int get timestamp;
  external JSArrayBuffer get data;
  external set data(JSArrayBuffer data);
  external RTCEncodedFrameMetadata getMetadata();
  external String? get type;
}

// RTCEncodedAudioFrame class with instance members
@JS()
extension type RTCEncodedAudioFrame._(JSObject _) implements JSObject {
  external int get timestamp;
  external JSArrayBuffer get data;
  external set data(JSArrayBuffer data);
  external int? get size;
  external RTCEncodedAudioFrameMetadata getMetadata();
}

// RTCEncodedVideoFrame class with instance members
@JS()
extension type RTCEncodedVideoFrame._(JSObject _) implements JSObject {
  external int get timestamp;
  external JSArrayBuffer get data;
  external set data(JSArrayBuffer data);
  external String get type;
  external RTCEncodedVideoFrameMetadata getMetadata();
}

// RTCEncodedFrameMetadata class with instance members
@JS()
extension type RTCEncodedFrameMetadata._(JSObject _) implements JSObject {
  external int get payloadType;
  external int get synchronizationSource;
}

// RTCEncodedAudioFrameMetadata class with instance members
@JS()
extension type RTCEncodedAudioFrameMetadata._(JSObject _) implements JSObject {
  external int get payloadType;
  external int get synchronizationSource;
}

// RTCEncodedVideoFrameMetadata class with instance members
@JS()
extension type RTCEncodedVideoFrameMetadata._(JSObject _) implements JSObject {
  external int get frameId;
  external int get width;
  external int get height;
  external int get payloadType;
  external int get synchronizationSource;
}

// RTCTransformEvent class with a factory constructor
@JS('RTCTransformEvent')
extension type RTCTransformEvent._(JSObject _) implements JSObject {
  external factory RTCTransformEvent();
}

// Extension for RTCTransformEvent
extension PropsRTCTransformEvent on RTCTransformEvent {
  RTCRtpScriptTransformer get transformer =>
      (this as JSObject).getProperty('transformer'.toJS);
}

// RTCRtpScriptTransformer class with a factory constructor
@JS()
extension type RTCRtpScriptTransformer._(JSObject _) implements JSObject {
  external factory RTCRtpScriptTransformer();
}

// Extension for RTCRtpScriptTransformer
extension PropsRTCRtpScriptTransformer on RTCRtpScriptTransformer {
  JSObject get jsObject => this as JSObject;
  ReadableStream get readable => jsObject.getProperty('readable'.toJS);
  WritableStream get writable => jsObject.getProperty('writable'.toJS);
  dynamic get options => jsObject.getProperty('options'.toJS);
  Future<int> generateKeyFrame([String? rid]) async {
    final val = await JSPromise(
            jsObject.callMethod('generateKeyFrame'.toJS, rid.jsify()))
        .toDart;

    return val.dartify() is int ? val.dartify() as int : 0;
  }

  Future<void> sendKeyFrameRequest() =>
      JSPromise(jsObject.callMethod('sendKeyFrameRequest'.toJS)).toDart;

  set handled(bool value) {
    jsObject.setProperty('handled'.toJS, value.toJS);
  }
}

// RTCRtpScriptTransform class with a factory constructor
@JS('RTCRtpScriptTransform')
extension type RTCRtpScriptTransform._(JSObject _) implements JSObject {
  external factory RTCRtpScriptTransform(Worker worker,
      [JSAny? options, JSArray<JSAny>? transfer]);
}
