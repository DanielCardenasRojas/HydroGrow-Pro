import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttService._internal() {
    _initClient();
  }
  static final MqttService I = MqttService._internal();

  late final MqttServerClient _client;

  /// Estado de conexión expuesto a la UI
  final ValueNotifier<bool> connected = ValueNotifier<bool>(false);

  /// Sensores ambiente (DHT22)
  final ValueNotifier<double?> temperatura = ValueNotifier<double?>(null);
  final ValueNotifier<double?> humedad = ValueNotifier<double?>(null);

  /// Sensores de suelo
  final ValueNotifier<double?> suelo1 = ValueNotifier<double?>(null);
  final ValueNotifier<double?> suelo2 = ValueNotifier<double?>(null);

  bool get isConnected =>
      _client.connectionStatus?.state == MqttConnectionState.connected;

  bool _connecting = false;

  // 🔥 TÓPICOS DE SENSORES (COINCIDEN CON NODE-RED)
  static const String _topicTemp = 'sensor/dht22/temperatura';
  static const String _topicHum = 'sensor/dht22/humedad';

  // prefijo para los suelos; en Node-RED usas sensor/suelo/1 y sensor/suelo/2
  static const String _topicSueloPrefix = 'sensor/suelo/';

  void _initClient() {
    final host = dotenv.env['HIVEMQ_HOST'] ?? '';
    final portStr = dotenv.env['HIVEMQ_PORT'] ?? '8883';
    final port = int.tryParse(portStr) ?? 8883;

    // Un solo cliente para toda la app
    _client = MqttServerClient.withPort(host, 'flutter_hydro_app', port);

    // Logs del paquete
    _client.logging(on: true);

    // TLS obligatorio en HiveMQ Cloud
    _client.secure = true;
    _client.securityContext = SecurityContext.defaultContext;

    // Versión de protocolo (3.1.1)
    _client.setProtocolV311();

    _client.keepAlivePeriod = 20;
    _client.connectTimeoutPeriod = 20000;

    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
  }

  // ================== CONEXIÓN ==================

  Future<void> connect() async {
    // Evitar conexiones en paralelo
    if (_connecting) {
      debugPrint('🔌 Ya se está intentando conectar, se ignora esta llamada');
      return;
    }

    // Si ya está conectado, no hacer nada
    if (isConnected) {
      debugPrint('🔌 Ya está conectado a HiveMQ, no se vuelve a conectar');
      return;
    }

    _connecting = true;

    final host = dotenv.env['HIVEMQ_HOST'] ?? '';
    final portStr = dotenv.env['HIVEMQ_PORT'] ?? '8883';
    final port = int.tryParse(portStr) ?? 8883;
    final username = dotenv.env['HIVEMQ_USERNAME'] ?? '';
    final password = dotenv.env['HIVEMQ_PASSWORD'] ?? '';

    debugPrint('🔌 Conectando a HiveMQ $host:$port (TLS)...');
    debugPrint(
      '1- Authenticating with username {$username} and password {$password}',
    );

    try {
      final status = await _client.connect(username, password);

      debugPrint(
        '🔌 Resultado connect => state=${status?.state} returnCode=${status?.returnCode}',
      );

      if (status?.state == MqttConnectionState.connected &&
          status?.returnCode == MqttConnectReturnCode.connectionAccepted) {
        debugPrint('✅ Conectado a HiveMQ');
        connected.value = true;

        _subscribeSensors();
        _listenUpdates();
      } else {
        debugPrint(
          '❌ FALLO conectando: state=${status?.state} returnCode=${status?.returnCode}',
        );
        connected.value = false;
        if (_client.connectionStatus?.state !=
            MqttConnectionState.disconnected) {
          _client.disconnect();
        }
      }
    } on NoConnectionException catch (e) {
      debugPrint('❌ NoConnectionException conectando a HiveMQ: $e');
      connected.value = false;
      if (_client.connectionStatus?.state != MqttConnectionState.disconnected) {
        _client.disconnect();
      }
    } on ConnectionException catch (e) {
      debugPrint(
        '❌ ConnectionException conectando / suscribiendo en HiveMQ: $e',
      );
      connected.value = false;
      if (_client.connectionStatus?.state != MqttConnectionState.disconnected) {
        _client.disconnect();
      }
    } on Exception catch (e) {
      debugPrint('❌ Excepción conectando a HiveMQ: $e');
      connected.value = false;
      if (_client.connectionStatus?.state != MqttConnectionState.disconnected) {
        _client.disconnect();
      }
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    if (!isConnected) return;
    _client.disconnect();
    connected.value = false;
  }

  // ================== SUBSCRIPCIONES ==================

  void _subscribeSensors() {
    _safeSubscribe(_topicTemp);
    _safeSubscribe(_topicHum);

    // 👇 Un solo wildcard para todos los suelos
    _safeSubscribe('sensor/suelo/#');
  }

  void _safeSubscribe(String topic) {
    if (!isConnected) {
      debugPrint('⚠️ No se puede suscribir a $topic: cliente no conectado');
      return;
    }
    debugPrint('📡 Subscribiéndose a $topic');
    _client.subscribe(topic, MqttQos.atMostOnce);
  }

  void _listenUpdates() {
    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> events) {
      final recMess = events[0].payload as MqttPublishMessage;
      final message = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      final topic = events[0].topic;

      debugPrint('📩 MQTT <- $topic = $message');

      final v = double.tryParse(message);

      if (topic == _topicTemp) {
        if (v != null) temperatura.value = v;
      } else if (topic == _topicHum) {
        if (v != null) humedad.value = v;
      } else if (topic.startsWith(_topicSueloPrefix) && v != null) {
        // topic esperado: sensor/suelo/1 o sensor/suelo/2
        final id = topic.substring(_topicSueloPrefix.length);
        if (id == '1') {
          suelo1.value = v;
        } else if (id == '2') {
          suelo2.value = v;
        }
      }
    });
  }

  // ================== PUBLICACIÓN (ACTUADORES) ==================

  /// Encender / apagar ventiladores (1 o 2)
  void setVentilador(int index, bool on) {
    final topic = 'control/ventilador/$index';
    final payload = on ? '1' : '0';
    _publish(topic, payload);
  }

  /// Encender / apagar bombas (1 o 2)
  void setBomba(int index, bool on) {
    final topic = 'control/bomba/$index'; // ajusta si usas otro nombre
    final payload = on ? '1' : '0';
    _publish(topic, payload);
  }

  /// Encender / apagar TODAS las bombas
  void setBombasAll(bool on) {
    // si quieres que siempre mande a las dos:
    setBomba(1, on);
    setBomba(2, on);
  }

  /// Encender / apagar tira LED
  void setLuz(bool on) {
    const topic = 'control/led';
    final payload = on ? '1' : '0';
    _publish(topic, payload);
  }

  void _publish(String topic, String payload) {
    if (!isConnected) {
      debugPrint('! No conectado, no se publica en $topic');
      return;
    }

    final builder = MqttClientPayloadBuilder()..addString(payload);

    _client.publishMessage(
      topic,
      MqttQos.atMostOnce,
      builder.payload!,
      retain: false,
    );

    debugPrint('📤 MQTT -> $topic = $payload');
  }

  // ================== CALLBACKS ==================

  void _onConnected() {
    debugPrint('✅ OnConnected: cliente conectado');
    connected.value = true;
  }

  void _onDisconnected() {
    debugPrint('🔌 OnDisconnected: cliente desconectado');
    connected.value = false;
  }

  void _onSubscribed(String topic) {
    debugPrint('📡 Subscrito a $topic');
  }
}
