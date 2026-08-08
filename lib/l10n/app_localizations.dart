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

  /// No description provided for @growth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get growth;

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

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

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

  /// No description provided for @goodMorningM.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorningM;

  /// No description provided for @goodMorningF.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorningF;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodAfternoonM.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoonM;

  /// No description provided for @goodAfternoonF.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoonF;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @goodEveningM.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEveningM;

  /// No description provided for @goodEveningF.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEveningF;

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

  /// No description provided for @prayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get prayerTimes;

  /// No description provided for @prayWithoutCeasing.
  ///
  /// In en, this message translates to:
  /// **'Pray without ceasing — 1 Thessalonians 5:17'**
  String get prayWithoutCeasing;

  /// No description provided for @addPrayerTime.
  ///
  /// In en, this message translates to:
  /// **'Add prayer time'**
  String get addPrayerTime;

  /// No description provided for @noPrayerTimes.
  ///
  /// In en, this message translates to:
  /// **'No prayer times set yet'**
  String get noPrayerTimes;

  /// No description provided for @prayerTimesHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press a time to let it go'**
  String get prayerTimesHint;

  /// No description provided for @timeAdded.
  ///
  /// In en, this message translates to:
  /// **'Prayer time added 🙏'**
  String get timeAdded;

  /// No description provided for @timeRemoved.
  ///
  /// In en, this message translates to:
  /// **'Prayer time removed'**
  String get timeRemoved;

  /// No description provided for @letGoTime.
  ///
  /// In en, this message translates to:
  /// **'Let this time go?'**
  String get letGoTime;

  /// No description provided for @removePrayerTimeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {time} from your prayer times?'**
  String removePrayerTimeConfirm(Object time);

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @waysToPray.
  ///
  /// In en, this message translates to:
  /// **'Ways to pray'**
  String get waysToPray;

  /// No description provided for @modeThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks'**
  String get modeThanks;

  /// No description provided for @modeAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get modeAsk;

  /// No description provided for @modeRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get modeRest;

  /// No description provided for @modeRepent.
  ///
  /// In en, this message translates to:
  /// **'Repent'**
  String get modeRepent;

  /// No description provided for @modeGuideRepent.
  ///
  /// In en, this message translates to:
  /// **'Confess what you know — He is faithful to forgive.'**
  String get modeGuideRepent;

  /// No description provided for @modeGuideThanks.
  ///
  /// In en, this message translates to:
  /// **'Give thanks in everything — it is His will for you.'**
  String get modeGuideThanks;

  /// No description provided for @modeGuideAsk.
  ///
  /// In en, this message translates to:
  /// **'Present your requests to God with thanksgiving.'**
  String get modeGuideAsk;

  /// No description provided for @modeGuideRest.
  ///
  /// In en, this message translates to:
  /// **'Be still — you are not alone.'**
  String get modeGuideRest;

  /// No description provided for @prayerWords.
  ///
  /// In en, this message translates to:
  /// **'Pray the words Jesus gave'**
  String get prayerWords;

  /// No description provided for @lordsPrayer.
  ///
  /// In en, this message translates to:
  /// **'Our Father in heaven, hallowed be your name. Your kingdom come, your will be done, on earth as it is in heaven. Give us today our daily bread. And forgive us our debts, as we also have forgiven our debtors. And lead us not into temptation, but deliver us from the evil one. Amen.'**
  String get lordsPrayer;

  /// No description provided for @lordHaveMercy.
  ///
  /// In en, this message translates to:
  /// **'Lord, have mercy.'**
  String get lordHaveMercy;

  /// No description provided for @nextAlarmRings.
  ///
  /// In en, this message translates to:
  /// **'Next: {time} · in {remaining}'**
  String nextAlarmRings(Object remaining, Object time);

  /// No description provided for @hoursAndMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String hoursAndMinutes(Object hours, Object minutes);

  /// No description provided for @minutesOnly.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String minutesOnly(Object minutes);

  /// No description provided for @morningAbbr.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get morningAbbr;

  /// No description provided for @eveningAbbr.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get eveningAbbr;

  /// No description provided for @prayerTopics.
  ///
  /// In en, this message translates to:
  /// **'Prayer topics'**
  String get prayerTopics;

  /// No description provided for @topicsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write what you want to bring before God…'**
  String get topicsPlaceholder;

  /// No description provided for @topicsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get topicsSaved;

  /// No description provided for @beginPresence.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get beginPresence;

  /// No description provided for @stepAway.
  ///
  /// In en, this message translates to:
  /// **'Step away'**
  String get stepAway;

  /// No description provided for @returnHere.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnHere;

  /// No description provided for @restNow.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restNow;

  /// No description provided for @justBeStill.
  ///
  /// In en, this message translates to:
  /// **'Be still and know'**
  String get justBeStill;

  /// No description provided for @revealTime.
  ///
  /// In en, this message translates to:
  /// **'Reveal felt time'**
  String get revealTime;

  /// No description provided for @hideTime.
  ///
  /// In en, this message translates to:
  /// **'Hide time'**
  String get hideTime;

  /// No description provided for @prayerRestLogged.
  ///
  /// In en, this message translates to:
  /// **'You rested here. That matters.'**
  String get prayerRestLogged;

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

  /// No description provided for @dailyTasks.
  ///
  /// In en, this message translates to:
  /// **'Daily Tasks'**
  String get dailyTasks;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get myTasks;

  /// No description provided for @planYourDay.
  ///
  /// In en, this message translates to:
  /// **'Good morning! Plan your day'**
  String get planYourDay;

  /// No description provided for @setIntentions.
  ///
  /// In en, this message translates to:
  /// **'Set your intentions for today'**
  String get setIntentions;

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get quickAdd;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @reviewYourDay.
  ///
  /// In en, this message translates to:
  /// **'Time to review your day!'**
  String get reviewYourDay;

  /// No description provided for @eveningReview.
  ///
  /// In en, this message translates to:
  /// **'Evening Review'**
  String get eveningReview;

  /// No description provided for @tasksDoneOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} tasks done'**
  String tasksDoneOf(Object done, Object total);

  /// No description provided for @myGoals.
  ///
  /// In en, this message translates to:
  /// **'My Goals'**
  String get myGoals;

  /// No description provided for @addGoal.
  ///
  /// In en, this message translates to:
  /// **'Add Goal'**
  String get addGoal;

  /// No description provided for @editSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Edit Quick Add'**
  String get editSuggestions;

  /// No description provided for @carryToTomorrow.
  ///
  /// In en, this message translates to:
  /// **'→ Tomorrow'**
  String get carryToTomorrow;

  /// No description provided for @skipTask.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipTask;

  /// No description provided for @taskXpEarned.
  ///
  /// In en, this message translates to:
  /// **'{title} done! +5 XP'**
  String taskXpEarned(Object title);

  /// No description provided for @allDoneBonus.
  ///
  /// In en, this message translates to:
  /// **'All tasks complete! +10 XP bonus'**
  String get allDoneBonus;

  /// No description provided for @howWasYourDay.
  ///
  /// In en, this message translates to:
  /// **'How was your day?'**
  String get howWasYourDay;

  /// No description provided for @doneForToday.
  ///
  /// In en, this message translates to:
  /// **'Done for today'**
  String get doneForToday;

  /// No description provided for @noTasksPlanned.
  ///
  /// In en, this message translates to:
  /// **'No tasks planned for today'**
  String get noTasksPlanned;

  /// No description provided for @planTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Plan tomorrow to stay on track!'**
  String get planTomorrow;

  /// No description provided for @tasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks completed'**
  String tasksCompleted(Object count);

  /// No description provided for @firstTaskWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your first task is waiting'**
  String get firstTaskWaiting;

  /// No description provided for @noDownloads.
  ///
  /// In en, this message translates to:
  /// **'No downloaded chapters yet'**
  String get noDownloads;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileSaved;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed — restart app to fully apply'**
  String get languageChanged;

  /// No description provided for @noBadgesYet.
  ///
  /// In en, this message translates to:
  /// **'Keep going to earn badges'**
  String get noBadgesYet;

  /// No description provided for @vineyardTitle.
  ///
  /// In en, this message translates to:
  /// **'The Vineyard'**
  String get vineyardTitle;

  /// No description provided for @soilYoursGrowingHis.
  ///
  /// In en, this message translates to:
  /// **'The soil is yours; the growing is His.'**
  String get soilYoursGrowingHis;

  /// No description provided for @vineyardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Plant a seed — an intention and a season — and watch what He grows. No tracking, no pressure; the vine ripens on its own clock.'**
  String get vineyardEmptyBody;

  /// No description provided for @enterTheVineyard.
  ///
  /// In en, this message translates to:
  /// **'Enter the Vineyard'**
  String get enterTheVineyard;

  /// No description provided for @yourIntention.
  ///
  /// In en, this message translates to:
  /// **'Your intention'**
  String get yourIntention;

  /// No description provided for @howLong.
  ///
  /// In en, this message translates to:
  /// **'How long?'**
  String get howLong;

  /// No description provided for @vineWordOptional.
  ///
  /// In en, this message translates to:
  /// **'A word for the vine (optional)'**
  String get vineWordOptional;

  /// No description provided for @vineWordHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. patience, humility, rest'**
  String get vineWordHint;

  /// No description provided for @plantIt.
  ///
  /// In en, this message translates to:
  /// **'Plant it'**
  String get plantIt;

  /// No description provided for @plantedSnack.
  ///
  /// In en, this message translates to:
  /// **'Planted. The harvest remembers it.'**
  String get plantedSnack;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayLabel;

  /// No description provided for @daysWord.
  ///
  /// In en, this message translates to:
  /// **'Day\'s Word'**
  String get daysWord;

  /// No description provided for @oneQuestion.
  ///
  /// In en, this message translates to:
  /// **'One Question'**
  String get oneQuestion;

  /// No description provided for @answerIt.
  ///
  /// In en, this message translates to:
  /// **'Answer it'**
  String get answerIt;

  /// No description provided for @answeredTapToRead.
  ///
  /// In en, this message translates to:
  /// **'Answered — tap to read'**
  String get answeredTapToRead;

  /// No description provided for @writeYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Write your answer...'**
  String get writeYourAnswer;

  /// No description provided for @weatherOfTheHeart.
  ///
  /// In en, this message translates to:
  /// **'Weather of the Heart'**
  String get weatherOfTheHeart;

  /// No description provided for @theSeason.
  ///
  /// In en, this message translates to:
  /// **'The Season'**
  String get theSeason;

  /// No description provided for @yourFruit.
  ///
  /// In en, this message translates to:
  /// **'Your Fruit'**
  String get yourFruit;

  /// No description provided for @vineRemembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No fruit yet — the vine remembers every answer you plant.'**
  String get vineRemembersEmpty;

  /// No description provided for @harvestGathered.
  ///
  /// In en, this message translates to:
  /// **'The harvest is gathered.'**
  String get harvestGathered;

  /// No description provided for @harvestGatheredBody.
  ///
  /// In en, this message translates to:
  /// **'Every answer you planted is remembered. When you are ready, plant again — or keep abiding.'**
  String get harvestGatheredBody;

  /// No description provided for @plantAgain.
  ///
  /// In en, this message translates to:
  /// **'Plant again'**
  String get plantAgain;

  /// No description provided for @harvestWhenReady.
  ///
  /// In en, this message translates to:
  /// **'The harvest — when you are ready'**
  String get harvestWhenReady;

  /// No description provided for @theHarvest.
  ///
  /// In en, this message translates to:
  /// **'The Harvest'**
  String get theHarvest;

  /// No description provided for @continueAbiding.
  ///
  /// In en, this message translates to:
  /// **'Continue abiding'**
  String get continueAbiding;

  /// No description provided for @harvestVerb.
  ///
  /// In en, this message translates to:
  /// **'Harvest'**
  String get harvestVerb;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @vineyardVisits.
  ///
  /// In en, this message translates to:
  /// **'Vineyard visits'**
  String get vineyardVisits;

  /// No description provided for @vineyardVisitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle, irregular encouragement from your vine — never a nag.'**
  String get vineyardVisitsSubtitle;

  /// No description provided for @visitsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get visitsOff;

  /// No description provided for @visitsGentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle (every few days)'**
  String get visitsGentle;

  /// No description provided for @visitsAttentive.
  ///
  /// In en, this message translates to:
  /// **'Attentive (daily)'**
  String get visitsAttentive;

  /// No description provided for @visitWindow.
  ///
  /// In en, this message translates to:
  /// **'Visit window'**
  String get visitWindow;

  /// No description provided for @windowEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get windowEvening;

  /// No description provided for @windowMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get windowMorning;

  /// No description provided for @todayRhythm.
  ///
  /// In en, this message translates to:
  /// **'Today\'s rhythm'**
  String get todayRhythm;

  /// No description provided for @abiding.
  ///
  /// In en, this message translates to:
  /// **'Abiding'**
  String get abiding;

  /// No description provided for @stepsOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} steps'**
  String stepsOf(Object done, Object total);

  /// No description provided for @theSeasonChanged.
  ///
  /// In en, this message translates to:
  /// **'The season changed — the vine grows on God\'s clock.'**
  String get theSeasonChanged;

  /// No description provided for @streakFlameGrace.
  ///
  /// In en, this message translates to:
  /// **'Carried today by grace.'**
  String get streakFlameGrace;

  /// No description provided for @streakFlameGentle.
  ///
  /// In en, this message translates to:
  /// **'Kept gently, day by day.'**
  String get streakFlameGentle;

  /// No description provided for @freezeChip.
  ///
  /// In en, this message translates to:
  /// **'grace-carry'**
  String get freezeChip;

  /// No description provided for @tourVine.
  ///
  /// In en, this message translates to:
  /// **'This is your vine.'**
  String get tourVine;

  /// No description provided for @tourGrows.
  ///
  /// In en, this message translates to:
  /// **'It grows as you live — quietly, on God\'s clock.'**
  String get tourGrows;

  /// No description provided for @tourMood.
  ///
  /// In en, this message translates to:
  /// **'How is your heart today? Look below.'**
  String get tourMood;

  /// No description provided for @gardenWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'The garden kept a quiet vigil while you were away.'**
  String get gardenWelcomeBack;

  /// No description provided for @gardenRevived.
  ///
  /// In en, this message translates to:
  /// **'Welcome back — the vine drank deep of your presence.'**
  String get gardenRevived;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @readyToGrow.
  ///
  /// In en, this message translates to:
  /// **'Ready to grow!'**
  String get readyToGrow;

  /// No description provided for @joinTelegram.
  ///
  /// In en, this message translates to:
  /// **'Join our community on Telegram'**
  String get joinTelegram;

  /// No description provided for @summerDayCount.
  ///
  /// In en, this message translates to:
  /// **'Day {elapsed} of {total} · {left} left'**
  String summerDayCount(Object elapsed, Object left, Object total);

  /// No description provided for @addFirstHabit.
  ///
  /// In en, this message translates to:
  /// **'Add your first habit to start tracking!'**
  String get addFirstHabit;

  /// No description provided for @habitName.
  ///
  /// In en, this message translates to:
  /// **'Habit name'**
  String get habitName;

  /// No description provided for @newHabit.
  ///
  /// In en, this message translates to:
  /// **'New Habit'**
  String get newHabit;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day {count} Streak'**
  String dayStreak(Object count);

  /// No description provided for @xpAndLevel.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP · Level {level}'**
  String xpAndLevel(Object level, Object xp);

  /// No description provided for @deleteHabitTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteHabitTitle(Object name);

  /// No description provided for @deleteHabitBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove the habit and all its completion history.'**
  String get deleteHabitBody;

  /// No description provided for @habitCategorySpiritual.
  ///
  /// In en, this message translates to:
  /// **'Spiritual'**
  String get habitCategorySpiritual;

  /// No description provided for @habitCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get habitCategoryHealth;

  /// No description provided for @habitCategoryStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get habitCategoryStudy;

  /// No description provided for @habitCategoryProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get habitCategoryProductivity;

  /// No description provided for @loggedMinutes.
  ///
  /// In en, this message translates to:
  /// **'Logged {minutes} minutes!'**
  String loggedMinutes(Object minutes);

  /// No description provided for @skillMinGoal.
  ///
  /// In en, this message translates to:
  /// **'{category} · {minutes} min goal'**
  String skillMinGoal(Object category, Object minutes);

  /// No description provided for @deleteSkillTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteSkillTitle(Object name);

  /// No description provided for @deleteSkillBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove the skill and all session logs.'**
  String get deleteSkillBody;

  /// No description provided for @skillCategoryCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get skillCategoryCreative;

  /// No description provided for @skillCategoryWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get skillCategoryWriting;

  /// No description provided for @skillCategoryTech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get skillCategoryTech;

  /// No description provided for @skillCategoryLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get skillCategoryLanguage;

  /// No description provided for @skillCategoryWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get skillCategoryWellness;

  /// No description provided for @skillCategoryArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get skillCategoryArt;

  /// No description provided for @noGoalsOfType.
  ///
  /// In en, this message translates to:
  /// **'No {type} goals yet'**
  String noGoalsOfType(Object type);

  /// No description provided for @addFirstGoal.
  ///
  /// In en, this message translates to:
  /// **'Add your first goal!'**
  String get addFirstGoal;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @achieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved'**
  String get achieved;

  /// No description provided for @noPastGoals.
  ///
  /// In en, this message translates to:
  /// **'No past goals yet'**
  String get noPastGoals;

  /// No description provided for @deleteGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete goal?'**
  String get deleteGoalTitle;

  /// No description provided for @deleteGoalBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove \"{title}\" permanently.'**
  String deleteGoalBody(Object title);

  /// No description provided for @addTypeGoal.
  ///
  /// In en, this message translates to:
  /// **'Add {type} Goal'**
  String addTypeGoal(Object type);

  /// No description provided for @goalHint.
  ///
  /// In en, this message translates to:
  /// **'What do you want to achieve?'**
  String get goalHint;

  /// No description provided for @weeklyType.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyType;

  /// No description provided for @monthlyType.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyType;

  /// No description provided for @yearlyType.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearlyType;

  /// No description provided for @currentGoals.
  ///
  /// In en, this message translates to:
  /// **'Current goals'**
  String get currentGoals;

  /// No description provided for @pastGoals.
  ///
  /// In en, this message translates to:
  /// **'Past goals'**
  String get pastGoals;

  /// No description provided for @weekOf.
  ///
  /// In en, this message translates to:
  /// **'Week of {start} — {end}'**
  String weekOf(Object end, Object start);

  /// No description provided for @hoursTotal.
  ///
  /// In en, this message translates to:
  /// **'{hours}h total'**
  String hoursTotal(Object hours);

  /// No description provided for @loggedFamilyHours.
  ///
  /// In en, this message translates to:
  /// **'Logged {hours}h with family!'**
  String loggedFamilyHours(Object hours);

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get saved;

  /// No description provided for @saveReflection.
  ///
  /// In en, this message translates to:
  /// **'Save Reflection'**
  String get saveReflection;

  /// No description provided for @weeklyReflection.
  ///
  /// In en, this message translates to:
  /// **'Weekly Reflection'**
  String get weeklyReflection;

  /// No description provided for @weeklyCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Weekly Check-in'**
  String get weeklyCheckIn;

  /// No description provided for @reflectOnWeek.
  ///
  /// In en, this message translates to:
  /// **'Take a moment to reflect on your week'**
  String get reflectOnWeek;

  /// No description provided for @reflectionCompleteWeek.
  ///
  /// In en, this message translates to:
  /// **'Reflection complete for this week'**
  String get reflectionCompleteWeek;

  /// No description provided for @reflectionSaved.
  ///
  /// In en, this message translates to:
  /// **'Reflection saved!'**
  String get reflectionSaved;

  /// No description provided for @qGrew.
  ///
  /// In en, this message translates to:
  /// **'What helped you grow this week?'**
  String get qGrew;

  /// No description provided for @qSlipped.
  ///
  /// In en, this message translates to:
  /// **'Where did you slip or struggle?'**
  String get qSlipped;

  /// No description provided for @qFocus.
  ///
  /// In en, this message translates to:
  /// **'What will you focus on next week?'**
  String get qFocus;

  /// No description provided for @writeThoughts.
  ///
  /// In en, this message translates to:
  /// **'Write your thoughts...'**
  String get writeThoughts;

  /// No description provided for @prayerXpEarned.
  ///
  /// In en, this message translates to:
  /// **'+15 XP — Prayer logged!'**
  String get prayerXpEarned;

  /// No description provided for @daysConsistent.
  ///
  /// In en, this message translates to:
  /// **'{count} days consistent'**
  String daysConsistent(Object count);

  /// No description provided for @freezeChips.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{❄️ 1 freeze} other{❄️ # freezes}}'**
  String freezeChips(num count);

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @weeklyXpTrend.
  ///
  /// In en, this message translates to:
  /// **'Weekly XP trend'**
  String get weeklyXpTrend;

  /// No description provided for @todaysFlow.
  ///
  /// In en, this message translates to:
  /// **'Today\'s flow'**
  String get todaysFlow;

  /// No description provided for @readToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s reading'**
  String get readToday;

  /// No description provided for @planOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get planOpen;

  /// No description provided for @readCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'Read today ✓'**
  String get readCompletedToday;

  /// No description provided for @readNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get readNotStarted;

  /// No description provided for @markReadingDone.
  ///
  /// In en, this message translates to:
  /// **'Mark today\'s reading done'**
  String get markReadingDone;

  /// No description provided for @readingXpEarned.
  ///
  /// In en, this message translates to:
  /// **'+20 XP — Reading completed!'**
  String get readingXpEarned;

  /// No description provided for @continueToPrayer.
  ///
  /// In en, this message translates to:
  /// **'Continue to Prayer'**
  String get continueToPrayer;

  /// No description provided for @openWord.
  ///
  /// In en, this message translates to:
  /// **'Open the Word'**
  String get openWord;

  /// No description provided for @beginPrayer.
  ///
  /// In en, this message translates to:
  /// **'Begin Prayer'**
  String get beginPrayer;

  /// No description provided for @liveItOut.
  ///
  /// In en, this message translates to:
  /// **'Live it out'**
  String get liveItOut;

  /// No description provided for @beginWithWord.
  ///
  /// In en, this message translates to:
  /// **'Begin with the Word first'**
  String get beginWithWord;

  /// No description provided for @dayStaysOpen.
  ///
  /// In en, this message translates to:
  /// **'The day stays open'**
  String get dayStaysOpen;

  /// No description provided for @toneDoneQuiet.
  ///
  /// In en, this message translates to:
  /// **'The day is yours, {name}. Keep walking.'**
  String toneDoneQuiet(Object name);

  /// No description provided for @toneDoneWarm.
  ///
  /// In en, this message translates to:
  /// **'Great start, {name}. Keep walking in it.'**
  String toneDoneWarm(Object name);

  /// No description provided for @toneDoneStill.
  ///
  /// In en, this message translates to:
  /// **'You are here, {name}. Keep walking.'**
  String toneDoneStill(Object name);

  /// No description provided for @prayWhatYouRead.
  ///
  /// In en, this message translates to:
  /// **'Pray based on what you read'**
  String get prayWhatYouRead;

  /// No description provided for @wordChallenge.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Word'**
  String get wordChallenge;

  /// No description provided for @startTodaysWord.
  ///
  /// In en, this message translates to:
  /// **'Start Today\'s Word'**
  String get startTodaysWord;

  /// No description provided for @seeAndHear.
  ///
  /// In en, this message translates to:
  /// **'See & Hear'**
  String get seeAndHear;

  /// No description provided for @buildTheVerse.
  ///
  /// In en, this message translates to:
  /// **'Build the Verse'**
  String get buildTheVerse;

  /// No description provided for @prayTheVerse.
  ///
  /// In en, this message translates to:
  /// **'Pray the Verse'**
  String get prayTheVerse;

  /// No description provided for @turnVerseIntoPrayer.
  ///
  /// In en, this message translates to:
  /// **'Turn this verse into a prayer'**
  String get turnVerseIntoPrayer;

  /// No description provided for @hearTheVerse.
  ///
  /// In en, this message translates to:
  /// **'Hear the verse'**
  String get hearTheVerse;

  /// No description provided for @wordIsRooting.
  ///
  /// In en, this message translates to:
  /// **'The Word is taking root in you 🌱'**
  String get wordIsRooting;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @reviewDue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Review · 1 verse} other{Review · # verses}}'**
  String reviewDue(num count);

  /// No description provided for @memoryGarden.
  ///
  /// In en, this message translates to:
  /// **'Memory Garden'**
  String get memoryGarden;

  /// No description provided for @masteryNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get masteryNew;

  /// No description provided for @masteryGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get masteryGrowing;

  /// No description provided for @masteryRooted.
  ///
  /// In en, this message translates to:
  /// **'Rooted'**
  String get masteryRooted;

  /// No description provided for @continueWord.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueWord;

  /// No description provided for @prayerTemplateThank.
  ///
  /// In en, this message translates to:
  /// **'Thank You, Lord, for…'**
  String get prayerTemplateThank;

  /// No description provided for @prayerTemplateAsk.
  ///
  /// In en, this message translates to:
  /// **'Help me to live…'**
  String get prayerTemplateAsk;

  /// No description provided for @prayerTemplateRest.
  ///
  /// In en, this message translates to:
  /// **'I rest in You…'**
  String get prayerTemplateRest;

  /// No description provided for @makeItTodayAct.
  ///
  /// In en, this message translates to:
  /// **'Make it today\'s act'**
  String get makeItTodayAct;

  /// No description provided for @actAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to today\'s tasks ✓'**
  String get actAdded;

  /// No description provided for @challengeComplete.
  ///
  /// In en, this message translates to:
  /// **'Today\'s word is taking root'**
  String get challengeComplete;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backHome;

  /// No description provided for @memoryGardenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rooted verses yet — begin with today\'s Word'**
  String get memoryGardenEmpty;

  /// No description provided for @tapToListen.
  ///
  /// In en, this message translates to:
  /// **'Tap to listen'**
  String get tapToListen;

  /// No description provided for @enterThreshold.
  ///
  /// In en, this message translates to:
  /// **'Enter the Threshold'**
  String get enterThreshold;

  /// No description provided for @todaysThread.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Thread'**
  String get todaysThread;

  /// No description provided for @shareVerseToday.
  ///
  /// In en, this message translates to:
  /// **'Share this verse with one person today'**
  String get shareVerseToday;

  /// No description provided for @restInWord.
  ///
  /// In en, this message translates to:
  /// **'Take a quiet minute to rest in this Word'**
  String get restInWord;

  /// No description provided for @liveOutTheme.
  ///
  /// In en, this message translates to:
  /// **'Live out {word} today'**
  String liveOutTheme(Object word);

  /// No description provided for @buildPrompt.
  ///
  /// In en, this message translates to:
  /// **'Rebuild the verse below'**
  String get buildPrompt;

  /// No description provided for @checkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get checkAnswer;

  /// No description provided for @reviewDone.
  ///
  /// In en, this message translates to:
  /// **'Beautifully reviewed — it stays rooted'**
  String get reviewDone;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @prayerTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'Write your own prayer…'**
  String get prayerTemplateHint;

  /// No description provided for @savePrayer.
  ///
  /// In en, this message translates to:
  /// **'Save this prayer'**
  String get savePrayer;

  /// No description provided for @savedPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer saved ✓'**
  String get savedPrayer;

  /// No description provided for @actPrayBack.
  ///
  /// In en, this message translates to:
  /// **'Pray this verse back aloud'**
  String get actPrayBack;

  /// No description provided for @tapToPractice.
  ///
  /// In en, this message translates to:
  /// **'Tap to practice'**
  String get tapToPractice;

  /// No description provided for @wellDone.
  ///
  /// In en, this message translates to:
  /// **'Well done 🌱'**
  String get wellDone;

  /// No description provided for @hiddenInYourHeart.
  ///
  /// In en, this message translates to:
  /// **'Hiding the Word in your heart'**
  String get hiddenInYourHeart;

  /// No description provided for @phraseOf.
  ///
  /// In en, this message translates to:
  /// **'Phrase {current} of {total}'**
  String phraseOf(Object current, Object total);

  /// No description provided for @iHaveRead.
  ///
  /// In en, this message translates to:
  /// **'I have read'**
  String get iHaveRead;

  /// No description provided for @whatDidYouUnderstand.
  ///
  /// In en, this message translates to:
  /// **'What did you understand?'**
  String get whatDidYouUnderstand;

  /// No description provided for @profileLampTitle.
  ///
  /// In en, this message translates to:
  /// **'The Word I carry'**
  String get profileLampTitle;

  /// No description provided for @profileLampEmpty.
  ///
  /// In en, this message translates to:
  /// **'A lamp that keeps one Word in your pocket. It stays out of your way, and it tracks nothing.'**
  String get profileLampEmpty;

  /// No description provided for @profileLampChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a word'**
  String get profileLampChoose;

  /// No description provided for @profileLampChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get profileLampChange;

  /// No description provided for @profileLampListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get profileLampListen;

  /// No description provided for @profileLampRemove.
  ///
  /// In en, this message translates to:
  /// **'Let go of this word'**
  String get profileLampRemove;

  /// No description provided for @profileRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'A quiet home'**
  String get profileRoomTitle;

  /// No description provided for @profileAvatarColor.
  ///
  /// In en, this message translates to:
  /// **'Avatar color'**
  String get profileAvatarColor;

  /// No description provided for @profileIdentityLine.
  ///
  /// In en, this message translates to:
  /// **'A small tool for growing faithfully, one day at a time.'**
  String get profileIdentityLine;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @darkModeToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle light/dark theme'**
  String get darkModeToggle;

  /// No description provided for @sabbathRest.
  ///
  /// In en, this message translates to:
  /// **'Sabbath Rest'**
  String get sabbathRest;

  /// No description provided for @chooseRestDay.
  ///
  /// In en, this message translates to:
  /// **'Choose your rest day'**
  String get chooseRestDay;

  /// No description provided for @restDayNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set — no rest day'**
  String get restDayNotSet;

  /// No description provided for @noneRestDay.
  ///
  /// In en, this message translates to:
  /// **'None (no rest day)'**
  String get noneRestDay;

  /// No description provided for @dailyReadingReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reading reminder'**
  String get dailyReadingReminder;

  /// No description provided for @remindsToReadDaily.
  ///
  /// In en, this message translates to:
  /// **'Reminds you to read daily'**
  String get remindsToReadDaily;

  /// No description provided for @reminderSetAt.
  ///
  /// In en, this message translates to:
  /// **'Reminder set at {time}'**
  String reminderSetAt(Object time);

  /// No description provided for @commentSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Comment & Suggestions'**
  String get commentSuggestions;

  /// No description provided for @dayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySunday;

  /// No description provided for @dayNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get dayNotSet;

  /// No description provided for @sundayInParen.
  ///
  /// In en, this message translates to:
  /// **' (Sunday)'**
  String get sundayInParen;

  /// No description provided for @paletteClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic Gold'**
  String get paletteClassic;

  /// No description provided for @paletteSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia Warm'**
  String get paletteSepia;

  /// No description provided for @paletteCalmBlue.
  ///
  /// In en, this message translates to:
  /// **'Calm Blue'**
  String get paletteCalmBlue;

  /// No description provided for @paletteForestGreen.
  ///
  /// In en, this message translates to:
  /// **'Forest Green'**
  String get paletteForestGreen;

  /// No description provided for @paletteMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get paletteMidnight;

  /// No description provided for @aboutBesletTitle.
  ///
  /// In en, this message translates to:
  /// **'About Beslet'**
  String get aboutBesletTitle;

  /// No description provided for @aboutPara1.
  ///
  /// In en, this message translates to:
  /// **'Beslet (ብስለት) began as a simple tool for my friends at Arba Minch University to make the most of their summer break. Today, it serves as a daily companion for the wider Christian community.'**
  String get aboutPara1;

  /// No description provided for @aboutPara2.
  ///
  /// In en, this message translates to:
  /// **'Phones often quietly steal our days. Beslet helps you reclaim that time and build consistency in what matters most—Bible reading, prayer, discipline, growth, fellowship, skills, and family. It’s a quiet tool for intentional living.'**
  String get aboutPara2;

  /// No description provided for @aboutPara3.
  ///
  /// In en, this message translates to:
  /// **'It is also an effort to serve God through software. The vision is to continuously refine the app, publish it on the Google Play Store, and build future tools for the community.'**
  String get aboutPara3;

  /// No description provided for @aboutSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get aboutSupportTitle;

  /// No description provided for @aboutSupportBody.
  ///
  /// In en, this message translates to:
  /// **'If Beslet has blessed you, optional contributions help cover the store listing and future updates.'**
  String get aboutSupportBody;

  /// No description provided for @aboutCbeAccount.
  ///
  /// In en, this message translates to:
  /// **'CBE Account'**
  String get aboutCbeAccount;

  /// No description provided for @aboutFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get aboutFeedbackTitle;

  /// No description provided for @aboutFeedbackBody.
  ///
  /// In en, this message translates to:
  /// **'Have suggestions? Reach out on Telegram.'**
  String get aboutFeedbackBody;

  /// No description provided for @copyAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copyAccountNumber;

  /// No description provided for @accountCopied.
  ///
  /// In en, this message translates to:
  /// **'Account number copied.'**
  String get accountCopied;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(Object version);
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
