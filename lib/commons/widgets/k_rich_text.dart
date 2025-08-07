import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KRichText extends StatelessWidget {
  final String leadingText;
  final String trailingText;
  final FontWeight? leadingFontWeight;
  final FontWeight? trailingFontWeight;
  final Color? leadingTextColor;
  final Color? trailingTextColor;
  final TextAlign? textAlign;
  final double? leadingFontSize;
  final double? trailingFontSize;

  const KRichText({
    super.key,
    required this.leadingText,
    required this.trailingText,
    this.leadingFontWeight,
    this.trailingFontWeight,
    this.leadingTextColor,
    this.trailingTextColor,
    this.textAlign,
    this.leadingFontSize,
    this.trailingFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      text: TextSpan(
        children: [
          TextSpan(
            text: leadingText,
            style: GoogleFonts.jost(
              fontSize: leadingFontSize ?? 14,
              fontWeight: leadingFontWeight ?? FontWeight.normal,
              color: leadingTextColor ?? Colors.black,
            ),
          ),
          TextSpan(
            text: trailingText,
            style: GoogleFonts.jost(
              fontSize: trailingFontSize ?? 14,
              fontWeight: trailingFontWeight ?? FontWeight.w500,
              color: trailingTextColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}