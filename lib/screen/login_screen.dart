import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();
  String verificationId = '';
  bool showCodeField = false;
  PhoneNumber number = PhoneNumber(isoCode: 'KR');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Welcome back to the app',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  // International Phone Number Input
                  InternationalPhoneNumberInput(
                    onInputChanged: (PhoneNumber newNumber) {
                      setState(() {
                        number = newNumber;
                      });
                    },
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                      useBottomSheetSafeArea: true,
                    ),
                    textFieldController: _phoneController,
                    inputDecoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+82 10 1234 5678',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    formatInput: true,
                    keyboardType: TextInputType.phone,
                    initialValue: number,
                  ),
                  const SizedBox(height: 16),
                  // SMS Code Input
                  if (showCodeField)
                    TextField(
                      controller: _smsCodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'SMS Code',
                        hintText: 'Enter the SMS code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Login / Send Code Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!showCodeField) {
                          _sendVerificationCode();
                        } else {
                          _verifyCode();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(showCodeField ? 'Login' : 'Send Code'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // SMS 코드 전송
  Future<void> _sendVerificationCode() async {
    String phoneNumber = number.phoneNumber ?? '';
    if (phoneNumber.isNotEmpty) {
      FirebaseAuth auth = FirebaseAuth.instance;

      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await auth.signInWithCredential(credential);
          _navigateToHome();
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackBar("Verification Failed: ${e.message}");
        },
        codeSent: (String id, int? resendToken) {
          setState(() {
            verificationId = id;
            showCodeField = true;
          });
        },
        codeAutoRetrievalTimeout: (String id) {
          verificationId = id;
        },
        timeout: const Duration(seconds: 60),
      );
    } else {
      _showSnackBar("Please enter a valid phone number.");
    }
  }

  // SMS 코드 검증
  Future<void> _verifyCode() async {
    String smsCode = _smsCodeController.text.trim();
    if (smsCode.isNotEmpty && verificationId.isNotEmpty) {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      try {
        await FirebaseAuth.instance.signInWithCredential(credential);
        _navigateToHome();
      } catch (e) {
        _showSnackBar("Invalid SMS Code.");
      }
    } else {
      _showSnackBar("Please enter the SMS code.");
    }
  }

  // 홈 화면 이동
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // 스낵바
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }
}
