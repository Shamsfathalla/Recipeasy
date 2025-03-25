import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth.dart';
import '../pages/home_page.dart';

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
  String forgotPasswordMessage = '';

  // Color constants
  final Color iconColor = Colors.blueAccent;
  final Color purpleTextColor = Colors.deepPurple;
  final Color accentButtonColor = Colors.blueAccent;

  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerConfirmPassword = TextEditingController();
  final TextEditingController _controllerForgotPasswordEmail = TextEditingController();

  void _clearPasswordField() {
    _controllerPassword.clear();
    setState(() => errorMessage = '');
  }

  void _clearTextControllers() {
    _controllerName.clear();
    _controllerEmail.clear();
    _controllerPassword.clear();
    _controllerConfirmPassword.clear();
    setState(() => errorMessage = '');
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
        errorMessage = 'Sign up successful! Please sign in.';
        // Copy email to sign-in form before clearing
        final signedUpEmail = _controllerEmail.text;
        _clearTextControllers();
        _controllerEmail.text = signedUpEmail; // Set the email in sign-in form
        isLogin = true;
        headerText = "Hello, sign in";
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() => errorMessage = 'The email address is already in use by another account.');
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
        prefixIcon: Icon(icon, color: iconColor),
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
          color: errorMessage.contains('success') ? Colors.green : Colors.red,
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
        onPressed: isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          showForgotPassword = true;
          showForm = false;
          _clearPasswordField();
          _controllerForgotPasswordEmail.text = _controllerEmail.text;
        });
      },
      child: Text(
        'Forgot Password?',
        style: TextStyle(color: accentButtonColor, fontSize: 16),
      ),
    );
  }

  Widget _notSignedUpButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Not signed up? ',
          style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              isLogin = false;
              headerText = "Create your account";
              _clearTextControllers();
            });
          },
          child: Text(
            'Sign up',
            style: TextStyle(fontSize: 16, color: accentButtonColor),
          ),
        ),
      ],
    );
  }

  Widget _alreadySignedUpButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already signed up? ',
          style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              isLogin = true;
              headerText = "Hello, sign in";
              _clearTextControllers();
            });
          },
          child: Text(
            'Sign in',
            style: TextStyle(fontSize: 16, color: accentButtonColor),
          ),
        ),
      ],
    );
  }

  Widget _forgotPasswordBox() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      bottom: showForgotPassword ? 0 : -MediaQuery.of(context).size.height * 0.6,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: showForgotPassword ? 1 : 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
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
              Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              _entryField('Email', _controllerForgotPasswordEmail, Icons.email, false),
              const SizedBox(height: 10),
              if (forgotPasswordMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    forgotPasswordMessage,
                    style: TextStyle(
                      color: forgotPasswordMessage.contains('error') ? Colors.red : Colors.green,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  if (_controllerForgotPasswordEmail.text.isEmpty) {
                    setState(() => forgotPasswordMessage = 'Please enter your email');
                    return;
                  }

                  try {
                    await Auth().sendPasswordResetEmail(_controllerForgotPasswordEmail.text);
                    setState(() => forgotPasswordMessage = 'Password reset link sent! Check your inbox.');
                  } on FirebaseAuthException catch (e) {
                    setState(() => forgotPasswordMessage = e.code == 'user-not-found'
                        ? 'Error: No user found with this email.'
                        : 'Error: ${e.message}');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                child: const Text('Send Reset Link'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    showForgotPassword = false;
                    showForm = true;
                    forgotPasswordMessage = '';
                  });
                },
                child: Text(
                  'Back to Sign In',
                  style: TextStyle(color: accentButtonColor, fontSize: 16),
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
      crossFadeState: isLogin ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: Column(
        children: [
          Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
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
          Text(
            'Create your Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _entryField('Name', _controllerName, Icons.person, false),
          const SizedBox(height: 15),
          _entryField('Email', _controllerEmail, Icons.email, false),
          const SizedBox(height: 15),
          _entryField('Password', _controllerPassword, Icons.lock, true),
          const SizedBox(height: 15),
          _entryField('Confirm Password', _controllerConfirmPassword, Icons.lock, true),
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
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            top: showForm && !isLogin ? screenHeight * 0.13 : screenHeight * 0.19,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 275,
                height: 275,
              ),
            ),
          ),

          Stack(
            alignment: Alignment.center,
            children: [
              if (showForm || showForgotPassword)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (showForgotPassword) {
                        showForgotPassword = false;
                        showForm = true;
                        forgotPasswordMessage = '';
                      } else {
                        showForm = false;
                        showForgotPassword = false;
                        errorMessage = '';
                        isLogin = true;
                        headerText = "Welcome";
                      }
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),

              Positioned(
                top: screenHeight * 0.51,
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
                              _clearTextControllers();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            foregroundColor: purpleTextColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              _clearTextControllers();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            foregroundColor: purpleTextColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      color: Theme.of(context).dialogBackgroundColor,
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

              _forgotPasswordBox(),
            ],
          ),
        ],
      ),
    );
  }
}