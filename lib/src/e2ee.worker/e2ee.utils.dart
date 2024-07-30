import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'crypto.dart' as crypto;

bool isE2EESupported() {
  return isInsertableStreamSupported() || isScriptTransformSupported();
}

bool isScriptTransformSupported() {
  return globalContext.has('RTCRtpScriptTransform');
}

JSObject? get rtpSenderPrototype {
  final rtpSender = globalContext.getProperty('RTCRtpSender'.toJS) as JSObject?;

  if (rtpSender == null) return null;

  final prototype = rtpSender.getProperty('prototype'.toJS) as JSObject?;

  return prototype;
}

bool isInsertableStreamSupported() {
  return globalContext.has('RTCRtpSender') &&
      rtpSenderPrototype?.getProperty('createEncodedStreams'.toJS) != null;
}

Future<web.CryptoKey> importKey(
    Uint8List keyBytes, String algorithm, String usage) {
  // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey
  return JSPromise<web.CryptoKey>(crypto.importKey(
    'raw',
    crypto.jsArrayBufferFrom(keyBytes),
    {'name': algorithm}.jsify(),
    false,
    usage == 'derive' ? ['deriveBits', 'deriveKey'] : ['encrypt', 'decrypt'],
  ) as JSFunction)
      .toDart;
}

Future<web.CryptoKey> createKeyMaterialFromString(
    Uint8List keyBytes, String algorithm, String usage) {
  // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey
  return JSPromise<web.CryptoKey>(crypto.importKey(
    'raw',
    crypto.jsArrayBufferFrom(keyBytes),
    {'name': 'PBKDF2'}.jsify(),
    false,
    ['deriveBits', 'deriveKey'],
  ) as JSFunction)
      .toDart;
}

dynamic getAlgoOptions(String algorithmName, Uint8List salt) {
  switch (algorithmName) {
    case 'HKDF':
      return {
        'name': 'HKDF',
        'salt': crypto.jsArrayBufferFrom(salt),
        'hash': 'SHA-256',
        'info': crypto.jsArrayBufferFrom(Uint8List(128)),
      };
    case 'PBKDF2':
      {
        return {
          'name': 'PBKDF2',
          'salt': crypto.jsArrayBufferFrom(salt),
          'hash': 'SHA-256',
          'iterations': 100000,
        };
      }
    default:
      throw Exception('algorithm $algorithmName is currently unsupported');
  }
}
