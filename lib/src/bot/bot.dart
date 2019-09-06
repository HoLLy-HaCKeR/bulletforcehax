import 'dart:async';
import 'dart:typed_data';

import 'package:bullet_force_hax/bullet_force_hax.dart';

import 'websock_creator.dart';

class Bot {
  static const endpointHost = "ns.exitgames.com";
  static const httpPort = 9093;
  static const httpsPort = 19093;
  static const protocol = "GpBinaryV16";
  static const applicationId = "8c2cad3e-2e3f-4941-9044-b390ff2c4956";
  static const applicationVersion = "1.34_WebGL_1.73";
  static const region = "us";

  String _address;
  String _userId;
  String _secret, _secret2;

  Future connectInitial() async {
    var completer = Completer<void>();

    var firstWebSocket = await connectSocket(endpointHost, httpPort, protocol);
    firstWebSocket.handleError((e) {
      print('!!! Got error on first ws: $e');
    });
    firstWebSocket.listen((data) {
      var parsed = ProtocolReader(data).readPacket();

      if (parsed is InitResponse) {
        firstWebSocket.add(_quickSerialize(InternalOperationRequest(InternalOperationCode.Ping, {
          1: SizedInt.int(0)  // should be Environment.TickCount
        })));

        firstWebSocket.add(_quickSerialize(OperationRequest(OperationCode.Authenticate, {
          ParameterCode.AppVersion: applicationVersion,
          ParameterCode.ApplicationId: applicationId,
          ParameterCode.AzureNodeInfo: region,
        })));
      }
      else if (parsed is InternalOperationResponse && parsed.code == InternalOperationCode.Ping) {
        // param 1 = sent time, param 2 = server time offset
        var num1 = parsed.params[2];
        print('server0 tickbase: $num1');
      } else if (parsed is OperationResponse && parsed.code == OperationCode.Authenticate) {
        // var nickname = parsed.params[196];
        _address = parsed.params[ParameterCode.Address];
        _secret = parsed.params[ParameterCode.Secret];
        _userId = parsed.params[ParameterCode.UserId];

        // close socket, we have what we need
        firstWebSocket.close();
        completer.complete();
      } else {
        assert(false);
        print('Received unknown packet on first ws: $parsed');
      }
    });
    return completer.future;
  }

  Future connectMain() async {
    var completer = Completer<void>();

    var split = _address.split('://').last.split(':'); // format is ws://host:port
    var host = split[0];
    var port = int.parse(split[1]);
    var ws = await connectSocket(host, port, protocol);
    ws.handleError((e) {
      print('!!! Got error on ws: $e');
    });
    ws.listen((data) {
      // data
      var parsed = ProtocolReader(data).readPacket();

      if (parsed is InitResponse) {
        print('got init response! yay!');
        ws.add(_quickSerialize(InternalOperationRequest(InternalOperationCode.Ping, {
          1: SizedInt.int(0)  // should be Environment.TickCount
        })));

        ws.add(_quickSerialize(OperationRequest(OperationCode.Authenticate, {
          ParameterCode.Secret: _secret,
        })));
      } else if (parsed is InternalOperationResponse && parsed.code == InternalOperationCode.Ping) {
        // param 1 = sent time, param 2 = server time offset
        var num1 = parsed.params[2];
        print('server1 tickbase: $num1');

        // TODO: send pings every 1s
        ws.close();
        completer.complete();
      } else if (parsed is OperationResponse && parsed.code == OperationCode.Authenticate) {
        // get more auth stuff?
        _secret2 = parsed.params[ParameterCode.Secret];
        // var matchmakingType = parsed.params[ParameterCode.MatchMakingType];
      } else {
        // assert(false);
        print('Received unhandled packet: $parsed');
      }
    });

    return completer.future;
  }

  static Uint8List _quickSerialize(PacketWithPayload pwp) => (ProtocolWriter()..writePacket(pwp)).toBytes();
}