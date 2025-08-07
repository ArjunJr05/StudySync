import 'package:flutter/material.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/core/themes/app_colors.dart';

/// An enhanced autocomplete text field with a dropdown for suggestions.
class EnhancedAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final List<String> suggestions;
  final Function(String)? onSelected;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool isLoading;

  const EnhancedAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.suggestions,
    this.onSelected,
    this.validator,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  State<EnhancedAutocompleteField> createState() =>
      _EnhancedAutocompleteFieldState();
}

class _EnhancedAutocompleteFieldState extends State<EnhancedAutocompleteField>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _onTextChange(); // Show suggestions when field is focused
    } else {
      _hideSuggestions();
    }
  }

  void _onTextChange() {
    if (!_focusNode.hasFocus) return;

    final text = widget.controller.text.toUpperCase();
    setState(() {
      _filteredSuggestions = widget.suggestions
          .where((suggestion) => suggestion.toUpperCase().contains(text))
          .take(8) // Limit suggestions for better UX
          .toList();
      _showSuggestions = _filteredSuggestions.isNotEmpty;
    });

    if (_showSuggestions) {
      _animationController.forward();
    } else {
      _hideSuggestions();
    }
  }

  void _hideSuggestions() {
    if (!_showSuggestions) return;
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  void _selectSuggestion(String suggestion) {
    widget.controller.text = suggestion;
    widget.onSelected?.call(suggestion);
    _hideSuggestions();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KText(
          text: widget.label,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          textColor: Colors.grey[700],
        ),
        const KVerticalSpacer(height: 8),
        CompositedTransformTarget(
          link: LayerLink(),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            validator: widget.validator,
            enabled: widget.enabled,
            textCapitalization: TextCapitalization.words,
            decoration: _buildInputDecoration(),
          ),
        ),
        _buildSuggestionsOverlay(),
      ],
    );
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      hintText: widget.hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: widget.isLoading
          ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              ),
            )
          : Icon(
              widget.icon,
              color: widget.enabled
                  ? (_focusNode.hasFocus
                        ? AppColors.primaryColor
                        : Colors.grey[600])
                  : Colors.grey[400],
              size: 20,
            ),
      suffixIcon: widget.controller.text.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
              onPressed: () {
                widget.controller.clear();
                widget.onSelected?.call('');
                _hideSuggestions();
              },
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      filled: true,
      fillColor: widget.enabled ? Colors.grey[50] : Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSuggestionsOverlay() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return _showSuggestions
            ? FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _filteredSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _filteredSuggestions[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _selectSuggestion(suggestion),
                              child: _buildSuggestionTile(suggestion),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }

  Widget _buildSuggestionTile(String suggestion) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[100]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: AppColors.primaryColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: _buildHighlightedText(suggestion, widget.controller.text),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final richText = <TextSpan>[];
    final lowerText = text.toUpperCase();
    final lowerQuery = query.toUpperCase();
    int lastMatchEnd = 0;

    while (lastMatchEnd < text.length) {
      final startIndex = lowerText.indexOf(lowerQuery, lastMatchEnd);
      if (startIndex == -1) {
        richText.add(TextSpan(text: text.substring(lastMatchEnd)));
        break;
      }
      if (startIndex > lastMatchEnd) {
        richText.add(TextSpan(text: text.substring(lastMatchEnd, startIndex)));
      }
      final endIndex = startIndex + query.length;
      richText.add(
        TextSpan(
          text: text.substring(startIndex, endIndex),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      );
      lastMatchEnd = endIndex;
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        children: richText,
      ),
    );
  }
}
