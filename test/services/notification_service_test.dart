import 'package:beslet_app/core/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationService.shouldAskForNotificationPermission', () {
    test('never asks when notifications are already enabled', () {
      expect(
        NotificationService.shouldAskForNotificationPermission(
          notificationsEnabled: true,
          lastAskedBuildNumber: null,
          currentBuildNumber: '65',
        ),
        false,
      );
    });

    test('asks on a fresh install that has never been asked', () {
      expect(
        NotificationService.shouldAskForNotificationPermission(
          notificationsEnabled: false,
          lastAskedBuildNumber: null,
          currentBuildNumber: '65',
        ),
        true,
      );
    });

    test('does not nag again at the same build after a denial', () {
      expect(
        NotificationService.shouldAskForNotificationPermission(
          notificationsEnabled: false,
          lastAskedBuildNumber: '65',
          currentBuildNumber: '65',
        ),
        false,
      );
    });

    test('re-asks after an upgrade from an older installed version', () {
      expect(
        NotificationService.shouldAskForNotificationPermission(
          notificationsEnabled: false,
          lastAskedBuildNumber: '63',
          currentBuildNumber: '65',
        ),
        true,
      );
    });

    test('re-asks even when the current build cannot be resolved', () {
      expect(
        NotificationService.shouldAskForNotificationPermission(
          notificationsEnabled: false,
          lastAskedBuildNumber: '63',
          currentBuildNumber: '',
        ),
        true,
      );
    });
  });
}