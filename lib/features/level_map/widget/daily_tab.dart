import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/daily_service.dart';
import '../provider/level_map_cubit.dart';

class DailyTab extends StatefulWidget {
  const DailyTab({super.key});

  @override
  State<DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends State<DailyTab> {
  late Timer _countdownTimer;
  Duration _timeLeft = DailyService.instance.timeUntilReset;

  // Calendar view state
  late int _calYear;
  late int _calMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calYear = now.year;
    _calMonth = now.month;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _timeLeft = DailyService.instance.timeUntilReset);
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _prevMonth() {
    setState(() {
      if (_calMonth == 1) { _calYear--; _calMonth = 12; }
      else { _calMonth--; }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    // Don't navigate past current month
    if (_calYear == now.year && _calMonth == now.month) return;
    setState(() {
      if (_calMonth == 12) { _calYear++; _calMonth = 1; }
      else { _calMonth++; }
    });
  }

  @override
  Widget build(BuildContext context) {
    final svc = DailyService.instance;
    final isCompleted = svc.isCompletedToday;
    final rewardClaimed = svc.isRewardClaimedToday;
    final streak = svc.streak;
    final best = svc.bestStreak;
    final stars = svc.todayStars;

    final now = DateTime.now();
    final isCurrentMonth = _calYear == now.year && _calMonth == now.month;
    // Top padding: status bar + top app bar height
    final topPad = MediaQuery.of(context).padding.top + kToolbarHeight + 12;
    final bottomPad = MediaQuery.of(context).padding.bottom + 84.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, topPad, 20, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          _buildHeader(context),
          const SizedBox(height: 16),

          // ── Today card FIRST — hero action, always visible ────────────
          isCompleted
              ? _CompletedCard(
                  stars: stars,
                  shapeEmoji: svc.todayShapeEmoji,
                  timeLeft: _timeLeft,
                  fmt: _fmt,
                  rewardClaimed: rewardClaimed,
                  onClaimReward: () async {
                    final claimed =
                        await context.read<LevelMapCubit>().claimDailyReward();
                    if (claimed && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎁 +1 Life added!'),
                          backgroundColor: Color(0xFF2E7D32),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      setState(() {});
                    }
                  },
                )
              : _PlayCard(
                  shapeEmoji: svc.todayShapeEmoji,
                  onPlay: () => context.push('/gameplay?daily=1'),
                ),

          const SizedBox(height: 20),

          // ── Streak cards (secondary info — below the action) ──────────
          _buildStreakRow(context, streak, best),
          const SizedBox(height: 20),

          // ── Monthly calendar (exploration content) ────────────────────
          _CalendarCard(
            year: _calYear,
            month: _calMonth,
            isCurrentMonth: isCurrentMonth,
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ).animate().fadeIn(duration: 350.ms, delay: 150.ms),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Challenge',
            style: textTheme.headlineMedium?.copyWith(
                color: AppColors.goldCream, fontWeight: FontWeight.w700))
            .animate()
            .fadeIn(duration: 300.ms)
            .moveY(begin: -8, end: 0, duration: 300.ms),
        Text(
          '${months[now.month - 1]} ${now.day}, ${now.year}',
          style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textWarm.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  Widget _buildStreakRow(BuildContext context, int streak, int best) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        // Current streak
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: streak > 0
                  ? const Color(0xFFFF6D00).withValues(alpha: 0.12)
                  : AppColors.boardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: streak > 0
                    ? const Color(0xFFFF6D00).withValues(alpha: 0.5)
                    : AppColors.accentGold.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text('Streak',
                        style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textWarm.withValues(alpha: 0.55),
                            letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  streak == 0 ? '–' : '$streak',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: streak > 0
                        ? const Color(0xFFFF6D00)
                        : AppColors.textWarm.withValues(alpha: 0.25),
                    height: 1,
                  ),
                ),
                Text(
                  streak == 0 ? 'Start today!' : streak == 1 ? 'day' : 'days',
                  style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textWarm.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).moveX(begin: -10, end: 0, duration: 350.ms),
        ),
        const SizedBox(width: 12),
        // Best streak
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.boardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.12),
                  width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Iconsax.crown_1,
                        color: AppColors.accentGold, size: 18),
                    const SizedBox(width: 6),
                    Text('Best',
                        style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textWarm.withValues(alpha: 0.55),
                            letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  best == 0 ? '–' : '$best',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: best > 0
                        ? AppColors.accentGold
                        : AppColors.textWarm.withValues(alpha: 0.25),
                    height: 1,
                  ),
                ),
                Text(
                  best == 0 ? 'No record yet' : best == 1 ? 'day' : 'days',
                  style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textWarm.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).moveX(begin: 10, end: 0, duration: 350.ms),
        ),
      ],
    );
  }
}

// ============================================================================
// Calendar card
// ============================================================================

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.year,
    required this.month,
    required this.isCurrentMonth,
    required this.onPrev,
    required this.onNext,
  });

  final int year;
  final int month;
  final bool isCurrentMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _weekLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final days = DailyService.instance.daysInMonth(year, month);

    // weekday of first day (DateTime.weekday: Mon=1, Sun=7 → we want Sun=0)
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final svc = DailyService.instance;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.boardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Column(
        children: [
          // ── Month navigation ───────────────────────────────────────────
          Row(
            children: [
              _NavBtn(icon: Iconsax.arrow_left_2, onTap: onPrev),
              Expanded(
                child: Text(
                  '${_monthNames[month - 1]} $year',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.goldCream,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _NavBtn(
                icon: Iconsax.arrow_right_3,
                onTap: isCurrentMonth ? null : onNext,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Day-of-week labels ─────────────────────────────────────────
          Row(
            children: _weekLabels
                .map((l) => Expanded(
                      child: Text(
                        l,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textWarm.withValues(alpha: 0.38),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // ── Day cells grid ─────────────────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: firstWeekday + days.length,
            itemBuilder: (_, index) {
              if (index < firstWeekday) return const SizedBox();
              final day = days[index - firstWeekday];
              final emoji = svc.shapeEmojiFor(day.date);
              return _DayCell(day: day, shapeEmoji: emoji);
            },
          ),

          // ── Legend ────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.accentGold, label: 'Completed'),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFFFF6D00), label: 'Today'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: AppColors.textWarm.withValues(alpha: 0.18),
                  label: 'Missed'),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.accentGold.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap != null
                ? AppColors.accentGold
                : AppColors.textWarm.withValues(alpha: 0.2)),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.shapeEmoji});
  final DayInfo day;
  final String shapeEmoji;

  @override
  Widget build(BuildContext context) {
    if (day.isFuture) {
      return _buildCell(
        child: Text('${day.date.day}',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textWarm.withValues(alpha: 0.2),
                fontWeight: FontWeight.w500)),
        bg: Colors.transparent,
        border: Colors.transparent,
      );
    }

    if (day.isToday) {
      return _buildCell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(shapeEmoji, style: const TextStyle(fontSize: 10)),
            Text('${day.date.day}',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFF6D00),
                    fontWeight: FontWeight.w800,
                    height: 1.1)),
          ],
        ),
        bg: const Color(0xFFFF6D00).withValues(alpha: 0.13),
        border: const Color(0xFFFF6D00).withValues(alpha: 0.7),
        glowColor: const Color(0xFFFF6D00),
      );
    }

    if (day.isCompleted) {
      return _buildCell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(shapeEmoji, style: const TextStyle(fontSize: 10)),
            Text('${day.date.day}',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.w700,
                    height: 1.1)),
          ],
        ),
        bg: AppColors.accentGold.withValues(alpha: 0.15),
        border: AppColors.accentGold.withValues(alpha: 0.55),
        glowColor: AppColors.accentGold,
      );
    }

    // Past, not completed
    return _buildCell(
      child: Text('${day.date.day}',
          style: TextStyle(
              fontSize: 12,
              color: AppColors.textWarm.withValues(alpha: 0.28),
              fontWeight: FontWeight.w400)),
      bg: Colors.transparent,
      border: AppColors.textWarm.withValues(alpha: 0.08),
    );
  }

  Widget _buildCell({
    required Widget child,
    required Color bg,
    required Color border,
    Color? glowColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border != Colors.transparent
            ? Border.all(color: border, width: 1.5)
            : null,
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                    color: glowColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: 1)
              ]
            : null,
      ),
      child: Center(child: child),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: AppColors.textWarm.withValues(alpha: 0.4),
                fontSize: 10)),
      ],
    );
  }
}

// ============================================================================
// Play / Completed cards
// ============================================================================

class _PlayCard extends StatelessWidget {
  const _PlayCard({required this.onPlay, required this.shapeEmoji});
  final VoidCallback onPlay;
  final String shapeEmoji;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGold.withValues(alpha: 0.18),
            AppColors.accentGold.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        children: [
          Text(shapeEmoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 10),
          Text("Today's Puzzle",
              style: textTheme.titleLarge?.copyWith(
                  color: AppColors.goldCream, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Shape puzzle · Daily exclusive · Complexity 500',
              style: textTheme.bodySmall
                  ?.copyWith(color: AppColors.textWarm.withValues(alpha: 0.5))),
          const SizedBox(height: 22),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Play Now',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.boardSurface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .moveY(begin: 12, end: 0, duration: 400.ms, delay: 200.ms);
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({
    required this.stars,
    required this.shapeEmoji,
    required this.timeLeft,
    required this.fmt,
    required this.rewardClaimed,
    required this.onClaimReward,
  });

  final int stars;
  final String shapeEmoji;
  final Duration timeLeft;
  final String Function(Duration) fmt;
  final bool rewardClaimed;
  final VoidCallback onClaimReward;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.boardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(shapeEmoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.tick_circle,
                    color: Color(0xFF66BB6A), size: 16),
                SizedBox(width: 6),
                Text('Completed!',
                    style: TextStyle(
                        color: Color(0xFF66BB6A),
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i < stars ? Iconsax.star_1 : Iconsax.star,
                  color: i < stars
                      ? AppColors.accentGold
                      : AppColors.textWarm.withValues(alpha: 0.18),
                  size: 34,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          if (!rewardClaimed)
            GestureDetector(
              onTap: onClaimReward,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF6D00), Color(0xFFFFB300)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFFF6D00).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🎁', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 10),
                    Text('Claim +1 Life',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ],
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.heart,
                    color: const Color(0xFFE05555).withValues(alpha: 0.7),
                    size: 16),
                const SizedBox(width: 6),
                Text('Life reward claimed',
                    style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textWarm.withValues(alpha: 0.45))),
              ],
            ),
          const SizedBox(height: 20),
          Text('Next puzzle in',
              style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textWarm.withValues(alpha: 0.4))),
          const SizedBox(height: 4),
          Text(fmt(timeLeft),
              style: textTheme.titleLarge?.copyWith(
                  color: AppColors.goldCream,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .moveY(begin: 12, end: 0, duration: 400.ms, delay: 200.ms);
  }
}
