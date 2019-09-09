import 'dart:convert';
import 'dart:typed_data';

import 'package:bullet_force_hax/bullet_force_hax.dart';
import 'package:bullet_force_hax/src/typed_wrappers/basic_game_info.dart';
import 'package:bullet_force_hax/src/typed_wrappers/player_properties.dart';
import 'package:test/test.dart';

void main() {
  const joinGameOperationResponsePacket = "8wPiAAAqAAT+aQAAAAP5aAABaQAAAAJoAAhz"
      "AA1jaGFyYWN0ZXJDYW1vYgBzAA91bmxvY2tlZHdlYXBvbnN5AAJpAAFCgAAAAABzAARyYW5r"
      "YhBzAApraWxsc3RyZWFrYgBzAAVwZXJrc3gAAAAIAAAAAAAAAABzAAp0ZWFtTnVtYmVyYgFi"
      "/3MADihIKSBmaWZpbmFnYXRhcwAFbW9kZWxiAPhoABdzABJtYXRjaENvdW50ZG93blRpbWVm"
      "AAAAAGL5bwFi/2IJYv5vAWL9bwFzAAlldmVudGNvZGVpAAAAAGL6eQAJcwAIcm9vbU5hbWUA"
      "B21hcE5hbWUACG1vZGVOYW1lAAhwYXNzd29yZAAJZGVkaWNhdGVkAAxzd2l0Y2hpbmdtYXAA"
      "DmFsbG93ZWR3ZWFwb25zAAlldmVudGNvZGUAC2F2ZXJhZ2VyYW5rcwAJdGltZVNjYWxlZj+A"
      "AABi+GkAAAACcwAIcGFzc3dvcmRzAABzAAhtb2RlTmFtZXMACENvbnF1ZXN0cwALYXZlcmFn"
      "ZXJhbmtpAAAAEHMADHJvdW5kU3RhcnRlZG8AcwAIcm9vbU5hbWVzAAxEZWZhdWx0TWF0Y2hz"
      "AAdtYXBOYW1lcwAFVXJiYW5zAAdtYXhQaW5nawK8cwATYmFubmVkd2VhcG9ubWVzc2FnZXMA"
      "P1dlYXBvbiBub3QgYWxsb3dlZCEgCiBDaGVjayB0aGUgcGF1c2UgbWVudSBmb3IgYWxsb3dl"
      "ZCB3ZWFwb25zLnMACWRlZGljYXRlZG8AcwAMbWF0Y2hTdGFydGVkbwFzAA1ndW5HYW1lUHJl"
      "c2V0aQAAAABzAA5hbGxvd2Vkd2VhcG9uc3kAAmn/5f98AABnA3MACnNjb3JlbGltaXRpAAAB"
      "XnMADHN3aXRjaGluZ21hcG8A/HkAAmkAAAACAAAAAw==";
  
  group('Full packet TypedWrappers tests', () {
    test('OperationResponse JoinGame (226): PlayerProperties', () {
      var packet = ProtocolReader(base64.decode(joinGameOperationResponsePacket)).readPacket();
      expect(packet is OperationResponse, isTrue);
      if (packet is OperationResponse) {
        expect(packet.code, OperationCode.JoinGame);
        expect(packet.returnCode, 0);
        expect(packet.debugMessage, null);
        expect(packet.params.length, 4);

        expect(packet.params.containsKey(ParameterCode.ActorNr), isTrue);
        expect(packet.params.containsKey(ParameterCode.ActorList), isTrue);
        expect(packet.params.containsKey(ParameterCode.GameProperties), isTrue);
        expect(packet.params.containsKey(ParameterCode.PlayerProperties), isTrue);

        expect(packet.params[ParameterCode.ActorNr], SizedInt.int(3));
        expect(packet.params[ParameterCode.ActorList].toString(), ProtocolArray(DataType.Integer, [SizedInt.int(2), SizedInt.int(3)]).toString());

        var gameProps = packet.params[ParameterCode.GameProperties] as Map;
        expect(gameProps.length, 23);
        // TODO: GameProperties

        var playerProps = packet.params[ParameterCode.PlayerProperties] as Map;
        var firstPlayerProps = playerProps[SizedInt.int(2)];
        var props = PlayerProperties.fromMap(firstPlayerProps);
        expect(props, PlayerProperties()
            ..characterCamo = 0
            ..unlockedWeapons = [82560, 0]
            ..rank = 16
            ..killStreak = 0
            ..perks = Uint8List(8)
            ..teamNumber = 1
            ..name = "(H) fifinagata"
            ..model = 0
        );
      }
    });
  });

  group('Individual TypedWrappers tests', () {
    test('$PlayerProperties', () {
      var testProps = PlayerProperties()
        ..characterCamo = 1
        ..unlockedWeapons = [82560, 0]
        ..rank = 56
        ..killStreak = 2
        ..perks = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7])
        ..teamNumber = 10
        ..name = "TestName"
        ..model = 8;

      var map = testProps.toMap();
      var bytes = (ProtocolWriter()..writeValue(map)).toBytes();
      var newMap = ProtocolReader(bytes).readValue();
      var newProps = PlayerProperties.fromMap(newMap as Map);
      expect(testProps, newProps);
    });

    test('$BasicGameInfo', () {
      var testGame = BasicGameInfo()
      ..roomName = "TestRoom"
      ..password = "TestPassword"
      ..password = "TestPassword"
      ..modeName = "aaa"
      ..mapName = "www"
      ..playerCount = 15
      ..maxPlayerCount = 16
      ..averageRank = 42
      ..allowedWeapons = [0x01234567, -0x01234567]
      ..switchingMap = false
      ..dedicated = true
      ..eventCode = 0
      ..field253 = false;

      var map = testGame.toMap();
      var bytes = (ProtocolWriter()..writeValue(map)).toBytes();
      var newMap = ProtocolReader(bytes).readValue();
      var newProps = BasicGameInfo.fromMap(newMap as Map);
      expect(testGame, newProps);
    });
  });
}