import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/navigation/service_status_provider.dart';

void main() {
  group('ServiceStatus', () {
    test('default constructor has all fields false', () {
      const ServiceStatus status = ServiceStatus();

      expect(status.kodiConfigured, isFalse);
      expect(status.kodiRunning, isFalse);
      expect(status.kodiSyncing, isFalse);
      expect(status.discordEnabled, isFalse);
      expect(status.discordConnected, isFalse);
      expect(status.discordRaSyncActive, isFalse);
    });

    test('hasActiveServices returns false when nothing is enabled', () {
      const ServiceStatus status = ServiceStatus();
      expect(status.hasActiveServices, isFalse);
    });

    test('hasActiveServices returns true when kodiConfigured', () {
      const ServiceStatus status = ServiceStatus(kodiConfigured: true);
      expect(status.hasActiveServices, isTrue);
    });

    test('hasActiveServices returns true when discordEnabled', () {
      const ServiceStatus status = ServiceStatus(discordEnabled: true);
      expect(status.hasActiveServices, isTrue);
    });

    test('hasActiveServices returns true when both enabled', () {
      const ServiceStatus status = ServiceStatus(
        kodiConfigured: true,
        discordEnabled: true,
      );
      expect(status.hasActiveServices, isTrue);
    });

    test('all fields can be set via constructor', () {
      const ServiceStatus status = ServiceStatus(
        kodiConfigured: true,
        kodiRunning: true,
        kodiSyncing: true,
        discordEnabled: true,
        discordConnected: true,
        discordRaSyncActive: true,
      );

      expect(status.kodiConfigured, isTrue);
      expect(status.kodiRunning, isTrue);
      expect(status.kodiSyncing, isTrue);
      expect(status.discordEnabled, isTrue);
      expect(status.discordConnected, isTrue);
      expect(status.discordRaSyncActive, isTrue);
    });
  });
}
