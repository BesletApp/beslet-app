import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tracking_provider.dart';

/// The guided spiritual flow: Bible → Prayer → Act. One faithful step is
/// enough for "Act" — grace, not a perfect day.
class DailyFlow {
  final bool bibleDone;
  final bool prayerDone;
  final bool actionDone;
  final int done;
  final int total;
  final int currentStep;

  const DailyFlow({
    required this.bibleDone,
    required this.prayerDone,
    required this.actionDone,
    required this.done,
    required this.total,
    required this.currentStep,
  });

  static const int totalSteps = 3;
}

/// Drives the Home's primary card and the Growth "Today's flow" pillars.
/// `currentStep` is the first incomplete step (0 = Bible, 1 = Prayer,
/// 2 = Act, 3 = all done). Derives from `trackingDataProvider` so the Home
/// card, Growth pillars, and reading XP always agree.
final dailyFlowProvider = Provider<DailyFlow>((ref) {
  final tracking = ref.watch(trackingDataProvider).valueOrNull;
  final bibleDone = tracking?.bibleDone ?? false;
  final prayerDone = tracking?.prayerDone ?? false;
  final actionDone = tracking?.actionDone ?? false;
  final done = tracking?.pillarsDone ?? 0;
  final currentStep = !bibleDone ? 0 : (!prayerDone ? 1 : (!actionDone ? 2 : 3));
  return DailyFlow(
    bibleDone: bibleDone,
    prayerDone: prayerDone,
    actionDone: actionDone,
    done: done,
    total: DailyFlow.totalSteps,
    currentStep: currentStep,
  );
});
