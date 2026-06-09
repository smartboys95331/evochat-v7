import 'dart:io';
import 'dart:convert';
import 'package:bonsoir/bonsoir.dart';
import 'encryption_service.dart';
import '../models/models.dart';

class MeshService {
  BonsoirService? _service;
  BonsoirBroadcast? _broadcast;
  ServerSocket? _server;
  bool _isListening = false;
  bool _isBroadcasting = false;

  static const int _port = 4545;
  static const String _serviceType = '_evochat._tcp';

  /// Start TCP server to receive messages
  Future<void> startListening(
      String myId, Function(String senderId, String text) onMessage) async {
    if (_isListening) return;
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, _port);
      _isListening = true;
      _server!.listen((Socket client) {
        final buffer = StringBuffer();
        client.listen(
          (data) => buffer.write(utf8.decode(data)),
          onDone: () {
            try {
              final raw = buffer.toString();
              final decrypted = EncryptionService.decryptText(raw);
              final separatorIndex = decrypted.indexOf('|');
              if (separatorIndex != -1) {
                final senderId = decrypted.substring(0, separatorIndex);
                final text = decrypted.substring(separatorIndex + 1);
                onMessage(senderId, text);
              }
            } catch (e) {
              print('Message parse error: $e');
            }
          },
          onError: (e) => print('Socket error: $e'),
          cancelOnError: true,
        );
      });
    } catch (e) {
      print('Listen error: $e');
      _isListening = false;
    }
  }

  /// Broadcast our presence on the local network
  Future<void> startBroadcasting(String userName) async {
    if (_isBroadcasting) return;
    try {
      _service = BonsoirService(
          name: userName, type: _serviceType, port: _port);
      _broadcast = BonsoirBroadcast(service: _service!);
      await _broadcast!.ready;
      await _broadcast!.start();
      _isBroadcasting = true;
    } catch (e) {
      print('Broadcast error: $e');
    }
  }

  /// Discover peers on local network
  Future<List<Peer>> discoverPeers() async {
    final List<Peer> foundPeers = [];
    BonsoirDiscovery? discovery;
    try {
      discovery = BonsoirDiscovery(type: _serviceType);
      await discovery.ready;

      discovery.eventStream!.listen((event) {
        if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
          final svc = event.service;
          if (svc != null) {
            // Extract IP from JSON map — works across all bonsoir 5.x versions
            final json = svc.toJson();
            final host = json['host']?.toString() ??
                json['ip']?.toString() ??
                json['serviceIp']?.toString() ??
                json['address']?.toString();

            if (host != null && host.isNotEmpty) {
              final exists = foundPeers.any((p) => p.name == svc.name);
              if (!exists) {
                foundPeers.add(Peer(
                  name: svc.name,
                  host: host,
                  port: svc.port,
                ));
              }
            }
          }
        }
      });

      await discovery.start();
      await Future.delayed(const Duration(seconds: 5));
      await discovery.stop();
    } catch (e) {
      print('Discovery error: $e');
      await discovery?.stop();
    }
    return foundPeers;
  }

  /// Send an encrypted message to a peer
  Future<bool> sendMessage(String host, String myId, String text) async {
    try {
      final socket = await Socket.connect(host, _port,
          timeout: const Duration(seconds: 5));
      final encrypted = EncryptionService.encryptText('$myId|$text');
      socket.add(utf8.encode(encrypted));
      await socket.flush();
      await socket.close();
      return true;
    } catch (e) {
      print('Send error: $e');
      return false;
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    await _broadcast?.stop();
    await _server?.close();
    _isListening = false;
    _isBroadcasting = false;
  }
}
