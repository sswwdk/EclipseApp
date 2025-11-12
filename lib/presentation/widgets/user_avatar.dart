import 'package:characters/characters.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final double radius;

  const UserAvatar({
    super.key,
    required this.displayName,
    this.imageUrl,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.dividerColor,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    final initial = displayName.trim().isNotEmpty
        ? displayName.characters.first.toUpperCase()
        : '?';
    final colors = _avatarColor(initial);

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.$1,
      child: Text(
        initial,
        style: TextStyle(
          color: colors.$2,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  (Color, Color) _avatarColor(String initial) {
    if (initial.isEmpty) {
      return _palettes.first;
    }
    final rune = initial.runes.first;
    final index = rune.abs() % _palettes.length;
    return _palettes[index];
  }
}

const List<(Color, Color)> _palettes = [
  (Color(0xFFFFE5E0), Color(0xFFFF6B57)),
  (Color(0xFFE3F2FD), Color(0xFF1565C0)),
  (Color(0xFFF1F8E9), Color(0xFF2E7D32)),
  (Color(0xFFEDE7F6), Color(0xFF5E35B1)),
  (Color(0xFFFFF3E0), Color(0xFFEF6C00)),
  (Color(0xFFE0F2F1), Color(0xFF00897B)),
  (Color(0xFFFFEBEE), Color(0xFFD81B60)),
  (Color(0xFFF3E5F5), Color(0xFF8E24AA)),
];

