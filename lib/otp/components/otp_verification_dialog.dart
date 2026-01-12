import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class OTPVerificationDialog extends StatefulWidget {
  final String email;
  final String name;
  final Function(String otp) onVerify;
  final Function() onResend;

  const OTPVerificationDialog({
    Key? key,
    required this.email,
    required this.name,
    required this.onVerify,
    required this.onResend,
  }) : super(key: key);

  @override
  State<OTPVerificationDialog> createState() => _OTPVerificationDialogState();
}

class _OTPVerificationDialogState extends State<OTPVerificationDialog> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  final isVerifying = false.obs;
  final errorMessage = Rx<String?>(null);
  final resendCooldown = 0.obs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCooldown() {
    resendCooldown.value = 60; // 60 seconds cooldown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown.value > 0) {
        resendCooldown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  void _handleVerify() {
    final otp = _controllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      setState(() {
        errorMessage.value = 'Please enter the complete 6-digit code';
      });
      return;
    }

    errorMessage.value = null;
    widget.onVerify(otp);
  }

  void _handleResend() {
    if (resendCooldown.value > 0) {
      return;
    }

    // Clear all fields
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    
    errorMessage.value = null;
    widget.onResend();
    _startResendCooldown();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // All fields filled, trigger verify
        _handleVerify();
      }
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    
    // Responsive dimensions
    final dialogWidth = isMobile ? screenWidth * 0.9 : 500.0;
    final horizontalPadding = isMobile ? 20.0 : 32.0;
    final verticalPadding = isMobile ? 20.0 : 32.0;
    final otpFieldSize = isMobile ? 40.0 : 50.0;
    final otpFieldSpacing = isMobile ? 8.0 : 12.0;
    final iconSize = isMobile ? 40.0 : 48.0;
    final titleSize = isMobile ? 20.0 : 24.0;
    final bodyTextSize = isMobile ? 13.0 : 14.0;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9, // Max 90% of screen height
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_outlined,
                  color: const Color(0xFF517399),
                  size: iconSize,
                ),
              ),
              
              SizedBox(height: isMobile ? 16 : 24),
              
              // Title
              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF517399),
                ),
              ),
              
              SizedBox(height: isMobile ? 8 : 12),
              
              // Description
              Text(
                'We\'ve sent a 6-digit verification code to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: bodyTextSize,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Email
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(height: isMobile ? 20 : 32),
              
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    width: otpFieldSize,
                    height: otpFieldSize * 1.2,
                    margin: EdgeInsets.only(
                      right: index < 5 ? otpFieldSpacing : 0,
                    ),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                          borderSide: const BorderSide(
                            color: Color(0xFF517399),
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => _onChanged(value, index),
                      onTap: () {
                        // Select all text when tapping
                        _controllers[index].selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _controllers[index].text.length,
                        );
                      },
                      onSubmitted: (_) {
                        if (index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              
              SizedBox(height: isMobile ? 16 : 24),
              
              // Error Message
              Obx(() {
                if (errorMessage.value != null) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFD32F2F),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            errorMessage.value!,
                            style: TextStyle(
                              color: const Color(0xFFD32F2F),
                              fontSize: bodyTextSize - 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              
              SizedBox(height: isMobile ? 16 : 24),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: isMobile ? 45 : 50,
                child: Obx(
                  () => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF517399),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isVerifying.value ? null : _handleVerify,
                    child: isVerifying.value
                        ? SizedBox(
                            width: isMobile ? 20 : 24,
                            height: isMobile ? 20 : 24,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Verify Code',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              
              SizedBox(height: isMobile ? 12 : 16),
              
              // Resend Code
              Obx(() {
                if (resendCooldown.value > 0) {
                  return Text(
                    'Resend code in ${resendCooldown.value}s',
                    style: TextStyle(
                      fontSize: bodyTextSize,
                      color: Colors.grey[600],
                    ),
                  );
                }
                
                return TextButton(
                  onPressed: _handleResend,
                  child: Text(
                    'Didn\'t receive the code? Resend',
                    style: TextStyle(
                      fontSize: bodyTextSize,
                      color: const Color(0xFF517399),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
              
              SizedBox(height: isMobile ? 4 : 8),
              
              // Cancel Button
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}