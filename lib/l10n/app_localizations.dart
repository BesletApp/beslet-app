import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ብስለት — Maturity'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @bible.
  ///
  /// In en, this message translates to:
  /// **'Bible'**
  String get bible;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @prayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get prayer;

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habits;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @reflection.
  ///
  /// In en, this message translates to:
  /// **'Reflection'**
  String get reflection;

  /// No description provided for @dailyHabits.
  ///
  /// In en, this message translates to:
  /// **'Daily Habits'**
  String get dailyHabits;

  /// No description provided for @verseOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Verse of the Day'**
  String get verseOfTheDay;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read More →'**
  String get readMore;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @dailyChecklist.
  ///
  /// In en, this message translates to:
  /// **'Daily Checklist'**
  String get dailyChecklist;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @amharic.
  ///
  /// In en, this message translates to:
  /// **'አማርኛ'**
  String get amharic;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get pageNotFound;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @noHabitsYet.
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get noHabitsYet;

  /// No description provided for @addHabit.
  ///
  /// In en, this message translates to:
  /// **'Add Habit'**
  String get addHabit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @weeklyGoal.
  ///
  /// In en, this message translates to:
  /// **'Weekly Goal'**
  String get weeklyGoal;

  /// No description provided for @prayerStart.
  ///
  /// In en, this message translates to:
  /// **'Start Prayer'**
  String get prayerStart;

  /// No description provided for @prayerComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete Prayer'**
  String get prayerComplete;

  /// No description provided for @prayerTakeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Take 5–10 minutes. When you\'re done, tap Complete.'**
  String get prayerTakeMinutes;

  /// No description provided for @prayerTimerHint.
  ///
  /// In en, this message translates to:
  /// **'Pray as you feel led. Complete when ready.'**
  String get prayerTimerHint;

  /// No description provided for @prayerSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip timer — just log I prayed'**
  String get prayerSkip;

  /// No description provided for @prayerCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'Prayed today ✓'**
  String get prayerCompletedToday;

  /// No description provided for @prayerPrayAgain.
  ///
  /// In en, this message translates to:
  /// **'Pray Again'**
  String get prayerPrayAgain;

  /// No description provided for @iPrayedToday.
  ///
  /// In en, this message translates to:
  /// **'I prayed today ✓'**
  String get iPrayedToday;

  /// No description provided for @didYouPray.
  ///
  /// In en, this message translates to:
  /// **'Did you pray today?'**
  String get didYouPray;

  /// No description provided for @prayerLogged.
  ///
  /// In en, this message translates to:
  /// **'Prayer logged! +15 XP'**
  String get prayerLogged;

  /// No description provided for @trackTime.
  ///
  /// In en, this message translates to:
  /// **'Track time'**
  String get trackTime;

  /// No description provided for @notePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get notePlaceholder;

  /// No description provided for @prayerReminder.
  ///
  /// In en, this message translates to:
  /// **'Prayer Reminder'**
  String get prayerReminder;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get setReminder;

  /// No description provided for @removeReminder.
  ///
  /// In en, this message translates to:
  /// **'Remove Reminder'**
  String get removeReminder;

  /// No description provided for @dailyAt.
  ///
  /// In en, this message translates to:
  /// **'Daily at {time}'**
  String dailyAt(Object time);

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @noSkillsYet.
  ///
  /// In en, this message translates to:
  /// **'No skills yet'**
  String get noSkillsYet;

  /// No description provided for @trackSkills.
  ///
  /// In en, this message translates to:
  /// **'Track skills you want to develop!'**
  String get trackSkills;

  /// No description provided for @addSkill.
  ///
  /// In en, this message translates to:
  /// **'Add Skill'**
  String get addSkill;

  /// No description provided for @newSkill.
  ///
  /// In en, this message translates to:
  /// **'New Skill'**
  String get newSkill;

  /// No description provided for @skillName.
  ///
  /// In en, this message translates to:
  /// **'Skill name'**
  String get skillName;

  /// No description provided for @categoryAndIcon.
  ///
  /// In en, this message translates to:
  /// **'Category & Icon'**
  String get categoryAndIcon;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutes(Object minutes);

  /// No description provided for @xp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xp;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Lv'**
  String get level;

  /// No description provided for @seed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get seed;

  /// No description provided for @growing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get growing;

  /// No description provided for @rooted.
  ///
  /// In en, this message translates to:
  /// **'Rooted'**
  String get rooted;

  /// No description provided for @mature.
  ///
  /// In en, this message translates to:
  /// **'Mature'**
  String get mature;

  /// No description provided for @leader.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get leader;

  /// No description provided for @fellowship.
  ///
  /// In en, this message translates to:
  /// **'Fellowship'**
  String get fellowship;

  /// No description provided for @familyTime.
  ///
  /// In en, this message translates to:
  /// **'Time with Family'**
  String get familyTime;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected!'**
  String get connected;

  /// No description provided for @reachOut.
  ///
  /// In en, this message translates to:
  /// **'Reach out to someone today'**
  String get reachOut;

  /// No description provided for @iReachedOut.
  ///
  /// In en, this message translates to:
  /// **'I reached out to someone'**
  String get iReachedOut;

  /// No description provided for @whoDidYouConnect.
  ///
  /// In en, this message translates to:
  /// **'Who did you connect with?'**
  String get whoDidYouConnect;

  /// No description provided for @logConnection.
  ///
  /// In en, this message translates to:
  /// **'Log Connection'**
  String get logConnection;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @logTime.
  ///
  /// In en, this message translates to:
  /// **'Log Time'**
  String get logTime;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @whatDidYouDo.
  ///
  /// In en, this message translates to:
  /// **'What did you do? (optional)'**
  String get whatDidYouDo;

  /// No description provided for @alreadyLogged.
  ///
  /// In en, this message translates to:
  /// **'Already logged today'**
  String get alreadyLogged;

  /// No description provided for @daysThisWeek.
  ///
  /// In en, this message translates to:
  /// **'days this week'**
  String get daysThisWeek;

  /// No description provided for @hoursThisWeek.
  ///
  /// In en, this message translates to:
  /// **'hours this week'**
  String get hoursThisWeek;

  /// No description provided for @todaysGrowth.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Growth'**
  String get todaysGrowth;

  /// No description provided for @spiritual.
  ///
  /// In en, this message translates to:
  /// **'Spiritual'**
  String get spiritual;

  /// No description provided for @connectedWith.
  ///
  /// In en, this message translates to:
  /// **'Connected with {name}'**
  String connectedWith(Object name);

  /// No description provided for @logFamilyTime.
  ///
  /// In en, this message translates to:
  /// **'Log family time'**
  String get logFamilyTime;

  /// No description provided for @familyHoursLogged.
  ///
  /// In en, this message translates to:
  /// **'{hours}h logged today'**
  String familyHoursLogged(Object hours);

  /// No description provided for @qualityTimeMatters.
  ///
  /// In en, this message translates to:
  /// **'Quality time matters. Keep it up!'**
  String get qualityTimeMatters;

  /// No description provided for @howMuchFamilyTime.
  ///
  /// In en, this message translates to:
  /// **'How much time did you spend with family today?'**
  String get howMuchFamilyTime;

  /// No description provided for @summerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Summer {year} begins June 8 (Sene 1). Get ready!'**
  String summerPrompt(Object year);

  /// No description provided for @summerStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Summer starts in {days} days.'**
  String summerStartsIn(Object days);

  /// No description provided for @getReadyForSummer.
  ///
  /// In en, this message translates to:
  /// **'Get ready for summer!'**
  String get getReadyForSummer;

  /// No description provided for @buildHabitsBefore.
  ///
  /// In en, this message translates to:
  /// **'Build your spiritual habits before {date}.'**
  String buildHabitsBefore(Object date);

  /// No description provided for @comeBackWhenSummer.
  ///
  /// In en, this message translates to:
  /// **'Come back when summer begins!'**
  String get comeBackWhenSummer;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'days left'**
  String get daysLeft;

  /// No description provided for @pillarSpiritualComplete.
  ///
  /// In en, this message translates to:
  /// **'Prayer ✓ · Bible ✓'**
  String get pillarSpiritualComplete;

  /// No description provided for @pillarPrayerDoneBiblePending.
  ///
  /// In en, this message translates to:
  /// **'Prayer ✓ · Bible pending'**
  String get pillarPrayerDoneBiblePending;

  /// No description provided for @pillarBibleDonePrayerPending.
  ///
  /// In en, this message translates to:
  /// **'Bible ✓ · Prayer pending'**
  String get pillarBibleDonePrayerPending;

  /// No description provided for @pillarSpiritualPending.
  ///
  /// In en, this message translates to:
  /// **'Prayer & Bible'**
  String get pillarSpiritualPending;

  /// No description provided for @skillTapToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap to start'**
  String get skillTapToStart;

  /// No description provided for @skillMinutesToday.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m today'**
  String skillMinutesToday(Object minutes);

  /// No description provided for @fellowshipConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected ✓'**
  String get fellowshipConnected;

  /// No description provided for @familyHoursToday.
  ///
  /// In en, this message translates to:
  /// **'{hours}h today'**
  String familyHoursToday(Object hours);

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get aboutApp;

  /// No description provided for @daysShownUp.
  ///
  /// In en, this message translates to:
  /// **'days shown up'**
  String get daysShownUp;

  /// No description provided for @ofTotal.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String ofTotal(Object total);

  /// No description provided for @daysRead.
  ///
  /// In en, this message translates to:
  /// **'days read'**
  String get daysRead;

  /// No description provided for @minutesAbbr.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesAbbr;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'connections'**
  String get connections;

  /// No description provided for @firstReadingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your first reading is waiting'**
  String get firstReadingWaiting;

  /// No description provided for @firstSkillWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your first skill step is waiting'**
  String get firstSkillWaiting;

  /// No description provided for @firstConnectionWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your first connection is waiting'**
  String get firstConnectionWaiting;

  /// No description provided for @firstFamilyWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your first family moment is waiting'**
  String get firstFamilyWaiting;

  /// No description provided for @spiritualGrowth.
  ///
  /// In en, this message translates to:
  /// **'Spiritual growth'**
  String get spiritualGrowth;

  /// No description provided for @phase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get phase;

  /// No description provided for @startedAgo.
  ///
  /// In en, this message translates to:
  /// **'Started {days} days ago'**
  String startedAgo(Object days);

  /// No description provided for @showedUpTimes.
  ///
  /// In en, this message translates to:
  /// **'Showed up {count} times'**
  String showedUpTimes(Object count);

  /// No description provided for @hoursInWord.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours in the Word'**
  String hoursInWord(Object hours);

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get doneLabel;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get inProgress;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'keep going'**
  String get keepGoing;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'locked'**
  String get locked;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get levelLabel;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @userSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Arba Minch University · Computer Science'**
  String get userSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
