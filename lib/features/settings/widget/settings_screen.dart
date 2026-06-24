import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/progress_service.dart';
import '../../../core/services/settings_service.dart';
import '../../gameplay/data/level_service.dart';
import '../../level_map/provider/level_map_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local mirror of service state so toggles feel instant.
  late bool _musicEnabled;
  late double _volume;
  late bool _hapticsEnabled;
  late int _difficultyLevel;

  @override
  void initState() {
    super.initState();
    _musicEnabled    = AudioService.instance.musicEnabled;
    _volume          = AudioService.instance.volume;
    _hapticsEnabled  = SettingsService.instance.hapticsEnabled;
    _difficultyLevel = SettingsService.instance.difficultyLevel;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textWarm),
          onPressed: () => context.pop(),
        ),
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppColors.goldCream, AppColors.accentGold],
          ).createShader(b),
          child: Text(
            'Settings',
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── Sound & Music ──────────────────────────────────────────────────
          _SectionHeader(label: 'Sound & Music', icon: Iconsax.music),
          _Card(children: [
            _ToggleRow(
              label: 'Background Music',
              subtitle: _musicEnabled ? 'Playing' : 'Muted',
              icon: Iconsax.music_circle,
              value: _musicEnabled,
              onChanged: (v) async {
                setState(() => _musicEnabled = v);
                await AudioService.instance.setMusicEnabled(v);
              },
            ),
            if (_musicEnabled) ...[
              const _Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Iconsax.volume_high,
                            color: AppColors.accentGold, size: 18),
                        const SizedBox(width: 10),
                        Text('Music Volume',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textWarm)),
                        const Spacer(),
                        Text('${(_volume * 100).round()}%',
                            style: textTheme.bodySmall?.copyWith(
                                color: AppColors.accentGold
                                    .withValues(alpha: 0.75))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.accentGold,
                        inactiveTrackColor:
                            AppColors.accentGold.withValues(alpha: 0.18),
                        thumbColor: AppColors.accentGold,
                        overlayColor:
                            AppColors.accentGold.withValues(alpha: 0.15),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        value: _volume,
                        min: 0,
                        max: 1,
                        divisions: 20,
                        onChanged: (v) => setState(() => _volume = v),
                        onChangeEnd: (v) => AudioService.instance.setVolume(v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ]),

          const SizedBox(height: 20),

          // ── Gameplay ──────────────────────────────────────────────────────
          _SectionHeader(label: 'Gameplay', icon: Iconsax.game),
          _Card(children: [
            _ToggleRow(
              label: 'Haptic Feedback',
              subtitle: 'Vibrate on tap and mistakes',
              icon: Iconsax.mobile,
              value: _hapticsEnabled,
              onChanged: (v) async {
                setState(() => _hapticsEnabled = v);
                await SettingsService.instance.setHapticsEnabled(v);
              },
            ),
            const _Divider(),
            _DifficultyRow(
              value: _difficultyLevel,
              onChanged: (v) async {
                setState(() => _difficultyLevel = v);
                await SettingsService.instance.setDifficultyLevel(v);
                clearLevelCache();
              },
            ),
          ]),

          const SizedBox(height: 20),

          // ── Progress ──────────────────────────────────────────────────────
          _SectionHeader(label: 'Progress', icon: Iconsax.chart),
          _Card(children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE05555).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restart_alt_rounded,
                    color: Color(0xFFE05555), size: 20),
              ),
              title: Text('Reset All Progress',
                  style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFE05555),
                      fontWeight: FontWeight.w600)),
              subtitle: Text('Stars, unlocked levels, daily streak',
                  style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textWarm.withValues(alpha: 0.45))),
              trailing: const Icon(Iconsax.arrow_right_3,
                  color: Color(0xFFE05555), size: 16),
              onTap: () => _confirmReset(context),
            ),
          ]),

          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(label: 'About', icon: Iconsax.info_circle),
          _Card(children: [
            _InfoRow(label: 'Version', value: '1.0.0'),
            const _Divider(),
            _TapRow(
              icon: Iconsax.star,
              label: 'Rate the App',
              onTap: () => _comingSoon(context, 'Rate the App'),
            ),
            const _Divider(),
            _TapRow(
              icon: Iconsax.shield_tick,
              label: 'Privacy Policy',
              onTap: () => context.push('/privacy-policy'),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.boardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset All Progress?',
            style: TextStyle(color: AppColors.goldCream)),
        content: const Text(
          'This will erase all your stars, unlocked levels, and daily streak. '
          'This cannot be undone.',
          style: TextStyle(color: AppColors.textWarm),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: AppColors.textWarm.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset',
                style: TextStyle(
                    color: Color(0xFFE05555), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ProgressService.instance.resetProgress();
      if (context.mounted) {
        // Rebuild level map state if cubit is in context.
        try {
          context.read<LevelMapCubit>().reload();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress reset. Starting fresh!'),
            backgroundColor: Color(0xFF37474F),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!'),
        backgroundColor: AppColors.boardSurface,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ============================================================================
// Reusable sub-widgets
// ============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentGold.withValues(alpha: 0.7), size: 15),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.accentGold.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.boardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.12), width: 1),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        indent: 16,
        endIndent: 16,
        color: AppColors.accentGold.withValues(alpha: 0.08),
      );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.accentGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.accentGold, size: 20),
      ),
      title: Text(label,
          style: textTheme.bodyMedium
              ?.copyWith(color: AppColors.textWarm, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: textTheme.bodySmall?.copyWith(
              color: AppColors.textWarm.withValues(alpha: 0.45))),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.accentGold,
        activeTrackColor: AppColors.accentGold.withValues(alpha: 0.3),
        inactiveTrackColor: AppColors.textWarm.withValues(alpha: 0.12),
        inactiveThumbColor: AppColors.textWarm.withValues(alpha: 0.4),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(label,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textWarm)),
      trailing: Text(value,
          style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textWarm.withValues(alpha: 0.5))),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  static const int _unlockAtLevel = 50;

  bool get _isLocked =>
      ProgressService.instance.highestUnlocked < _unlockAtLevel + 1;

  int get _levelsLeft =>
      (_unlockAtLevel + 1 - ProgressService.instance.highestUnlocked).clamp(0, _unlockAtLevel);

  String get _label {
    if (value == 1)  return 'Easy';
    if (value <= 3)  return 'Normal';
    if (value <= 5)  return 'Challenging';
    if (value <= 7)  return 'Hard';
    if (value <= 9)  return 'Expert';
    return 'Insane';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locked = _isLocked;
    final dimColor = AppColors.textWarm.withValues(alpha: locked ? 0.30 : 1.0);
    final goldDim  = AppColors.accentGold.withValues(alpha: locked ? 0.25 : 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: goldDim.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  locked ? Iconsax.lock : Iconsax.activity,
                  color: goldDim,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Puzzle Complexity',
                            style: textTheme.bodyMedium?.copyWith(
                                color: dimColor,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        if (locked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.textWarm.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.textWarm.withValues(alpha: 0.15),
                                  width: 1),
                            ),
                            child: Text(
                              '${_levelsLeft} levels left',
                              style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textWarm.withValues(alpha: 0.45),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.accentGold.withValues(alpha: 0.30),
                                  width: 1),
                            ),
                            child: Text(
                              '$value · $_label',
                              style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.accentGold,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      locked
                          ? 'Unlocks after completing level $_unlockAtLevel'
                          : 'Affects grid size and piece count',
                      style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textWarm.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Unlock progress bar (shown while locked)
          if (locked) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ProgressService.instance.highestUnlocked / (_unlockAtLevel + 1),
                backgroundColor: AppColors.textWarm.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentGold.withValues(alpha: 0.45)),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Level ${ProgressService.instance.highestUnlocked} / $_unlockAtLevel',
                  style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textWarm.withValues(alpha: 0.30),
                      fontSize: 10),
                ),
                Text(
                  'Keep playing to unlock!',
                  style: textTheme.bodySmall?.copyWith(
                      color: AppColors.accentGold.withValues(alpha: 0.40),
                      fontSize: 10),
                ),
              ],
            ),
          ] else ...[
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.accentGold,
                inactiveTrackColor: AppColors.accentGold.withValues(alpha: 0.15),
                thumbColor: AppColors.accentGold,
                overlayColor: AppColors.accentGold.withValues(alpha: 0.15),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: value.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Easy', style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textWarm.withValues(alpha: 0.3), fontSize: 10)),
                Text('Intense', style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textWarm.withValues(alpha: 0.3), fontSize: 10)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  const _TapRow({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.accentGold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: AppColors.accentGold.withValues(alpha: 0.8), size: 20),
      ),
      title: Text(label,
          style: textTheme.bodyMedium
              ?.copyWith(color: AppColors.textWarm, fontWeight: FontWeight.w500)),
      trailing: Icon(Iconsax.arrow_right_3,
          color: AppColors.textWarm.withValues(alpha: 0.3), size: 16),
      onTap: onTap,
    );
  }
}
