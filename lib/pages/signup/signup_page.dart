import 'package:capstone_app/pages/signup/signup_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignUpPage extends GetView<SignUpController> {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Determine if mobile or tablet/desktop
    final isMobile = screenWidth < 600;

    // Responsive dimensions
    final containerWidth = isMobile ? screenWidth * 0.9 : 500.0;
    final containerHeight =
        isMobile ? null : 700.0; // Let it auto-size on mobile
    final fieldWidth = isMobile ? screenWidth * 0.85 : 400.0;
    final horizontalPadding = isMobile ? 16.0 : 20.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            transform: GradientRotation(2.61799),
            colors: <Color>[
              Color(0xFFf9f9f9),
              Color(0xFFd4dad6),
              Color(0xFFafbbb6),
              Color(0xFF8b9d9b),
              Color(0xFF698083),
              Color(0xFF49636f),
              Color(0xFF2c475c),
              Color(0xFF142b4e)
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              width: containerWidth,
              height: containerHeight,
              margin:
                  isMobile ? const EdgeInsets.symmetric(vertical: 20) : null,
              decoration: BoxDecoration(
                color: const Color.fromARGB(223, 255, 255, 255),
                borderRadius: isMobile ? BorderRadius.circular(10) : null,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 1,
                    blurRadius: isMobile ? 5 : 1,
                    color: Colors.grey.shade400,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Back Button
                    Padding(
                      padding: EdgeInsets.only(
                        top: isMobile ? 12 : 16,
                        left: isMobile ? 8 : 16,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_left_rounded),
                            onPressed: () {
                              controller.navigateToLogin();
                            },
                          ),
                        ],
                      ),
                    ),

                    // Logo
                    Image.asset(
                      'lib/images/PAWrtal_logo.png',
                      height: isMobile ? 40 : 50,
                      width: isMobile ? 240 : 300,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),

                    // General Error Message
                    Obx(() {
                      if (controller.generalError.value != null) {
                        return Container(
                          width: fieldWidth,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFEF5350),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFD32F2F),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  controller.generalError.value!,
                                  style: TextStyle(
                                    color: const Color(0xFFD32F2F),
                                    fontSize: isMobile ? 12 : 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Email Field
                    SizedBox(
                      width: fieldWidth,
                      child: Obx(
                        () => TextFormField(
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          maxLength: 50,
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                          decoration: InputDecoration(
                            counterText: "",
                            prefixIcon: Icon(
                              Icons.email_rounded,
                              size: isMobile ? 20 : 24,
                              color: controller.emailError.value != null
                                  ? Colors.red
                                  : null,
                            ),
                            hintText: "Email",
                            hintStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                            errorText: controller.emailError.value,
                            errorMaxLines: 2,
                            errorStyle: TextStyle(fontSize: isMobile ? 11 : 12),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: isMobile ? 12 : 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: controller.emailError.value != null
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: controller.emailError.value != null
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: controller.emailError.value != null
                                    ? Colors.red
                                    : const Color.fromARGB(255, 81, 115, 153),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Colors.red,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),

                    // Name Field
                    SizedBox(
                      width: fieldWidth,
                      child: Obx(
                        () => TextFormField(
                          controller: controller.nameController,
                          keyboardType: TextInputType.name,
                          maxLength: 50,
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                          decoration: InputDecoration(
                            counterText: "",
                            prefixIcon: Icon(
                              Icons.person_rounded,
                              size: isMobile ? 20 : 24,
                              color: controller.nameError.value != null
                                  ? Colors.red
                                  : null,
                            ),
                            hintText: "Full Name",
                            hintStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                            errorText: controller.nameError.value,
                            errorMaxLines: 2,
                            errorStyle: TextStyle(fontSize: isMobile ? 11 : 12),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: isMobile ? 12 : 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: controller.nameError.value != null
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: controller.nameError.value != null
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: controller.nameError.value != null
                                    ? Colors.red
                                    : const Color.fromARGB(255, 81, 115, 153),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Colors.red,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),

                    // Password Field
                    SizedBox(
                      width: fieldWidth,
                      child: Obx(
                        () => TextFormField(
                          controller: controller.passwordController,
                          maxLength: 50,
                          obscureText: !controller.isPasswordVisible.value,
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                          decoration: InputDecoration(
                            counterText: "",
                            prefixIcon: Icon(
                              Icons.lock_rounded,
                              size: isMobile ? 20 : 24,
                              color: controller.passwordError.value != null
                                  ? Colors.red
                                  : null,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isPasswordVisible.value
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: isMobile ? 20 : 24,
                              ),
                              onPressed: controller.togglePasswordVisibility,
                            ),
                            hintText: "Password",
                            hintStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                            errorText: controller.passwordError.value,
                            errorMaxLines: 3,
                            errorStyle: TextStyle(fontSize: isMobile ? 11 : 12),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: isMobile ? 12 : 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: controller.passwordError.value != null
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: controller.passwordError.value != null
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: controller.passwordError.value != null
                                    ? Colors.red
                                    : const Color.fromARGB(255, 81, 115, 153),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Colors.red,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),

                    // Confirm Password Field
                    SizedBox(
                      width: fieldWidth,
                      child: Obx(
                        () => TextFormField(
                          controller: controller.confirmPasswordController,
                          maxLength: 50,
                          obscureText:
                              !controller.isConfirmPasswordVisible.value,
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                          decoration: InputDecoration(
                            counterText: "",
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              size: isMobile ? 20 : 24,
                              color:
                                  controller.confirmPasswordError.value != null
                                      ? Colors.red
                                      : null,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isConfirmPasswordVisible.value
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: isMobile ? 20 : 24,
                              ),
                              onPressed:
                                  controller.toggleConfirmPasswordVisibility,
                            ),
                            hintText: "Confirm Password",
                            hintStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                            errorText: controller.confirmPasswordError.value,
                            errorMaxLines: 2,
                            errorStyle: TextStyle(fontSize: isMobile ? 11 : 12),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: isMobile ? 12 : 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: controller.confirmPasswordError.value !=
                                        null
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: controller.confirmPasswordError.value !=
                                        null
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: controller.confirmPasswordError.value !=
                                        null
                                    ? Colors.red
                                    : const Color.fromARGB(255, 81, 115, 153),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Colors.red,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),

                    // Terms and Conditions Checkbox
                    SizedBox(
                      width: fieldWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => Row(
                                children: [
                                  Checkbox(
                                    value: controller.termsAccepted.value,
                                    onChanged: (value) {
                                      controller.termsAccepted.value =
                                          value ?? false;
                                      controller.termsError.value = null;
                                    },
                                    activeColor:
                                        const Color.fromARGB(255, 81, 115, 153),
                                    side: BorderSide(
                                      color: controller.termsError.value != null
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: controller.termsError.value !=
                                                  null
                                              ? Colors.red
                                              : Colors.black87,
                                          fontSize: isMobile ? 12 : 13,
                                        ),
                                        children: [
                                          const TextSpan(
                                              text: "I agree to the "),
                                          TextSpan(
                                            text: "Terms and Conditions",
                                            style: const TextStyle(
                                              color: Color.fromARGB(
                                                  255, 81, 115, 153),
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                controller
                                                    .showTermsAndConditions();
                                              },
                                          ),
                                          const TextSpan(text: " and "),
                                          TextSpan(
                                            text: "Privacy Policy",
                                            style: const TextStyle(
                                              color: Color.fromARGB(
                                                  255, 81, 115, 153),
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                controller.showPrivacyPolicy();
                                              },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                          Obx(() {
                            if (controller.termsError.value != null) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(left: 12, top: 4),
                                child: Text(
                                  controller.termsError.value!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: isMobile ? 11 : 12,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),

                    // Sign Up Button
                    SizedBox(
                      width: fieldWidth,
                      height: isMobile ? 45 : 50,
                      child: Obx(
                        () => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 81, 115, 153),
                          ),
                          onPressed: controller.isLoading.value ||
                                  controller.isGoogleLoading.value
                              ? null
                              : controller.signUp,
                          child: controller.isLoading.value
                              ? SizedBox(
                                  width: isMobile ? 20 : 24,
                                  height: isMobile ? 20 : 24,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 20,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),

                    // Sign In Link
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: isMobile ? 13 : 14,
                        ),
                        children: <TextSpan>[
                          const TextSpan(text: "Already have an account? "),
                          TextSpan(
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 81, 115, 153),
                            ),
                            text: "Sign in",
                            recognizer: TapGestureRecognizer()
                              ..onTap = controller.navigateToLogin,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),

                    // Divider
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Row(
                        children: [
                          Expanded(child: Divider(indent: isMobile ? 4 : 8)),
                          Text(
                            "  or  ",
                            style: TextStyle(fontSize: isMobile ? 12 : 14),
                          ),
                          Expanded(child: Divider(endIndent: isMobile ? 4 : 8)),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),

                    Text(
                      "Sign up with",
                      style: TextStyle(fontSize: isMobile ? 13 : 14),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),

                    // Google Sign Up Button
                    Obx(
                      () => InkWell(
                        onTap: controller.isLoading.value ||
                                controller.isGoogleLoading.value
                            ? null
                            : controller.signUpWithGoogle,
                        child: Container(
                          width: isMobile ? 45 : 50,
                          height: isMobile ? 45 : 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                isMobile ? BorderRadius.circular(8) : null,
                            boxShadow: [
                              BoxShadow(
                                spreadRadius: 1,
                                blurRadius: isMobile ? 3 : 1,
                                color: Colors.grey.shade400,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: controller.isGoogleLoading.value
                              ? Center(
                                  child: SizedBox(
                                    width: isMobile ? 20 : 24,
                                    height: isMobile ? 20 : 24,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Image.asset('lib/images/google_logo.png'),
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
