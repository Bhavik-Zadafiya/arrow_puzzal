import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.boardSurface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.accentGold.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textWarm, size: 18),
                ),
                const SizedBox(width: 4),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFD4B97A), AppColors.accentGold],
                  ).createShader(b),
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AppHeader(),
                  const SizedBox(height: 28),
                  _effectiveDate('June 24, 2025'),
                  const SizedBox(height: 28),
                  _section(
                    icon: Icons.info_outline_rounded,
                    title: '1. Introduction',
                    body:
                        'Welcome to ArrowX ("the App"), developed and maintained by Skyzen Infotech ("we", "us", or "our"). '
                        'This Privacy Policy explains how we collect, use, and protect information when you use our mobile application. '
                        'By downloading or using ArrowX, you agree to the practices described in this policy.',
                  ),
                  _section(
                    icon: Icons.extension_outlined,
                    title: '2. About the App',
                    body:
                        'ArrowX is a casual puzzle game designed for players of all ages. '
                        'The game does not contain any violent, adult, or inappropriate content. '
                        'It is a clean, family-friendly experience focused entirely on fun and mental challenge.',
                  ),
                  _section(
                    icon: Icons.storage_outlined,
                    title: '3. Information We Collect',
                    body: null,
                    bullets: [
                      _Bullet(
                        label: 'Device Information',
                        detail:
                            'We may collect non-personal device data such as operating system version and device model solely for crash reporting and app improvement.',
                      ),
                      _Bullet(
                        label: 'Game Progress',
                        detail:
                            'Level completion, star ratings, and lifeline counts are stored locally on your device using SharedPreferences. This data never leaves your device.',
                      ),
                      _Bullet(
                        label: 'No Personal Data',
                        detail:
                            'We do not collect your name, email address, phone number, location, or any other personally identifiable information.',
                      ),
                      _Bullet(
                        label: 'No Account Required',
                        detail:
                            'ArrowX does not require you to create an account or log in. You can play entirely anonymously.',
                      ),
                    ],
                  ),
                  _section(
                    icon: Icons.ads_click_outlined,
                    title: '4. Advertising',
                    body:
                        'ArrowX may display rewarded advertisements (e.g., watch an ad to earn hints or lifelines). '
                        'These ads are served by third-party ad networks. Third-party ad providers may collect '
                        'non-personal identifiers (such as an advertising ID) in accordance with their own privacy policies. '
                        'We encourage you to review the privacy policies of any third-party ad providers. '
                        'We do not share any personal information with advertisers.',
                  ),
                  _section(
                    icon: Icons.share_outlined,
                    title: '5. Data Sharing',
                    body:
                        'We do not sell, trade, rent, or otherwise transfer your information to outside parties. '
                        'All game data is stored locally on your device. '
                        'We do not transmit any gameplay data to our servers.',
                  ),
                  _section(
                    icon: Icons.child_care_outlined,
                    title: '6. Children\'s Privacy',
                    body:
                        'ArrowX is appropriate for all ages, including children. '
                        'We do not knowingly collect personal information from children under the age of 13. '
                        'Since we collect no personal information from any user, the App is safe for use by children. '
                        'Parents and guardians can allow their children to use this App with confidence.',
                  ),
                  _section(
                    icon: Icons.lock_outline_rounded,
                    title: '7. Data Security',
                    body:
                        'All game data is stored locally on your device and is not transmitted over any network by us. '
                        'We take reasonable measures to protect the information stored on your device. '
                        'However, no method of electronic storage is 100% secure, and we cannot guarantee absolute security.',
                  ),
                  _section(
                    icon: Icons.phone_android_outlined,
                    title: '8. Permissions',
                    body: null,
                    bullets: [
                      _Bullet(
                        label: 'Internet Access',
                        detail:
                            'Required only for loading rewarded advertisements. Not used to transmit personal data.',
                      ),
                      _Bullet(
                        label: 'Vibration',
                        detail:
                            'Used for optional haptic feedback during gameplay. Can be disabled in Settings.',
                      ),
                    ],
                  ),
                  _section(
                    icon: Icons.update_outlined,
                    title: '9. Changes to This Policy',
                    body:
                        'We may update this Privacy Policy from time to time. Any changes will be posted within the App. '
                        'Continued use of ArrowX after any changes constitutes your acceptance of the revised policy. '
                        'We encourage you to review this policy periodically.',
                  ),
                  _section(
                    icon: Icons.mail_outline_rounded,
                    title: '10. Contact Us',
                    body:
                        'If you have any questions or concerns about this Privacy Policy or our data practices, '
                        'please contact us:\n\n'
                        'Skyzen Infotech\n'
                        'Email: support@skyzeninfotech.com\n'
                        'Website: www.skyzeninfotech.com',
                  ),
                  const SizedBox(height: 16),
                  _divider(),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '© 2025 Skyzen Infotech. All rights reserved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppColors.textWarm.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── App header card ───────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.boardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFD4B97A), AppColors.accentGold, Color(0xFFF0D080)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(b),
            child: const Text(
              'ArrowX',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'by Skyzen Infotech',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textWarm.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accentGold.withValues(alpha: 0.30),
              ),
            ),
            child: const Text(
              'Privacy Policy',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accentGold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Effective date ────────────────────────────────────────────────────────────

Widget _effectiveDate(String date) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.boardSurface.withValues(alpha: 0.60),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: AppColors.textWarm.withValues(alpha: 0.08),
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.calendar_today_outlined,
            color: AppColors.accentGold.withValues(alpha: 0.70), size: 14),
        const SizedBox(width: 8),
        Text(
          'Effective Date: $date',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textWarm.withValues(alpha: 0.55),
          ),
        ),
      ],
    ),
  );
}

// ── Section ───────────────────────────────────────────────────────────────────

Widget _section({
  required IconData icon,
  required String title,
  String? body,
  List<_Bullet>? bullets,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.accentGold, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWarm,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (body != null)
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              height: 1.6,
              color: AppColors.textWarm.withValues(alpha: 0.70),
            ),
          ),
        if (bullets != null)
          ...bullets.map((b) => _bulletItem(b)),
      ],
    ),
  );
}

Widget _bulletItem(_Bullet b) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.accentGold,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${b.label}: ',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textWarm,
                    height: 1.6,
                  ),
                ),
                TextSpan(
                  text: b.detail,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textWarm.withValues(alpha: 0.70),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _divider() => Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.accentGold.withValues(alpha: 0.25),
            Colors.transparent,
          ],
        ),
      ),
    );

class _Bullet {
  const _Bullet({required this.label, required this.detail});
  final String label;
  final String detail;
}
