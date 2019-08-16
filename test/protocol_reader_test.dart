import 'dart:typed_data';

import 'package:bullet_force_hax/src/protocol_reader/ProtocolReader.dart';
import 'package:bullet_force_hax/src/protocol_reader/types/CustomData.dart';
import 'package:bullet_force_hax/src/protocol_reader/types/SizedFloat.dart';
import 'package:bullet_force_hax/src/protocol_reader/types/SizedInt.dart';
import 'package:bullet_force_hax/src/protocol_reader/types/packets.dart';
import 'package:test/test.dart';

void main() {
  group('reading protocol types', () {
    test('can read null', () {
      var reader = ProtocolReader(Uint8List.fromList([0x2a]));
      var t = reader.readValue();

      expect(t, null);
    });

    // TODO: Dictionary test
    // TODO: EventData test
    // TODO: OperationResponse test
    // TODO: OperationRequest test
    // TODO: Array test

    test('can read bool', () {
      var t1 = ProtocolReader(Uint8List.fromList([0x6f, 0x00])).readValue();
      var t2 = ProtocolReader(Uint8List.fromList([0x6f, 0x01])).readValue();

      expect(t1.runtimeType, bool);
      expect(t1, false);
      expect(t2.runtimeType, bool);
      expect(t2, true);

    });

    test('can read u8', () {
      var reader = ProtocolReader(Uint8List.fromList([0x62, 0x90]));
      var t = reader.readValue();

      expect(t.runtimeType, SizedInt);
      if (t is SizedInt) {
        expect(t.value, 0x90);
        expect(t.size, 1);
      }
    });

    test('can read s16', () {
      var reader = ProtocolReader(Uint8List.fromList([0x6b, 0xFA, 0xC7]));
      var t = reader.readValue();

      expect(t.runtimeType, SizedInt);
      if (t is SizedInt) {
        expect(t.value, -1337);
        expect(t.size, 2);
      }
    });

    test('can read s32', () {
      var reader = ProtocolReader(Uint8List.fromList([0x69, 0xDE, 0xAD, 0xBE, 0xEF]));
      var t = reader.readValue();

      expect(t.runtimeType, SizedInt);
      if (t is SizedInt) {
        expect(t.value, -559038737);
        expect(t.size, 4);
      }
    });

    test('can read s64', () {
      var reader = ProtocolReader(Uint8List.fromList([0x6c, 0xCA, 0x11, 0xAB, 0x1E, 0xCA, 0xFE, 0xBA, 0xBE]));
      var t = reader.readValue();

      expect(t.runtimeType, SizedInt);
      if (t is SizedInt) {
        expect(t.value, -3886136854700967234);
        expect(t.size, 8);
      }
    });

    test('can read f32', () {
      var reader = ProtocolReader(Uint8List.fromList([0x66, 0x42, 0x28, 0x00, 0x00]));
      var t = reader.readValue();

      expect(t.runtimeType, SizedFloat);
      if (t is SizedFloat) {
        expect(t.value, 42);
        expect(t.size, 4);
      }
    });

    test('can read f64', () {
      var reader = ProtocolReader(Uint8List.fromList([0x64, 0x40, 0x2a, 0xbd, 0x70, 0xa3, 0xd7, 0x0a, 0x3d]));
      var t = reader.readValue();

      expect(t.runtimeType, SizedFloat);
      if (t is SizedFloat) {
        expect(t.value, 13.37);
        expect(t.size, 8);
      }
    });

    // TODO: unicode test
    test('can read strings', () {
      var reader = ProtocolReader(Uint8List.fromList([0x73, 0x00, 0x03, 0x61, 0x62, 0x63]));
      var t = reader.readValue();

      expect(t.runtimeType, String);
      expect(t, "abc");
    });

    test('can read byte[]', () {
      var reader = ProtocolReader(Uint8List.fromList([120, 0, 0, 0, 4, 0xDE, 0xAD, 0xBE, 0xEF]));
      var t = reader.readValue();

      expect(t is Uint8List, isTrue);
      if (t is Uint8List) {
        expect(t.length, 4);
        expect(t, [0xDE, 0xAD, 0xBE, 0xEF]);
      }
    });

    test('can read int[]', () {
      var reader = ProtocolReader(Uint8List.fromList([110, 0, 0, 0, 2, 0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE, 0xBA, 0xBE]));
      var t = reader.readValue();

      expect(t is Int32List, isTrue);
      if (t is Int32List) {
        expect(t.length, 2);
        expect(t, [-559038737, -889275714]);
      }
    });

    test('can read string[]', () {
      var reader = ProtocolReader(Uint8List.fromList([97, 0, 2, 0, 3, 0x61, 0x62, 0x63, 0, 0]));
      var t = reader.readValue();

      expect(t is List<String>, isTrue);
      if (t is List<String>) {
        expect(t.length, 2);
        expect(t[0], 'abc');
        expect(t[1], '');
      }
    });

    test('can read ObjectArray', () {
      var reader = ProtocolReader(Uint8List.fromList([122, 0, 3, 115, 0, 3, 0x61, 0x62, 0x63, 42, 107, 0x01, 0x23]));
      var t = reader.readValue();

      expect(t is List<Object>, isTrue);
      if (t is List<Object>) {
        expect(t.length, 3);
        expect(t[0], 'abc');
        expect(t[1], null);

        var elem2 = t[2];
        expect(elem2 is SizedInt, isTrue);
        if (elem2 is SizedInt) {
          expect(elem2.size, 2);
          expect(elem2.value, 0x123);
        }
      }
    });

    test('can read hashtable', () {
      var reader = ProtocolReader(Uint8List.fromList([0x68, 0x00, 0x02, 98, 0xFF, 42, 115, 0x00, 0x03, 0x61, 0x62, 0x63, 111, 0x01]));
      var t = reader.readValue();

      expect(t is Map<Object, Object>, isTrue); // cannot use runtimeType?
      if (t is Map<Object, Object>) {
        expect(t.length, 2);
        expect(t[SizedInt.byte(0xFF)], null);
        expect(t['abc'], true);
      }
    });

    test('can read custom data', () {
      var reader = ProtocolReader(Uint8List.fromList([99, 42, 0, 4, 0xDE, 0xAD, 0xBE, 0xEF]));
      var t = reader.readValue();

      expect(t.runtimeType, CustomData);
      if (t is CustomData) {
        expect(t.typeCode, 42);
        expect(t.data.length, 4);
        expect(t.data, [0xDE, 0xAD, 0xBE, 0xEF]);
      }
    });
  });

  group('reading packets', () {
    test('packet 0x02: OperationRequest', () {
      var reader = ProtocolReader(Uint8List.fromList([0xf3, 0x02, 0xe5, 0x00, 0x00]));
      var t = reader.readPacket();

      expect(t is OperationRequest, isTrue);
      expect(t.code, 229);  // JoinLobby
      expect(t.params.length, 0);
    });
    test('packet 0x03: OperationResponse', () {
      var reader = ProtocolReader(Uint8List.fromList([0xf3, 0x03, 0xe5, 0x00, 0x00, 0x2a, 0x00, 0x00]));
      var t = reader.readPacket();

      expect(t is OperationResponse, isTrue);
      if (t is OperationResponse) {
        expect(t.code, 229);  // JoinLobby
        expect(t.debugMessage, null);
        expect(t.returnCode, 0);
        expect(t.params.length, 0);
      }
    });
    test('packet 0x04: Event', () {
      var reader = ProtocolReader(Uint8List.fromList([0xf3, 0x04, 0xe2, 0x00, 0x03, 0xe3, 0x69, 0x00, 0x00, 0x00, 0xdf, 0xe5, 0x69, 0x00, 0x00, 0x01, 0x6c, 0xe4, 0x69, 0x00, 0x00, 0x00, 0x46]));
      var t = reader.readPacket();

      expect(t is Event, isTrue);
      expect(t.code, 226);  // AppStats
      expect(t.params.length, 3);
      expect((t.params[0xE3] as SizedInt).value, 223);  // MASTER_PEER_COUNT
      expect((t.params[0xE5] as SizedInt).value, 364);  // PEER_COUNT
      expect((t.params[0xE4] as SizedInt).value, 70);   // GAME_COUNT
    });
    test('packet 0x06: InternalOperationRequest', () {
      var reader = ProtocolReader(Uint8List.fromList([0xf3, 0x06, 0x01, 0x00, 0x01, 0x01, 0x69, 0x4c, 0xb9, 0x9b, 0x22]));
      var t = reader.readPacket();

      expect(t is InternalOperationRequest, isTrue);
      expect(t.code, 1);  // JoinLobby
      expect(t.params.length, 1);
      expect((t.params[1] as SizedInt).value, 0x4CB99B22);  // FIND_FRIEND_REQUEST_LIST
    });
    test('packet 0x07: InternalOperationResponse', () {
      var reader = ProtocolReader(Uint8List.fromList([0xf3, 0x07, 0x01, 0x00, 0x00, 0x2a, 0x00, 0x02, 0x01, 0x69, 0x4c, 0xb9, 0x9b, 0x22, 0x02, 0x69, 0x9f, 0x13, 0x6e, 0x5d]));
      var t = reader.readPacket();

      expect(t is InternalOperationResponse, isTrue);
      if (t is InternalOperationResponse) {
        expect(t.code, 1);  // JoinLobby
        expect(t.debugMessage, null);
        expect(t.returnCode, 0);
        expect(t.params.length, 2);
        expect((t.params[1] as SizedInt).value, 0x4CB99B22);  // FIND_FRIEND_REQUEST_LIST
        expect((t.params[2] as SizedInt).value, -0x60EC91A3);  // FIND_FRIENDS_OPTIONS
      }
    });
  });
}
