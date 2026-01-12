import 'package:capstone_app/web/pages/web_signup/web_signup_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebSignUpPage extends GetView<WebSignUpController> {
  const WebSignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Center(
          child: Container(
            width: 500,
            height: 700,
            decoration: BoxDecoration(
              color: const Color.fromARGB(223, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  spreadRadius: 1,
                  blurRadius: 1,
                  color: Colors.grey.shade400,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 16),
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
                  Image.asset(
                    'lib/images/PAWrtal_logo.png',
                    height: 50,
                    width: 300,
                  ),
                  const SizedBox(height: 16),

                  // General Error Message
                  Obx(() {
                    if (controller.generalError.value != null) {
                      return Container(
                        width: 400,
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
                                style: const TextStyle(
                                  color: Color(0xFFD32F2F),
                                  fontSize: 13,
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
                    width: 400,
                    child: Obx(
                      () => TextFormField(
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 50,
                        onFieldSubmitted: (_) {
                          if (!controller.isLoading.value &&
                              !controller.isGoogleLoading.value) {
                            controller.signUp();
                          }
                        },
                        decoration: InputDecoration(
                          counterText: "",
                          prefixIcon: Icon(
                            Icons.email_rounded,
                            color: controller.emailError.value != null
                                ? Colors.red
                                : null,
                          ),
                          hintText: "Email",
                          errorText: controller.emailError.value,
                          errorMaxLines: 2,
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
                  const SizedBox(height: 20),

                  // Name Field
                  SizedBox(
                    width: 400,
                    child: Obx(
                      () => TextFormField(
                        controller: controller.nameController,
                        keyboardType: TextInputType.name,
                        maxLength: 50,
                        onFieldSubmitted: (_) {
                          if (!controller.isLoading.value &&
                              !controller.isGoogleLoading.value) {
                            controller.signUp();
                          }
                        },
                        decoration: InputDecoration(
                          counterText: "",
                          prefixIcon: Icon(
                            Icons.person_rounded,
                            color: controller.nameError.value != null
                                ? Colors.red
                                : null,
                          ),
                          hintText: "Full Name",
                          errorText: controller.nameError.value,
                          errorMaxLines: 2,
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
                  const SizedBox(height: 20),

                  // Password Field
                  SizedBox(
                    width: 400,
                    child: Obx(
                      () => TextFormField(
                        controller: controller.passwordController,
                        maxLength: 50,
                        obscureText: !controller.isPasswordVisible.value,
                        onFieldSubmitted: (_) {
                          if (!controller.isLoading.value &&
                              !controller.isGoogleLoading.value) {
                            controller.signUp();
                          }
                        },
                        decoration: InputDecoration(
                          counterText: "",
                          prefixIcon: Icon(
                            Icons.lock_rounded,
                            color: controller.passwordError.value != null
                                ? Colors.red
                                : null,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isPasswordVisible.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                          hintText: "Password",
                          errorText: controller.passwordError.value,
                          errorMaxLines: 3,
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
                  const SizedBox(height: 20),

                  // Confirm Password Field
                  SizedBox(
                    width: 400,
                    child: Obx(
                      () => TextFormField(
                        controller: controller.confirmPasswordController,
                        maxLength: 50,
                        obscureText: !controller.isConfirmPasswordVisible.value,
                        onFieldSubmitted: (_) {
                          if (!controller.isLoading.value &&
                              !controller.isGoogleLoading.value) {
                            controller.signUp();
                          }
                        },
                        decoration: InputDecoration(
                          counterText: "",
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: controller.confirmPasswordError.value != null
                                ? Colors.red
                                : null,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isConfirmPasswordVisible.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed:
                                controller.toggleConfirmPasswordVisibility,
                          ),
                          hintText: "Confirm Password",
                          errorText: controller.confirmPasswordError.value,
                          errorMaxLines: 2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color:
                                  controller.confirmPasswordError.value != null
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color:
                                  controller.confirmPasswordError.value != null
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color:
                                  controller.confirmPasswordError.value != null
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
                  const SizedBox(height: 20),

                  // Terms and Conditions Checkbox
                  SizedBox(
                    width: 400,
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
                                        color:
                                            controller.termsError.value != null
                                                ? Colors.red
                                                : Colors.black87,
                                        fontSize: 13,
                                      ),
                                      children: [
                                        const TextSpan(text: "I agree to the "),
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
                              padding: const EdgeInsets.only(left: 12, top: 4),
                              child: Text(
                                controller.termsError.value!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign Up Button
                  SizedBox(
                    width: 400,
                    height: 50,
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
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Sign Up",
                                style: TextStyle(
                                    fontSize: 20, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign In Link
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
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
                  const SizedBox(height: 16),

                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider(indent: 8)),
                      Text("  or  "),
                      Expanded(child: Divider(endIndent: 8)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Sign up with"),
                  const SizedBox(height: 16),

                  // Google Sign Up Button
                  Obx(
                    () => InkWell(
                      onTap: controller.isLoading.value ||
                              controller.isGoogleLoading.value
                          ? null
                          : controller.signUpWithGoogle,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              spreadRadius: 1,
                              blurRadius: 1,
                              color: Colors.grey.shade400,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: controller.isGoogleLoading.value
                            ? const Center(child: CircularProgressIndicator())
                            : Image.asset('lib/images/google_logo.png'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
