import 'dart:math';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/visiting_card/widget/share_button.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

const double _kH = 215.0;
const double _kR = 14.0;

class AllPersonalVisitingCards extends StatelessWidget {
  final PersonalProfileDetailsModel? personalDetails;
  const AllPersonalVisitingCards({super.key, required this.personalDetails});

  @override
  Widget build(BuildContext context) {
    final u = personalDetails?.user;
    return Scaffold(
      appBar: CommonBackAppBar(title: 'Visiting Cards'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // --- Decent / Professional ---
          _SlateDark(u: u),
          const SizedBox(height: 20),
          _NavyProfessional(u: u),
          const SizedBox(height: 20),
          _WarmCream(u: u),
          const SizedBox(height: 20),
          _StoneMinimal(u: u),
          const SizedBox(height: 20),
          _ForestMatte(u: u),
          const SizedBox(height: 20),
          // --- Cinematic / Bold ---
          _GlassCard(u: u),
          const SizedBox(height: 20),
          _GoldLuxury(u: u),
          const SizedBox(height: 20),
          _BoldGradient(u: u),
          const SizedBox(height: 20),
          _NeonCyber(u: u),
          const SizedBox(height: 20),
          _SunsetAura(u: u),
          SizedBox(height: SizeConfig.size60),
        ],
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

Widget _avatar(String? url, String? name,
    {double r = 26, Color bg = const Color(0xFF2A2A3A), Color border = Colors.white24}) {
  final letters = (name ?? '').trim().split(' ').where((s) => s.isNotEmpty).take(2).map((s) => s[0].toUpperCase()).join();
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: border, width: 1.5),
    ),
    child: CircleAvatar(
      radius: r,
      backgroundColor: bg,
      backgroundImage: (url != null && url.isNotEmpty) ? CachedNetworkImageProvider(url) : null,
      child: (url == null || url.isEmpty)
          ? Text(letters.isEmpty ? '?' : letters,
              style: TextStyle(color: Colors.white60, fontSize: r * 0.65, fontWeight: FontWeight.w600, letterSpacing: 1))
          : null,
    ),
  );
}

Widget _info(IconData ic, String? t, {Color c = Colors.white54, Color ic2 = Colors.white30}) {
  if (t == null || t.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(children: [
      Icon(ic, size: 11, color: ic2),
      const SizedBox(width: 6),
      Expanded(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10.5, color: c, height: 1.2, letterSpacing: 0.15))),
    ]),
  );
}

String _addr(User? u) => u?.address ?? u?.location ?? '';

// ============================================================
// 1 — SLATE DARK (charcoal + gold accent)
// ============================================================
class _SlateDark extends StatelessWidget {
  final User? u;
  final _k = GlobalKey();
  _SlateDark({required this.u});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1A1A2E);
    const gold = Color(0xFFBFA76A);
    const text = Color(0xFFF0EDE6);
    const sub = Color(0xFF9B978F);

    return Stack(children: [
      RepaintBoundary(key: _k, child: Container(
        height: _kH, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(_kR),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Row(children: [
          _avatar(u?.profileImage, u?.name, r: 28, bg: const Color(0xFF252540), border: gold.withValues(alpha: 0.3)),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(u?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: text, letterSpacing: 0.3)),
            if ((u?.designation ?? '').isNotEmpty) ...[const SizedBox(height: 3),
              Text(u!.designation!.toUpperCase(), style: TextStyle(fontSize: 9, color: gold.withValues(alpha: 0.8), letterSpacing: 2, fontWeight: FontWeight.w500))],
            const SizedBox(height: 12),
            Container(height: 0.5, width: 36, color: gold.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            _info(Icons.phone_outlined, u?.contactNo, c: sub, ic2: gold.withValues(alpha: 0.5)),
            _info(Icons.email_outlined, u?.email, c: sub, ic2: gold.withValues(alpha: 0.5)),
            _info(Icons.location_on_outlined, _addr(u), c: sub, ic2: gold.withValues(alpha: 0.5)),
          ])),
        ]),
      )),
      VisitingCardShareButton(cardKey: _k),
    ]);
  }
}

// ============================================================
// 2 — NAVY PROFESSIONAL (deep navy + silver bar)
// ============================================================
class _NavyProfessional extends StatelessWidget {
  final User? u;
  final _k = GlobalKey();
  _NavyProfessional({required this.u});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0D2137);
    const silver = Color(0xFFB0B8C4);
    const text = Color(0xFFE8ECF0);
    const sub = Color(0xFF7A8A9C);

    return Stack(children: [
      RepaintBoundary(key: _k, child: Container(
        height: _kH,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(_kR),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Row(children: [
          Container(width: 4, decoration: BoxDecoration(color: silver.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(_kR), bottomLeft: Radius.circular(_kR)))),
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 24, 24),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(u?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: text)),
                if ((u?.designation ?? '').isNotEmpty) ...[const SizedBox(height: 4),
                  Text(u!.designation!.toUpperCase(), style: TextStyle(fontSize: 9, color: silver.withValues(alpha: 0.7), letterSpacing: 1.5))],
                const SizedBox(height: 14),
                _info(Icons.phone_outlined, u?.contactNo, c: sub, ic2: silver.withValues(alpha: 0.4)),
                _info(Icons.email_outlined, u?.email, c: sub, ic2: silver.withValues(alpha: 0.4)),
                _info(Icons.location_on_outlined, _addr(u), c: sub, ic2: silver.withValues(alpha: 0.4)),
              ])),
              const SizedBox(width: 16),
              _avatar(u?.profileImage, u?.name, r: 26, bg: const Color(0xFF162D45), border: silver.withValues(alpha: 0.2)),
            ]))),
        ]),
      )),
      VisitingCardShareButton(cardKey: _k),
    ]);
  }
}

// ============================================================
// 3 — WARM CREAM (off-white + brown)
// ============================================================
class _WarmCream extends StatelessWidget {
  final User? u;
  final _k = GlobalKey();
  _WarmCream({required this.u});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5F0E8);
    const dark = Color(0xFF3C3228);
    const mid = Color(0xFF8A7E70);
    const accent = Color(0xFFB8A88A);

    return Stack(children: [
      RepaintBoundary(key: _k, child: Container(
        height: _kH, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(_kR),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _avatar(u?.profileImage, u?.name, r: 22, bg: const Color(0xFFE8E0D4), border: accent.withValues(alpha: 0.4)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: dark, letterSpacing: -0.2)),
              if ((u?.designation ?? '').isNotEmpty)
                Text(u!.designation!.toUpperCase(), style: const TextStyle(fontSize: 9, color: mid, letterSpacing: 1.8)),
            ])),
          ]),
          const SizedBox(height: 10),
          Container(height: 0.5, width: 28, color: accent),
          const Spacer(),
          _info(Icons.phone_outlined, u?.contactNo, c: mid, ic2: accent),
          _info(Icons.email_outlined, u?.email, c: mid, ic2: accent),
          _info(Icons.location_on_outlined, _addr(u), c: mid, ic2: accent),
        ]),
      )),
      VisitingCardShareButton(cardKey: _k),
    ]);
  }
}

// ============================================================
// 4 — STONE MINIMAL (warm grey + centered)
// ============================================================
class _StoneMinimal extends StatelessWidget {
  final User? u;
  final _k = GlobalKey();
  _StoneMinimal({required this.u});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFE8E4DF);
    const dark = Color(0xFF3A3733);
    const mid = Color(0xFF7A756E);
    const line = Color(0xFFCCC7C0);

    return Stack(children: [
      RepaintBoundary(key: _k, child: Container(
        height: _kH, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(_kR),
          border: Border.all(color: line, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _avatar(u?.profileImage, u?.name, r: 22, bg: const Color(0xFFD8D3CC), border: line),
          const SizedBox(height: 10),
          Text(u?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: dark, letterSpacing: 0.2)),
          if ((u?.designation ?? '').isNotEmpty) ...[const SizedBox(height: 3),
            Text(u!.designation!.toUpperCase(), textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: mid, letterSpacing: 1.5))],
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if ((u?.contactNo ?? '').isNotEmpty) _chip(Icons.phone_outlined, u!.contactNo!, mid, line),
            if ((u?.email ?? '').isNotEmpty) ...[const SizedBox(width: 8), _chip(Icons.email_outlined, u!.email!, mid, line)],
          ]),
        ]),
      )),
      VisitingCardShareButton(cardKey: _k),
    ]);
  }

  Widget _chip(IconData ic, String t, Color c, Color b) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(border: Border.all(color: b), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, size: 11, color: c), const SizedBox(width: 5),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 100),
          child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: c))),
      ]),
    );
  }
}

// ============================================================
// 5 — FOREST MATTE (deep green + cream)
// ============================================================
class _ForestMatte extends StatelessWidget {
  final User? u;
  final _k = GlobalKey();
  _ForestMatte({required this.u});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1E3A2F);
    const cream = Color(0xFFF0EBE0);
    const sub = Color(0xFFA8B5A0);
    const accent = Color(0xFF5C7A5E);

    return Stack(children: [
      RepaintBoundary(key: _k, child: Container(
        height: _kH, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(_kR),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 5))]),
        child: Row(children: [
          _avatar(u?.profileImage, u?.name, r: 28, bg: const Color(0xFF2A4A3A), border: accent.withValues(alpha: 0.4)),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(u?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cream, letterSpacing: 0.2)),
            if ((u?.designation ?? '').isNotEmpty) ...[const SizedBox(height: 4),
              Text(u!.designation!.toUpperCase(), style: TextStyle(fontSize: 9, color: sub.withValues(alpha: 0.8), letterSpacing: 1.8))],
            const SizedBox(height: 14),
            _info(Icons.phone_outlined, u?.contactNo, c: sub, ic2: accent),
            _info(Icons.email_outlined, u?.email, c: sub, ic2: accent),
            _info(Icons.location_on_outlined, _addr(u), c: sub, ic2: accent),
          ])),
        ]),
      )),
      VisitingCardShareButton(cardKey: _k),
    ]);
  }
}

// ============================================================
// 6 — GLASS MORPHISM (frosted glass + neon accents)
// ============================================================
class _GlassCard extends StatelessWidget {
  final User? u;
  final _k = GlobalKey();
  _GlassCard({required this.u});

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFE94560);
    return Stack(children: [
      RepaintBoundary(key: _k, child: Container(
        height: _kH,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(_kR),
          gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Stack(children: [
          Positioned(right: -20, top: -20, child: _glow(90, const Color(0xFF0F3460))),
          Positioned(left: 30, bottom: -30, child: _glow(70, pink)),
          Padding(padding: const EdgeInsets.all(22), child: Row(children: [
            _avatar(u?.profileImage, u?.name, r: 30, bg: const Color(0xFF1A1A30), border: pink.withValues(alpha: 0.4)),
            const SizedBox(width: 18),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(u?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
              if ((u?.designation ?? '').isNotEmpty) ...[const SizedBox(height: 3),
                Text(u!.designation!, style: TextStyle(fontSize: 11, color: pink.withValues(alpha: 0.9), letterSpacing: 0.5))],
              const SizedBox(height: 12),
              _info(Icons.phone_outlined, u?.contactNo, ic2: pink),
              _info(Icons.email_outlined, u?.email, ic2: pink),
              _info(Icons.location_on_outlined, _addr(u), ic2: pink),
            ])),
          ])),
        ]),
      )),
      VisitingCardShareButton(cardKey: _k),
    ]);
  }

  Widget _glow(double s, Color c) => Container(width: s, height: s,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.3),
      boxShadow: [BoxShadow(color: c.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 10)]));
}

// ============================================================
// 7 — GOLD LUXURY (black + gold foil + triangles)
// ============================================================
class _GoldLuxury extends StatelessWidget {
  final User? u;
  final _k = GlobalKey();
  _GoldLuxury({required this.u});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const goldL = Color(0xFFFFD700);

    return Stack(children: [
      RepaintBoundary(key: _k, child: Container(
        height: _kH,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(_kR), color: const Color(0xFF080808),
          border: Border.all(color: gold.withValues(alpha: 0.2), width: 0.5)),
        child: Stack(children: [
          Positioned(top: 0, right: 0, child: CustomPaint(size: const Size(60, 60), painter: _TriPainter(gold.withValues(alpha: 0.12)))),
          Positioned(bottom: 0, left: 0, child: Transform.rotate(angle: pi,
            child: CustomPaint(size: const Size(40, 40), painter: _TriPainter(gold.withValues(alpha: 0.08))))),
          Positioned(left: 22, top: 20, bottom: 20, child: Container(width: 2,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(colors: [gold.withValues(alpha: 0.0), gold, gold.withValues(alpha: 0.0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
          Padding(padding: const EdgeInsets.fromLTRB(36, 22, 22, 22), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text((u?.name ?? '').toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: goldL, letterSpacing: 3)),
              if ((u?.designation ?? '').isNotEmpty) ...[const SizedBox(height: 4),
                Text(u!.designation!, style: TextStyle(fontSize: 10, color: gold.withValues(alpha: 0.6), letterSpacing: 1.5))],
              const SizedBox(height: 14),
              _info(Icons.phone_outlined, u?.contactNo, c: Colors.white38, ic2: gold),
              _info(Icons.email_outlined, u?.email, c: Colors.white38, ic2: gold),
              _info(Icons.location_on_outlined, _addr(u), c: Colors.white38, ic2: gold),
            ])),
            const SizedBox(width: 12),
            _avatar(u?.profileImage, u?.name, r: 28, bg: const Color(0xFF151515), border: gold.withValues(alpha: 0.4)),
          ])),
        ]),
      )),
      VisitingCardShareButton(cardKey: _k),
    ]);
  }
}

// ============================================================
// 8 — BOLD GRADIENT (purple → pink + geometric)
// ============================================================
class _BoldGradient extends StatelessWidget {
  final User? u;
  final _k = GlobalKey();
  _BoldGradient({required this.u});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      RepaintBoundary(key: _k, child: Container(
        height: _kH,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(_kR),
          gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE), Color(0xFFFD79A8)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Stack(children: [
          Positioned(right: 20, top: 15, child: Transform.rotate(angle: 0.4,
            child: Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8))))),
          Positioned(right: 55, bottom: 25, child: Container(width: 30, height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
          Padding(padding: const EdgeInsets.all(22), child: Row(children: [
            _avatar(u?.profileImage, u?.name, r: 28, bg: Colors.white12, border: Colors.white30),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(u?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
              if ((u?.designation ?? '').isNotEmpty) ...[const SizedBox(height: 3),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(u!.designation!, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)))],
              const SizedBox(height: 12),
              _info(Icons.phone_outlined, u?.contactNo, c: Colors.white70, ic2: Colors.white54),
              _info(Icons.email_outlined, u?.email, c: Colors.white70, ic2: Colors.white54),
              _info(Icons.location_on_outlined, _addr(u), c: Colors.white70, ic2: Colors.white54),
            ])),
          ])),
        ]),
      )),
      VisitingCardShareButton(cardKey: _k),
    ]);
  }
}

// ============================================================
// 9 — NEON CYBER (black + green glow)
// ============================================================
class _NeonCyber extends StatelessWidget {
  final User? u;
  final _k = GlobalKey();
  _NeonCyber({required this.u});

  @override
  Widget build(BuildContext context) {
    const neon = Color(0xFF00FF87);
    return Stack(children: [
      RepaintBoundary(key: _k, child: Container(
        height: _kH,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(_kR), color: const Color(0xFF0D0D0D),
          border: Border.all(color: neon.withValues(alpha: 0.15))),
        child: Stack(children: [
          Positioned(left: 16, top: 16, child: Container(width: 50, height: 50,
            decoration: BoxDecoration(shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: neon.withValues(alpha: 0.06), blurRadius: 40, spreadRadius: 20)]))),
          Padding(padding: const EdgeInsets.all(22), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(u?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
              if ((u?.designation ?? '').isNotEmpty) ...[const SizedBox(height: 3),
                Text(u!.designation!, style: TextStyle(fontSize: 11, color: neon.withValues(alpha: 0.8), letterSpacing: 0.5))],
              const SizedBox(height: 14),
              _info(Icons.phone_outlined, u?.contactNo, ic2: neon.withValues(alpha: 0.7)),
              _info(Icons.email_outlined, u?.email, ic2: neon.withValues(alpha: 0.7)),
              _info(Icons.location_on_outlined, _addr(u), ic2: neon.withValues(alpha: 0.7)),
            ])),
            const SizedBox(width: 12),
            _avatar(u?.profileImage, u?.name, r: 26, bg: const Color(0xFF111111), border: neon.withValues(alpha: 0.3)),
          ])),
        ]),
      )),
      VisitingCardShareButton(cardKey: _k),
    ]);
  }
}

// ============================================================
// 10 — SUNSET AURA (orange → pink → purple)
// ============================================================
class _SunsetAura extends StatelessWidget {
  final User? u;
  final _k = GlobalKey();
  _SunsetAura({required this.u});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      RepaintBoundary(key: _k, child: Container(
        height: _kH,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(_kR),
          gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF3CAC), Color(0xFF784BA0)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Stack(children: [
          Positioned(right: -15, bottom: -15, child: Container(width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
          Padding(padding: const EdgeInsets.all(22), child: Row(children: [
            _avatar(u?.profileImage, u?.name, r: 28, bg: Colors.white12, border: Colors.white30),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(u?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              if ((u?.designation ?? '').isNotEmpty) ...[const SizedBox(height: 3),
                Text(u!.designation!, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)))],
              const SizedBox(height: 12),
              _info(Icons.phone_outlined, u?.contactNo, c: Colors.white.withValues(alpha: 0.85), ic2: Colors.white54),
              _info(Icons.email_outlined, u?.email, c: Colors.white.withValues(alpha: 0.85), ic2: Colors.white54),
              _info(Icons.location_on_outlined, _addr(u), c: Colors.white.withValues(alpha: 0.85), ic2: Colors.white54),
            ])),
          ])),
        ]),
      )),
      VisitingCardShareButton(cardKey: _k),
    ]);
  }
}

// ============================================================
// PAINTERS
// ============================================================
class _TriPainter extends CustomPainter {
  final Color color;
  _TriPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(Path()..moveTo(size.width, 0)..lineTo(size.width, size.height)..lineTo(0, 0)..close(), Paint()..color = color);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
