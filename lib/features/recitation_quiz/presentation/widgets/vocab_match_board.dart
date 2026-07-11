import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/vocab_match_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_button.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_haptics.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Papan untuk memasangkan kata Arab dan arti: susun semua, lalu periksa.
class VocabMatchBoard extends StatefulWidget {
  final VocabMatchQuestion question;
  final bool light;
  final ValueChanged<bool> onCompleted;

  const VocabMatchBoard({
    super.key,
    required this.question,
    required this.onCompleted,
    this.light = false,
  });

  @override
  State<VocabMatchBoard> createState() => _VocabMatchBoardState();
}

class _VocabMatchBoardState extends State<VocabMatchBoard> {
  final _player = AudioPlayer();
  late final List<int> _meaningOrder;
  final _matches = <int, int>{};
  final _confirmed = <int>{};
  final _wrongLeft = <int>{};
  final _wrongRight = <int>{};
  int? _leftPick;
  int _attempt = 0;
  int _shakeTick = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.question.pairs.fold<int>(
      17,
      (value, pair) =>
          value * 31 + pair.arabic.hashCode + pair.meaning.hashCode,
    );
    _meaningOrder = List<int>.generate(widget.question.pairs.length, (i) => i)
      ..shuffle(Random(seed));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _pickArabic(int index) {
    if (_confirmed.contains(index) || _checking) return;
    setState(() {
      if (_matches.containsKey(index)) {
        _matches.remove(index);
        if (_leftPick == index) _leftPick = null;
      } else {
        _leftPick = _leftPick == index ? null : index;
      }
    });
  }

  void _pickMeaning(int index) {
    if (_confirmed.contains(index) || _checking) return;
    setState(() {
      final pairedLeft = _leftForRight(index);
      if (pairedLeft != null) {
        _matches.remove(pairedLeft);
        if (_leftPick == pairedLeft) _leftPick = null;
        return;
      }
      if (_leftPick == null) return;
      final left = _leftPick!;
      _matches.remove(left);
      _matches[left] = index;
      _leftPick = null;
    });
  }

  int? _leftForRight(int rightIndex) {
    for (final entry in _matches.entries) {
      if (entry.value == rightIndex) return entry.key;
    }
    return null;
  }

  Future<void> _checkAll() async {
    final total = widget.question.pairs.length;
    if (_checking || _matches.length != total || _attempt >= 2) return;

    final wrongLeft = <int>{
      for (final entry in _matches.entries)
        if (entry.key != entry.value && !_confirmed.contains(entry.key))
          entry.key,
    };
    final correctLeft = <int>{
      for (final entry in _matches.entries)
        if (entry.key == entry.value) entry.key,
    };
    _attempt++;
    if (wrongLeft.isEmpty) {
      setState(() {
        _confirmed.addAll(_matches.keys);
        _checking = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (mounted) widget.onCompleted(true);
      return;
    }

    setState(() {
      _wrongLeft
        ..clear()
        ..addAll(wrongLeft);
      _wrongRight
        ..clear()
        ..addAll(wrongLeft.map((left) => _matches[left]!));
      _confirmed.addAll(correctLeft);
      _shakeTick++;
      _checking = true;
    });
    // Percobaan terakhir akan mendapat feedback dari alur penilaian induk
    // ketika callback false dikirim; jangan mainkan feedback dua kali.
    if (_attempt < 2) {
      await _player.play(AssetSource('sounds/wrong.wav'), volume: 0.45);
      QuizHaptics.wrong();
    }
    await Future<void>.delayed(const Duration(milliseconds: 560));
    if (!mounted) return;
    if (_attempt >= 2) {
      widget.onCompleted(false);
      return;
    }
    setState(() {
      _matches.removeWhere((left, _) => _wrongLeft.contains(left));
      _wrongLeft.clear();
      _wrongRight.clear();
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.light ? const Color(0xFF18303E) : Colors.white;
    final muted = widget.light ? Colors.black45 : Colors.white54;
    final neutral = widget.light
        ? const Color(0xFFEAF1F3)
        : QuizColors.nightCard;
    final border = widget.light ? const Color(0xFFB7C9CF) : Colors.white24;
    final total = widget.question.pairs.length;
    final correctCount = _confirmed.length;
    final ready = _matches.length == total;
    final remainingAttempts = 2 - _attempt;
    final checkLabel = _attempt == 0
        ? 'Periksa'
        : 'Periksa lagi ($remainingAttempts/2)';

    return Column(
      children: [
        Container(
          key: const ValueKey('vocab-match-panel'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.light ? Colors.white : QuizColors.nightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Text(
                'Ketuk pasangan yang cocok',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        for (var i = 0; i < total; i++)
                          _MatchTile(
                            key: ValueKey('arabic-$i'),
                            text: widget.question.pairs[i].arabic,
                            arabic: true,
                            pairNumber: _matches.containsKey(i) ? i + 1 : null,
                            selected: _leftPick == i || _matches.containsKey(i),
                            confirmed: _confirmed.contains(i),
                            wrong: _wrongLeft.contains(i),
                            shakeTick: _shakeTick,
                            foreground: foreground,
                            background: neutral,
                            border: border,
                            onTap: () => _pickArabic(i),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        for (final i in _meaningOrder)
                          _MatchTile(
                            key: ValueKey('meaning-$i'),
                            text: widget.question.pairs[i].meaning,
                            pairNumber: _leftForRight(i) == null
                                ? null
                                : _leftForRight(i)! + 1,
                            selected: _matches.containsValue(i),
                            confirmed: _confirmed.contains(i),
                            wrong: _wrongRight.contains(i),
                            shakeTick: _shakeTick,
                            foreground: foreground,
                            background: neutral,
                            border: border,
                            onTap: () => _pickMeaning(i),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                correctCount == total
                    ? 'Semua pasangan benar'
                    : '$correctCount/$total pasangan benar',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: QuizButton(
            key: const ValueKey('vocab-match-check-button'),
            label: checkLabel,
            icon: Icons.check_rounded,
            color: QuizColors.goldDark,
            onPressed: ready && !_checking && correctCount < total
                ? _checkAll
                : null,
          ),
        ),
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  final String text;
  final bool arabic;
  final int? pairNumber;
  final bool selected;
  final bool confirmed;
  final bool wrong;
  final int shakeTick;
  final Color foreground;
  final Color background;
  final Color border;
  final VoidCallback onTap;

  const _MatchTile({
    super.key,
    required this.text,
    this.arabic = false,
    required this.pairNumber,
    required this.selected,
    required this.confirmed,
    required this.wrong,
    required this.shakeTick,
    required this.foreground,
    required this.background,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = confirmed
        ? QuizColors.correctBright
        : wrong
        ? QuizColors.missingBright
        : selected
        ? QuizColors.gold
        : border;
    final fill = confirmed
        ? QuizColors.correctBright.withValues(alpha: 0.18)
        : wrong
        ? QuizColors.missingBright.withValues(alpha: 0.16)
        : selected
        ? QuizColors.gold.withValues(alpha: 0.16)
        : background;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TweenAnimationBuilder<double>(
        key: ValueKey('shake-$shakeTick'),
        tween: Tween(begin: wrong ? 1.0 : 0.0, end: 0.0),
        duration: const Duration(milliseconds: 340),
        curve: Curves.elasticIn,
        builder: (context, value, child) => Transform.translate(
          offset: Offset(sin(value * 22) * 8, 0),
          child: child,
        ),
        child: InkWell(
          onTap: confirmed ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent,
                width: selected || wrong || confirmed ? 2 : 1.4,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (pairNumber != null) ...[
                    Container(
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                      child: Center(
                        child: Text(
                          '$pairNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      textDirection: arabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: arabic ? 'QuranHafs' : null,
                        color: wrong
                            ? QuizColors.missingBright
                            : confirmed
                            ? QuizColors.correctBright
                            : foreground,
                        fontSize: arabic ? 20 : 13.5,
                        height: arabic ? 1.6 : 1.25,
                        fontWeight: arabic ? FontWeight.w400 : FontWeight.w800,
                      ),
                    ),
                  ),
                  if (confirmed) ...[
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: QuizColors.correctBright,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
