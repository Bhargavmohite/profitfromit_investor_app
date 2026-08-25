import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';

class CommonTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? leadingIcon;
  final String? hintText;
  final bool obscureText;
  final int maxLines;
  final TextAlign textAlign;
  final TextStyle? textStyle;
  final bool showClearButton;

  const CommonTextFormField({
    super.key,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.inputFormatters,
    this.leadingIcon,
    this.hintText,
    this.obscureText = false,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.textStyle,
    this.showClearButton = true,
  });

  @override
  State<CommonTextFormField> createState() => _CommonTextFormFieldState();
}

class _CommonTextFormFieldState extends State<CommonTextFormField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  void _refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      inputFormatters: widget.inputFormatters,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      textAlign: widget.textAlign,
      style: widget.textStyle ?? const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hintText,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        prefixIcon: widget.leadingIcon != null ? Padding(padding: const EdgeInsets.only(right: 6), child: widget.leadingIcon) : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),

        // Clear button
        suffixIcon: widget.showClearButton && widget.controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  widget.controller.clear();
                  if (widget.onChanged != null) {
                    widget.onChanged!("");
                  }
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: AppColor.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                  child: Icon(Icons.close, size: 18),
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }
}
