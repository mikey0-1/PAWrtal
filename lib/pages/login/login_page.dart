import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/login/login_controller.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> resetPasswordFormKey = GlobalKey<FormState>();

  final LoginController controller =
      LoginController(Get.find<AuthRepository>());
  final AppWriteProvider appWriteProvider = AppWriteProvider();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(223, 255, 255, 255),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 1,
                    blurRadius: 5,
                    color: Colors.grey.shade400,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Form(
                key: controller.formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Welcome Section
                      const Text(
                        "WELCOME TO",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Logo
                      Image.asset(
                        "lib/images/PAWrtal_logo.png",
                        height: 80,
                        width: 200,
                      ),
                      const SizedBox(height: 32),

                      // Sign In Text
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 40),
                          child: Text(
                            "Sign In",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Error Message Display (unified for all errors)
                      Obx(() => controller.errorMessage.value.isNotEmpty
                          ? Container(
                              width: 300,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      controller.errorMessage.value,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink()),

                      // Email/Username Field (50 character limit, no format validation)
                      SizedBox(
                        width: 300,
                        child: TextFormField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_rounded),
                            hintText: "Email or Username",
                            helperStyle: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            counterText: "", // Hide the character counter
                          ),
                          keyboardType: TextInputType.text,
                          controller: controller.emailEditingController,
                          maxLength: 50, // Hard limit: 50 characters
                          textInputAction: TextInputAction.next,
                          onChanged: (value) {
                            // Clear error when user starts typing
                            if (controller.errorMessage.value.isNotEmpty) {
                              controller.errorMessage.value = '';
                            }
                          },
                          // Use the username/email validator (no format validation)
                          validator: (value) {
                            return controller.validateEmailOrUsername(value!);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Field (50 character limit)
                      SizedBox(
                        width: 300,
                        child: Obx(() => TextFormField(
                              obscureText: !controller.isPasswordVisible.value,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    controller.isPasswordVisible.value
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed:
                                      controller.togglePasswordVisibility,
                                ),
                                hintText: "Password",
                                helperStyle: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                counterText: "", // Hide the character counter
                              ),
                              keyboardType: TextInputType.visiblePassword,
                              controller: controller.passwordEditingController,
                              maxLength: 50, // Hard limit: 50 characters
                              textInputAction: TextInputAction.done,
                              onChanged: (value) {
                                // Clear error when user starts typing
                                if (controller.errorMessage.value.isNotEmpty) {
                                  controller.errorMessage.value = '';
                                }
                              },
                              onFieldSubmitted: (value) {
                                // Allow pressing Enter/Done to submit
                                controller.validateAndLogin(
                                  emailOrUsername: controller
                                      .emailEditingController.text
                                      .trim(),
                                  password: controller
                                      .passwordEditingController.text
                                      .trim(),
                                );
                              },
                              // validator: (value) {
                              //   return controller.validatePassword(value!);
                              // },
                            )),
                      ),

                      // Forgot Password
                      SizedBox(
                        width: 300,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      title: const Text("Reset Password"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            "Enter your email address and we'll send you a link to reset your password.",
                                          ),
                                          const SizedBox(height: 10),
                                          Form(
                                            key: resetPasswordFormKey,
                                            child: TextFormField(
                                              controller: controller
                                                  .emailForPasswordResetController,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return "Please enter your email";
                                                }
                                                if (!GetUtils.isEmail(value)) {
                                                  return "Please enter a valid email";
                                                }
                                                return null;
                                              },
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                labelText: "Email",
                                                prefixIcon: Icon(Icons.email),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            controller
                                                .emailForPasswordResetController
                                                .clear();
                                          },
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (resetPasswordFormKey
                                                .currentState!
                                                .validate()) {
                                              Navigator.pop(context);
                                              controller
                                                  .sendPasswordResetEmail();
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF517399),
                                          ),
                                          child: const Text(
                                            "Send Link",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(color: Colors.blue.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button
                      SizedBox(
                        width: 300,
                        height: 50,
                        child: Obx(
                          // WRAP WITH Obx
                          () => ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 5,
                              backgroundColor:
                                  const Color.fromARGB(255, 81, 115, 153),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: controller.isGoogleLoading.value
                                ? null
                                : () {
                                    controller.validateAndLogin(
                                      emailOrUsername: controller
                                          .emailEditingController.text
                                          .trim(),
                                      password: controller
                                          .passwordEditingController.text,
                                    );
                                  },
                            child: const Text(
                              "Sign In",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Text(
                              "  or  ",
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign in with text
                      const Text(
                        "Sign in with",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),

                      // Google Button
                      Obx(
                        () => GestureDetector(
                          onTap: controller.isGoogleLoading.value
                              ? null
                              : () async {
                                  await controller.signInWithGoogle();
                                },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  color: Colors.grey.shade400,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: controller.isGoogleLoading.value
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : Image.asset(
                                    "lib/images/google_logo.png",
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Don't have account text
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: <TextSpan>[
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 81, 115, 153),
                              ),
                              text: "Sign up",
                              recognizer: TapGestureRecognizer()
                                ..onTap = controller.moveToSignUp,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32,),
                      // TextButton(
                      //   onPressed: () =>
                      //       Get.toNamed('/vet-clinic-registration'),
                      //   child: const Text('Sign up as a veterinary clinic'),
                      // ),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: <TextSpan>[
                            TextSpan(
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 81, 115, 153),
                              ),
                              text: "Register your veterinary clinic here →",
                              recognizer: TapGestureRecognizer()
                                ..onTap = _moveToSignUpVet,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  void _moveToSignUpVet() {
    Get.toNamed(Routes.vetClinicRegistration);
  }
}
