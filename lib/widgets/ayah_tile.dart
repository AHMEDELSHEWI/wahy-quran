import 'package:flutter/material.dart';

import '../models/ayah.dart';

/// Renders a single ayah in a mushaf-like continuous style, with its
/// verse-number marker rendered as a small circular badge (ornament-style)
/// after the ayah text — matching common mushaf typography conventions.
class AyahTile extends StatelessWidget {
  final Ayah ayah;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AyahTile({
    super.key,
    required this.ayah,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: RichText(
          textDirection: TextDirection.rtl,
          text: TextSpan(
            children: [
              TextSpan(
                text: '${ayah.textUthmani} ',
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 24,
                  height: 2.0,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _toArabicNumerals(ayah.ayahNumber),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _toArabicNumerals(int number) {
    const western = '0123456789';
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    return number
        .toString()
        .split('')
        .map((c) => eastern[western.indexOf(c)])
        .join();
  }
}
