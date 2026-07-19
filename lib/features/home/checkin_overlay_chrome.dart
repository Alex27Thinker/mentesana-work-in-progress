// Mentesana — the "home" back chip that lives at the shell level above
// the check-in field. Replaces the inline GestureDetector that used to
// live in app_shell.dart for the AppScreen.checkin case.

import 'package:flutter/material.dart';

import '../../sea_icons.dart';
import '../../theme.dart';

class CheckinOverlayChrome extends StatelessWidget {
  const CheckinOverlayChrome({
    super.key,
    required this.onHome,
  });

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: s16, left: s12),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onHome,
            child: Padding(
              padding: const EdgeInsets.all(s8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A small chevron — like a soft "back" affordance that
                  // matches the home icon in the bottom nav, but quieter
                  // so the field stays the focal point.
                  StrokeIcon(
                    SeaIcons.back,
                    size: 14,
                    color: textFaint,
                    strokeWidth: 1.3,
                  ),
                  const SizedBox(width: 6),
                  Text('home',
                      style: MenteType.eyebrow.copyWith(
                          letterSpacing: .72, color: textFaint)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
