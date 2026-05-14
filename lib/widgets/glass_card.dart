import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kColorPrimary = Color(0xFF7986CB);
const kColorSecondary = Color(0xFF4DB6AC);
const kColorError = Color(0xFFEF5350);
const kGradientColors = [
  Color(0xFF0F0C29),
  Color(0xFF302B63),
  Color(0xFF24243E),
];

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blur;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(24),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20,
    this.blur = 14,
    this.opacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}



InputDecoration glassInputDecoration({
  required String label,
  required IconData icon,
  String? hint,
  String? suffixText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixText: suffixText,
    suffixIcon: suffixIcon,
    prefixIcon: Icon(icon, color: Colors.white54, size: 20),
    labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
    hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
    suffixStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kColorPrimary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kColorError),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kColorError, width: 1.5),
    ),
    errorStyle: GoogleFonts.inter(color: Color(0xFFEF9A9A), fontSize: 12),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}


