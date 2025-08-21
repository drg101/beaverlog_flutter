import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beaverlog_flutter/beaverlog_flutter.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  
  setUp(() {
    // Mock SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
  });

  group('BeaverLog Basic Tests', () {
    test('init() completes without error', () async {
      final beaverLog = BeaverLog();
      
      expect(() async {
        await beaverLog.init(
          appId: 'test-app',
          publicKey: 'test-key',
          host: 'https://test.com',
        );
      }, returnsNormally);
    });

    test('event() completes without error after init', () async {
      final beaverLog = BeaverLog();
      
      await beaverLog.init(
        appId: 'test-app',
        publicKey: 'test-key',
        host: 'https://test.com',
      );
      
      expect(() async {
        await beaverLog.event(
          eventName: 'test_event',
          meta: {'key': 'value'},
        );
      }, returnsNormally);
    });

    test('multiple events can be logged', () async {
      final beaverLog = BeaverLog();
      
      await beaverLog.init(
        appId: 'test-app',
        publicKey: 'test-key',
        host: 'https://test.com',
      );
      
      // Should not throw
      await beaverLog.event(eventName: 'event1');
      await beaverLog.event(eventName: 'event2', meta: {'test': true});
      await beaverLog.event(eventName: 'event3', meta: {'count': 42});
    });

    test('dispose() completes without error', () async {
      final beaverLog = BeaverLog();
      
      await beaverLog.init(
        appId: 'test-app',
        publicKey: 'test-key',
        host: 'https://test.com',
      );
      
      expect(() {
        beaverLog.dispose();
      }, returnsNormally);
    });
  });
}