import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth.dart'; // Import your Auth class
import '../pages/home_page.dart'; // Import the HomePage

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String errorMessage = '';
  bool showForm = false;
  bool isLogin = true;
  bool showForgotPassword = false;
  String headerText = "Welcome";

  // New variable for Forgot Password message
  String forgotPasswordMessage = '';

  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerConfirmPassword =
      TextEditingController();
  final TextEditingController _controllerForgotPasswordEmail =
      TextEditingController();

  // Function to clear only the password field
  void _clearPasswordField() {
    _controllerPassword.clear();
    setState(() {
      errorMessage = ''; // Clear any error messages
    });
  }

  // Function to clear all text controllers
  void _clearTextControllers() {
    _controllerName.clear();
    _controllerEmail.clear();
    _controllerPassword.clear();
    _controllerConfirmPassword.clear();
    setState(() {
      errorMessage = ''; // Clear any error messages
    });
  }

  Future<void> signInWithEmailAndPassword() async {
    if (_controllerEmail.text.isEmpty || _controllerPassword.text.isEmpty) {
      setState(() => errorMessage = 'Please enter both email and password');
      return;
    }

    try {
      await Auth().signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
      setState(() => errorMessage = '');
      // Navigate to HomePage after successful sign-in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message ?? 'An error occurred');
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    if (_controllerName.text.isEmpty ||
        _controllerEmail.text.isEmpty ||
        _controllerPassword.text.isEmpty ||
        _controllerConfirmPassword.text.isEmpty) {
      setState(() => errorMessage = 'All fields are required');
      return;
    }

    if (_controllerPassword.text != _controllerConfirmPassword.text) {
      setState(() => errorMessage = 'Passwords do not match');
      return;
    }

    try {
      await Auth().createUserWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
      setState(() {
        errorMessage = 'Sign up successful! Please sign in.'; // Success message
        _clearTextControllers(); // Clear the form fields
        // Switch to Sign-In mode
        isLogin = true;
        headerText = "Hello, sign in";
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(
          () =>
              errorMessage =
                  'The email address is already in use by another account.',
        );
      } else {
        setState(() => errorMessage = e.message ?? 'An error occurred');
      }
    }
  }

  Widget _entryField(
    String hintText,
    TextEditingController controller,
    IconData icon,
    bool isPassword,
  ) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _errorMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        errorMessage,
        style: TextStyle(
          color:
              errorMessage.contains('success')
                  ? Colors.green
                  : Colors.red, // Green for success, red for errors
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed:
            isLogin
                ? signInWithEmailAndPassword
                : createUserWithEmailAndPassword,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        child: Text(isLogin ? 'Sign in' : 'Sign up'),
      ),
    );
  }

  Widget _forgotPasswordButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          showForgotPassword = true; // Open forgot password box
          showForm = false; // Close sign-in/sign-up box
          _clearPasswordField(); // Clear only the password field
          _controllerForgotPasswordEmail.text =
              _controllerEmail
                  .text; // Copy email from Sign In to Forgot Password
        });
      },
      child: const Text(
        'Forgot Password?',
        style: TextStyle(color: Colors.blueAccent, fontSize: 16),
      ),
    );
  }

  Widget _notSignedUpButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Not signed up? ',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              isLogin = false; // Switch to sign-up mode
              headerText = "Create your account";
              _clearTextControllers(); // Clear text fields
            });
          },
          child: const Text(
            'Sign up',
            style: TextStyle(fontSize: 16, color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }

  Widget _alreadySignedUpButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already signed up? ',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              isLogin = true; // Switch to sign-in mode
              headerText = "Hello, sign in";
              _clearTextControllers(); // Clear text fields
            });
          },
          child: const Text(
            'Sign in',
            style: TextStyle(fontSize: 16, color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }

  Widget _forgotPasswordBox() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      bottom:
          showForgotPassword ? 0 : -MediaQuery.of(context).size.height * 0.6,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: showForgotPassword ? 1 : 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Reset Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _entryField(
                'Email',
                _controllerForgotPasswordEmail,
                Icons.email,
                false,
              ),
              const SizedBox(height: 10),
              if (forgotPasswordMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    forgotPasswordMessage,
                    style: TextStyle(
                      color:
                          forgotPasswordMessage.contains('error')
                              ? Colors.red
                              : Colors.green,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  if (_controllerForgotPasswordEmail.text.isEmpty) {
                    setState(() {
                      forgotPasswordMessage = 'Please enter your email';
                    });
                    return;
                  }

                  try {
                    await Auth().sendPasswordResetEmail(
                      _controllerForgotPasswordEmail.text,
                    );
                    setState(() {
                      forgotPasswordMessage =
                          'Password reset link sent! Check your inbox.';
                    });
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'user-not-found') {
                      setState(() {
                        forgotPasswordMessage =
                            'Error: No user found with this email.';
                      });
                    } else {
                      setState(() {
                        forgotPasswordMessage = 'Error: ${e.message}';
                      });
                    }
                  }
                },
                child: const Text('Send Reset Link'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    showForgotPassword = false; // Close forgot password box
                    showForm = true; // Reopen sign-in form
                    forgotPasswordMessage = ''; // Clear the message
                  });
                },
                child: const Text(
                  'Back to Sign In',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 500),
      crossFadeState:
          isLogin ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: Column(
        children: [
          const Text(
            'Welcome Back',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _entryField('Email', _controllerEmail, Icons.email, false),
          const SizedBox(height: 15),
          _entryField('Password', _controllerPassword, Icons.lock, true),
          _errorMessage(),
          _submitButton(),
          _forgotPasswordButton(),
          _notSignedUpButton(),
        ],
      ),
      secondChild: Column(
        children: [
          const Text(
            'Create your Account',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _entryField('Name', _controllerName, Icons.person, false),
          const SizedBox(height: 15),
          _entryField('Email', _controllerEmail, Icons.email, false),
          const SizedBox(height: 15),
          _entryField('Password', _controllerPassword, Icons.lock, true),
          const SizedBox(height: 15),
          _entryField(
            'Confirm Password',
            _controllerConfirmPassword,
            Icons.lock,
            true,
          ),
          _errorMessage(),
          _submitButton(),
          _alreadySignedUpButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png', // Path to your background image
              fit: BoxFit.cover, // Ensures the image covers the entire screen
            ),
          ),

          // Logo Image (Animated Position and Size)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            top:
                showForm && !isLogin
                    ? screenHeight * 0.13
                    : screenHeight * 0.19, // Adjusted position
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/logo.png', // Path to your logo image
                width: 275, // Adjusted width
                height: 275, // Adjusted height
              ),
            ),
          ),

          // Content Overlay
          Stack(
            alignment: Alignment.center,
            children: [
              // Background GestureDetector to detect taps outside the form
              if (showForm || showForgotPassword)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (showForgotPassword) {
                        showForgotPassword = false; // Close forgot password box
                        showForm = true; // Reopen sign-in form
                        forgotPasswordMessage = ''; // Clear the message
                      } else {
                        showForm = false; // Close sign-in/sign-up box
                        showForgotPassword =
                            false; // Ensure forgot password box is also closed
                        errorMessage = '';
                        isLogin = true; // Default to sign-in mode
                        headerText = "Welcome";
                      }
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),

              // Sign In and Sign Up Buttons
              Positioned(
                top:
                    screenHeight *
                    0.51, // Adjusted position below the welcome text
                left: 0,
                right: 0,
                child: Visibility(
                  visible: !showForm && !showForgotPassword,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 300,
                        height: 80,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLogin = true;
                              showForm = true;
                              _clearTextControllers(); // Clear text fields
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: 300,
                        height: 80,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLogin = false;
                              showForm = true;
                              _clearTextControllers(); // Clear text fields
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('Sign Up'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Form Container
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                bottom: showForm ? 0 : -screenHeight * 0.6,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: showForm ? 1 : 0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: _form(),
                  ),
                ),
              ),

              // Forgot Password Box
              _forgotPasswordBox(),
            ],
          ),
        ],
      ),
    );
  }
}
