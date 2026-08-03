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
  bool _loaded = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
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

  Future<void> _save() async {
    await ReadingPreferences.saveJournalText(widget.verseId, _controller.text);
    if (mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.reference,
                    style: TextStyle(
                        fontSize: 11,
                        color: c.textMuted,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 12),
                Text(widget.verseText,
                    style: TextStyle(
                        fontSize: 15,
                        color: c.textPrimary.withValues(alpha: 0.9),
                        height: 1.6,
                        fontStyle: FontStyle.italic)),
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
                    color: c.textPrimary,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: Icon(
                _saved ? Icons.check : Icons.save_outlined,
                size: 18,
              ),
              label: Text(_saved ? 'Saved' : 'Save'),
            ),
          ),
        ),
      ]),
    );
  }
}
