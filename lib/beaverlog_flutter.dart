import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class BeaverLog with WidgetsBindingObserver {
  static final BeaverLog _instance = BeaverLog._internal();
  factory BeaverLog() => _instance;
  BeaverLog._internal();

  bool _isInitialized = false;
  bool _isConfigured = false;
  final Uuid _uuid = const Uuid();
  String? _uid;
  String? _sessionId;
  int? _lastActivity;
  String? _appId;
  String? _publicKey;
  String? _host;

  Future<void> init({
    required String appId,
    required String publicKey,
    required String host,
  }) async {
    _appId = appId;
    _publicKey = publicKey;
    _host = host;
    _isConfigured = true;
    // Auto-initialize after configuration
    await _initialize();
  }

  Future<void> _initialize() async {
    if (!_isInitialized) {
      WidgetsFlutterBinding.ensureInitialized();
      WidgetsBinding.instance.addObserver(this);
      await _loadOrCreateUid();
      _createNewSession();
      _isInitialized = true;
    }
  }

  Future<void> _loadOrCreateUid() async {
    final prefs = await SharedPreferences.getInstance();
    _uid = prefs.getString('beaverlog_uid');

    if (_uid == null) {
      _uid = _uuid.v4();
      await prefs.setString('beaverlog_uid', _uid!);
    }
  }

  void _createNewSession() {
    _sessionId = _uuid.v4();
    _lastActivity = DateTime.now().millisecondsSinceEpoch;
  }

  void _checkSessionTimeout() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastActivity != null && _sessionId != null) {
      final timeDifference = now - _lastActivity!;
      final minutesDifference = timeDifference / (1000 * 60);

      if (minutesDifference >= 5) {
        _createNewSession();
      }
    } else {
      _createNewSession();
    }
  }

  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _onAppOpened();
        break;
      case AppLifecycleState.paused:
        _onAppBackgrounded();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _sendEvent(Map<String, Object?> eventData) async {
    if (!_isConfigured ||
        _host == null ||
        _appId == null ||
        _publicKey == null) {
      debugPrint('BeaverLog: Missing required parameter');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$_host/api/events"),
        headers: {
          'Content-Type': 'application/json',
          'app_id': _appId!,
          'public_key': _publicKey!,
        },
        body: jsonEncode([eventData]),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'BeaverLog: Failed to send event. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('BeaverLog: Error sending event: $e');
    }
  }

  void _onAppOpened() {
    event(eventName: 'app_opened');
  }

  void _onAppBackgrounded() {
    event(eventName: 'app_backgrounded');
  }

  Future<void> event({
    required String eventName,
    Map<String, Object>? meta,
  }) async {
    _checkSessionTimeout();
    _lastActivity = DateTime.now().millisecondsSinceEpoch;

    final eventData = {
      'name': eventName,
      'uid': _uid,
      'session_id': _sessionId,
      'timestamp': _lastActivity,
      'meta': meta ?? {},
    };

    // Send to server
    await _sendEvent(eventData);

    // Local debug print
    debugPrint('Sent Event: $eventData');
  }
}
