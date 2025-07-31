// lib/components/woosong_input_field.dart - 개선된 버전
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WoosongInputField extends StatefulWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final String? hint;
  final TextInputType? keyboardType;
  final bool enabled; // 활성화/비활성화 옵션 추가
  final Function(String)? onSubmitted; // Enter 키 처리 추가
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters; // 입력 포맷터 추가

  const WoosongInputField({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.hint,
    this.keyboardType,
    this.enabled = true,
    this.onSubmitted,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  State<WoosongInputField> createState() => _WoosongInputFieldState();
}

class _WoosongInputFieldState extends State<WoosongInputField> {
  bool isFocused = false;
  bool isObscured = true;

  @override
  void initState() {
    super.initState();
    isObscured = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.enabled 
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Focus(
            onFocusChange: (focus) => setState(() => isFocused = focus),
            child: Container(
              decoration: BoxDecoration(
                color: widget.enabled ? Colors.white : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !widget.enabled
                      ? const Color(0xFFE2E8F0)
                      : isFocused
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFE2E8F0),
                  width: isFocused && widget.enabled ? 2 : 1,
                ),
                boxShadow: [
                  if (isFocused && widget.enabled)
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: !widget.enabled
                          ? const Color(0xFF94A3B8)
                          : isFocused
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF64748B),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        obscureText: isObscured,
                        enabled: widget.enabled,
                        keyboardType: widget.keyboardType,
                        maxLines: widget.maxLines,
                        onSubmitted: widget.onSubmitted,
                        inputFormatters: widget.inputFormatters,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: widget.enabled 
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF94A3B8),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: widget.hint ?? widget.label,
                          hintStyle: TextStyle(
                            color: widget.enabled 
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    if (widget.isPassword)
                      GestureDetector(
                        onTap: widget.enabled 
                            ? () => setState(() => isObscured = !isObscured)
                            : null,
                        child: Icon(
                          isObscured ? Icons.visibility_off : Icons.visibility,
                          color: widget.enabled 
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}