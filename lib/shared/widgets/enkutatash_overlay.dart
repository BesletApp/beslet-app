import 'package:flutter/material.dart';

class EnkutatashOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  const EnkutatashOverlay({super.key, required this.onDismiss});

  @override
  State<EnkutatashOverlay> createState() => _EnkutatashOverlayState();
}

class _EnkutatashOverlayState extends State<EnkutatashOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0E00),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Spacer(flex: 2),
                _header(),
                const SizedBox(height: 32),
                _verseCard('Isaiah 43:19', 'Behold, I am doing a new thing; now it springs forth, do you not perceive it? I will make a way in the wilderness and rivers in the desert.'),
                const SizedBox(height: 16),
                _verseCard('2 Corinthians 5:17', 'Therefore, if anyone is in Christ, he is a new creation. The old has passed away; behold, the new has come.'),
                const SizedBox(height: 16),
                _verseCard('Ephesians 2:10', 'For we are His workmanship, created in Christ Jesus for good works, which God prepared beforehand, that we should walk in them.'),
                const SizedBox(height: 32),
                _proverb(),
                const Spacer(flex: 2),
                _dismissButton(),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(children: [
      Text('🎉 የእንቁጣጣሽ', style: TextStyle(fontFamily: 'NotoSansEthiopic', fontSize: 14, color: const Color(0xFFE8C84A).withValues(alpha: 0.7))),
      const SizedBox(height: 8),
      Text('Enkutatash', style: const TextStyle(fontFamily: 'CormorantGaramond', fontSize: 42, fontWeight: FontWeight.w700, color: Color(0xFFE8C84A))),
      const SizedBox(height: 4),
      Text('Ethiopian New Year 2019', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: const Color(0xFFE8C84A).withValues(alpha: 0.7))),
      const SizedBox(height: 24),
      Container(
        width: 60, height: 2,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE8C84A), Color(0xFFB8860B)]),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    ]);
  }

  Widget _verseCard(String ref, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A00),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8C84A).withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ref, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFE8C84A).withValues(alpha: 0.8))),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white70, height: 1.5)),
      ]),
    );
  }

  Widget _proverb() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A00),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8C84A).withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        const Icon(Icons.auto_stories, size: 32, color: Color(0xFFE8C84A)),
        const SizedBox(height: 12),
        Text(
          'The new year is a blank book.\nYou hold the pen.\nWrite your story with faith.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'CormorantGaramond', fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFFE8C84A).withValues(alpha: 0.9), height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          'This year, may His Word guide every page.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: const Color(0xFFE8C84A).withValues(alpha: 0.5)),
        ),
      ]),
    );
  }

  Widget _dismissButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          _ctrl.reverse().then((_) => widget.onDismiss());
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE8C84A),
          side: const BorderSide(color: Color(0xFFE8C84A)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: const Text('Enter the New Year', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
