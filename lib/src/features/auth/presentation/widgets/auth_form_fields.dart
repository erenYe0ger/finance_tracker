import 'package:flutter/material.dart';

/// Custom text form field for auth screens
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final bool autofill;
  final Iterable<String>? autofillHints;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onFieldSubmitted,
    this.autofill = false,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofill ? autofillHints : null,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }
}

/// Password field with toggle visibility
class AuthPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  const AuthPasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint = 'Enter your password',
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      prefixIcon: Icons.lock_outline,
      obscureText: _obscureText,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      suffixIcon: IconButton(
        icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _obscureText = !_obscureText),
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      ),
    );
  }
}

/// Email field with validation
class AuthEmailField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const AuthEmailField({
    super.key,
    required this.controller,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onFieldSubmitted,
  });

  static String? defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      label: 'Email',
      hint: 'Enter your email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      validator: validator ?? defaultValidator,
      onFieldSubmitted: onFieldSubmitted,
      autofill: true,
      autofillHints: const [AutofillHints.email],
    );
  }
}

/// Password field with default validation
class AuthPasswordFieldDefault extends StatelessWidget {
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const AuthPasswordFieldDefault({
    super.key,
    required this.controller,
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.onFieldSubmitted,
  });

  static String? defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 12) {
      return 'Password must be at least 12 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthPasswordField(
      controller: controller,
      textInputAction: textInputAction,
      validator: validator ?? defaultValidator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}

/// Confirm password field
class AuthConfirmPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final TextEditingController passwordController;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const AuthConfirmPasswordField({
    super.key,
    required this.controller,
    required this.passwordController,
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  State<AuthConfirmPasswordField> createState() => _AuthConfirmPasswordFieldState();
}

class _AuthConfirmPasswordFieldState extends State<AuthConfirmPasswordField> {
  bool _obscureText = true;

  String? _validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != widget.passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: widget.controller,
      label: 'Confirm Password',
      hint: 'Confirm your password',
      prefixIcon: Icons.lock_outline,
      obscureText: _obscureText,
      textInputAction: widget.textInputAction,
      validator: widget.validator ?? _validate,
      onFieldSubmitted: widget.onFieldSubmitted,
      suffixIcon: IconButton(
        icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _obscureText = !_obscureText),
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      ),
    );
  }
}