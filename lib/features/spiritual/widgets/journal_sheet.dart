import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/reading_preferences_provider.dart';

class JournalSheet extends StatefulWidget {
  final String reference;
  final String verseText;
  final String verseId;

  const JournalSheet({
    super.key,
    required this.reference,
    required this.verseText,
    required this.verseId,
  });

  @override
  State<JournalSheet> createState() => _JournalSheetState();
}

class _JournalSheetState extends State<JournalSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Timer? _pauseTimer;
  bool _loaded = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pauseTimer?.cancel();
    _save();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await ReadingPreferences.loadJournalText(widget.verseId);
    if (saved != null && mounted && !_loaded) {
      _loaded = true;
      _controller.text = saved;
    }
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
    if (_paused) setState(() => _paused = false);
    _pauseTimer?.cancel();
    _pauseTimer = Timer(const Duration(seconds: 2), _enterPrayerMode);
  }

  void _enterPrayerMode() {
    if (_controller.text.isNotEmpty && mounted) {
      setState(() => _paused = true);
    }
  }

  Future<void> _save() async {
    await ReadingPreferences.saveJournalText(widget.verseId, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) navigator.pop();
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, _paused ? 120 : 20),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.reference,
                  style: TextStyle(fontSize: 11,
                    color: c.textMuted, fontWeight: FontWeight.w500)),
                SizedBox(height: 12),
                Text(widget.verseText,
                  style: TextStyle(fontSize: 15,
                    color: c.textPrimary.withValues(alpha: 0.9),
                    height: 1.6, fontStyle: FontStyle.italic)),
                SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    maxLines: null,
                    decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: c.textPrimary.withValues(alpha: _paused ? 0.88 : 1.0),
                    height: _paused ? 2.2 : 1.7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    ),
);
  }
}
