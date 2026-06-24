import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

// ── Notification IDs ──────────────────────────────────────────────────────────
// Each slot has a fixed ID so rescheduling overwrites the previous one cleanly.
const _kIdInactivity  = 1;
const _kIdDaily       = 2;
const _kIdLives       = 3;
const _kIdWild        = 4; // random "wild card" messages

// ── Message banks — the more variety, the less predictable it feels ───────────

const _inactivityMessages = [
  ('Come back… 👀', 'The arrows are getting restless without you.'),
  ('Missing something?', 'Your puzzle is still unsolved. It\'s judging you.'),
  ('Hey!', 'The arrows can\'t escape without your help 🏹'),
  ('Psst…', 'Level {n} is still waiting. Are you scared? 😏'),
  ('Still here.', 'Your arrows haven\'t moved in a while. They miss you.'),
  ('Just checking in 🤔', 'You left mid-escape. The arrows are confused.'),
  ('Tap me. I dare you.', 'ArrowX misses the sound of your taps.'),
  ('It\'s been a while…', 'Did you forget about the arrows? They didn\'t forget you.'),
  ('Wake up! ⏰', 'A fresh puzzle is ready and nobody is solving it.'),
  ('Lonely arrows 😢', 'Your pieces haven\'t moved since you left. Come free them.'),
];

const _dailyMessages = [
  ('Daily puzzle is here! 🎯', 'Today\'s challenge just dropped. Can you crack it?'),
  ('New day, new puzzle ✨', 'Your daily arrow challenge is ready.'),
  ('Fresh puzzle alert 🏹', 'Today\'s arrows are waiting to be freed. Are you ready?'),
  ('Daily drop 🎲', 'Something new is waiting for you in ArrowX.'),
  ('Today\'s puzzle is live!', 'A brand new challenge just unlocked. Go solve it.'),
  ('Good morning, puzzler ☀️', 'Your daily dose of arrow madness is ready.'),
  ('Can you beat today\'s?', 'The daily puzzle is live. Clock is ticking… or is it? 😈'),
  ('Daily unlocked 🔓', 'Today\'s arrows have a mind of their own. Good luck.'),
];

const _livesFullMessages = [
  ('Full lives! ❤️', 'You\'ve got 10 lives. Time to go risk them all.'),
  ('Lives restored ✅', 'You\'re back to full power. The puzzles are waiting.'),
  ('Topped up! 🔋', 'All your lives regenerated. Don\'t waste them now.'),
  ('Ready to play? ❤️‍🔥', 'Lives are full. The arrows are restless. Go!'),
];

const _wildMessages = [
  ('Psst…', 'We added nothing new. But we knew you\'d check. 😄'),
  ('Random thought 💭', 'What if the arrow was you all along?'),
  ('Odd hours call for puzzles 🌙', 'Can\'t sleep? ArrowX has the cure.'),
  ('Challenge accepted? 🎯', 'Someone just beat your level. Or did they? Only one way to find out.'),
  ('Breaking news 📰', 'Local arrows still trapped. Help needed immediately.'),
  ('Plot twist 🌀', 'What if you\'re the arrow? Think about it.'),
  ('Productivity tip 💡', 'Studies show solving arrow puzzles makes you 100% cooler.*\n*Not a real study.'),
  ('You vs. the puzzle 🧠', 'The puzzle doesn\'t think you\'ll open this. Prove it wrong.'),
  ('Midnight madness 🌝', 'This is your sign to play ArrowX right now.'),
  ('Fun fact 📌', 'Arrows have been pointing the right way since 3000 BC. Time to join them.'),
  ('Reminder ⚡', 'The arrows. They wait. They always wait.'),
  ('Hello from the other side 👋', 'Your arrows called. They want to escape.'),
];

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _rng    = Random();
  bool _ready   = false;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Request Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _ready = true;
  }

  // ── Called every time the app opens ─────────────────────────────────────────
  // Reschedules inactivity + wild-card so the pattern stays unpredictable.

  Future<void> onAppOpen() async {
    if (!_ready) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_open_ms', DateTime.now().millisecondsSinceEpoch);

    // Cancel stale inactivity + wild — user is here, no need to nag now.
    await _plugin.cancel(_kIdInactivity);
    await _plugin.cancel(_kIdWild);

    // Reschedule them for later — random windows so they never feel robotic.
    await _scheduleInactivity();
    await _scheduleWild();
    await _scheduleDaily();
  }

  // ── Called when lifeline regen completes ────────────────────────────────────

  Future<void> scheduleLifesFull(int secondsUntilFull) async {
    if (!_ready || secondsUntilFull <= 0) return;
    await _plugin.cancel(_kIdLives);
    final msg = _pick(_livesFullMessages);
    await _scheduleAfterSeconds(_kIdLives, secondsUntilFull, msg.$1, msg.$2);
  }

  // Cancel lives notification when user opens (already full or spending).
  Future<void> cancelLivesNotification() async {
    if (!_ready) return;
    await _plugin.cancel(_kIdLives);
  }

  // ── Internal schedulers ─────────────────────────────────────────────────────

  // Inactivity: fires between 26 h and 55 h from now — never the same gap.
  Future<void> _scheduleInactivity() async {
    final hoursDelay = 26 + _rng.nextInt(30); // 26–55 hours
    // Also randomise the minute so it never arrives at the same time of day.
    final minuteOffset = _rng.nextInt(60);
    final totalSeconds = hoursDelay * 3600 + minuteOffset * 60;
    final msg = _pick(_inactivityMessages);
    await _scheduleAfterSeconds(_kIdInactivity, totalSeconds, msg.$1, msg.$2);
  }

  // Daily puzzle: fires tomorrow at a random time between 08:00 and 12:59.
  // The hour shifts each day so it never feels like a calendar event.
  Future<void> _scheduleDaily() async {
    final now      = tz.TZDateTime.now(tz.local);
    final hour     = 8 + _rng.nextInt(5);   // 8 AM – 12 PM
    final minute   = _rng.nextInt(60);
    var   scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    // If that time already passed today, fire tomorrow instead.
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final msg = _pick(_dailyMessages);
    await _scheduleAt(_kIdDaily, scheduled, msg.$1, msg.$2);
  }

  // Wild-card: completely random — fires between 4 h and 18 h from now,
  // at a random minute, on a random day within the next 3 days.
  Future<void> _scheduleWild() async {
    final hoursDelay = 4 + _rng.nextInt(67);  // 4 h – 70 h
    final minuteJitter = _rng.nextInt(60);
    final totalSeconds = hoursDelay * 3600 + minuteJitter * 60;
    final msg = _pick(_wildMessages);
    await _scheduleAfterSeconds(_kIdWild, totalSeconds, msg.$1, msg.$2);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  T _pick<T>(List<T> list) => list[_rng.nextInt(list.length)];

  Future<void> _scheduleAfterSeconds(
      int id, int seconds, String title, String body) async {
    final when = tz.TZDateTime.now(tz.local)
        .add(Duration(seconds: seconds));
    await _scheduleAt(id, when, title, body);
  }

  Future<void> _scheduleAt(
      int id, tz.TZDateTime when, String title, String body) async {
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'arrowx_main',
            'ArrowX Notifications',
            channelDescription: 'Puzzle reminders and updates',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFFC9A24B), // accentGold
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('[NotificationService] schedule error: $e');
    }
  }
}
