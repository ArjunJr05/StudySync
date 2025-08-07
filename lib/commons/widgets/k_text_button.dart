import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KTextBtn extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;
  final TextAlign? textAlign;
  final EdgeInsetsGeometry? padding;

  const KTextBtn({
    super.key,
    required this.text,
    required this.onPressed,
    this.fontSize,
    this.fontWeight,
    this.textColor,
    this.textAlign,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: padding ?? EdgeInsets.zero,
        foregroundColor: textColor, // required for splash color
      ),
      child: Text(
        text,
        textAlign: textAlign ?? TextAlign.start,
        style: GoogleFonts.jost(
          fontSize: fontSize ?? 14.0,
          fontWeight: fontWeight ?? FontWeight.w500,
          color: textColor ?? Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}