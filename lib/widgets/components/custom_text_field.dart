import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String? hint;
  final String? labelText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final bool readOnly;
  final bool isPassword;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final void Function()? onFocus;
  final void Function()? onBlur;
  final String? Function(String?)? validator;
  final bool enabled;
  final Color? borderColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? errorColor;
  final Color? successColor;
  final Color? backgroundColor;
  final Widget? prefixIcon; // <-- added prefixIcon support
  final int? maxLength;
  final FocusNode? focusNode;
  final bool isDense;
  final EdgeInsetsGeometry? contentPadding;

  const CustomTextField({
    Key? key,
    this.hint,
    this.labelText,
    this.controller,
    this.readOnly = false,
    this.isPassword = false,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onFocus,
    this.onBlur,
    this.validator,
    this.enabled = true,
    this.borderColor,
    this.textColor,
    this.hintColor,
    this.errorColor,
    this.successColor,
    this.backgroundColor,
    this.keyboardType,
    this.prefixIcon,
    this.maxLength,
    this.focusNode,
    this.isDense = false,
    this.contentPadding,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.isPassword;

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.onFocus?.call();
      } else {
        widget.onBlur?.call();
      }
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = theme.colorScheme.onSurfaceVariant;
    final textColor = widget.textColor ??
        (isDark
            ? (widget.hintColor ?? muted)
            : Colors.black);
    final hintColor = widget.hintColor ?? muted;
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(
          color: textColor,
          fontSize: widget.isDense ? 12 : null,
        ),
        hintText: widget.hint,
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        isDense: widget.isDense,
        contentPadding: widget.contentPadding ??
            (widget.isDense
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
                : null),
        counterText: '',
        fillColor: widget.backgroundColor ?? Colors.transparent,
        prefixIcon: widget.prefixIcon == null && !widget.isPassword
            ? null
            : widget.prefixIcon ??
                (widget.isPassword ? const Icon(Icons.lock) : null),
        prefixIconConstraints: widget.isDense
            ? const BoxConstraints(minWidth: 28, minHeight: 28)
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.isDense ? 10 : 12),
          borderSide: BorderSide(
            color: widget.borderColor ?? theme.colorScheme.primary,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.isDense ? 10 : 12),
          borderSide: BorderSide(
            color: widget.borderColor ?? theme.colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.isDense ? 10 : 12),
          borderSide: BorderSide(
            color: widget.borderColor ?? theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.isDense ? 10 : 12),
          borderSide: BorderSide(
            color: widget.errorColor ?? theme.colorScheme.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.isDense ? 10 : 12),
          borderSide: BorderSide(
            color: widget.errorColor ?? theme.colorScheme.error,
            width: 1.5,
          ),
        ),
      ),
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      validator: widget.validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            return null;
          },
    );
  }
}
