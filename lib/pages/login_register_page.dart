import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool isCheckingUsername = false;
  bool isLoading = false;
  bool showRegistrationSuccess = false;

  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerConfirmPassword = TextEditingController();
  final TextEditingController _controllerForgotPasswordEmail = TextEditingController();

  @override
  void dispose() {
    _controllerUsername.dispose();
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    _controllerConfirmPassword.dispose();
    _controllerForgotPasswordEmail.dispose();
    super.dispose();
  }

  void _clearPasswordField() {
    _controllerPassword.clear();
    setState(() => errorMessage = '');
  }

  void _clearTextControllers() {
    _controllerUsername.clear();
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

    setState(() => isLoading = true);

    try {
      await Auth().signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message ?? 'An error occurred');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    if (_controllerUsername.text.isEmpty ||
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

    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(_controllerUsername.text)) {
      setState(() => errorMessage = 'Username must be 3-20 characters (letters, numbers, _)');
      return;
    }

    setState(() {
      isCheckingUsername = true;
      isLoading = true;
      showRegistrationSuccess = false;
    });

    try {
      final isAvailable = await Auth().isUsernameAvailable(_controllerUsername.text);
      if (!isAvailable) {
        setState(() {
          errorMessage = 'Username is already taken';
          isCheckingUsername = false;
          isLoading = false;
        });
        return;
      }

      await Auth().createUserWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
        username: _controllerUsername.text,
      );

      setState(() {
        showRegistrationSuccess = true;
        errorMessage = 'Registration successful! Please sign in.';
        _controllerPassword.clear();
        _controllerConfirmPassword.clear();
        isLogin = true;
        headerText = "Sign in to continue";
      });

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() => showRegistrationSuccess = false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          errorMessage = 'Email already in use';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password should be at least 6 characters';
        } else {
          errorMessage = e.message ?? 'Registration failed';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          isCheckingUsername = false;
          isLoading = false;
        });
      }
    }
  }

  Widget _entryField(
      String hintText,
      TextEditingController controller,
      IconData icon,
      bool isPassword, {
        bool showAvailability = false,
      }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            if (showAvailability && !isLogin) {
              setState(() {});
            }
          },
        ),
        if (showAvailability && !isLogin && controller.text.isNotEmpty)
          FutureBuilder<bool>(
            future: Auth().isUsernameAvailable(controller.text),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              if (snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    snapshot.data! ? '✓ Available' : '✗ Taken',
                    style: TextStyle(
                      color: snapshot.data! ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
      ],
    );
  }

  Widget _errorMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        errorMessage,
        style: TextStyle(
          color: errorMessage.toLowerCase().contains('success') ? Colors.green : Colors.red,
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
        onPressed: isLoading ? null : isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Text(isLogin ? 'Sign in' : 'Sign up'),
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
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _notSignedUpButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Not signed up? ',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        TextButton(
          onPressed: isLoading ? null : () {
            setState(() {
              isLogin = false;
              headerText = "Create your account";
              _clearTextControllers();
            });
          },
          child: Text(
            'Sign up',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
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
          'Already have an account? ',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        TextButton(
          onPressed: isLoading ? null : () {
            setState(() {
              isLogin = true;
              headerText = "Welcome back";
              _clearTextControllers();
            });
          },
          child: Text(
            'Sign in',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
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
                    setState(() => forgotPasswordMessage = 'Reset link sent! Check your email.');
                  } on FirebaseAuthException catch (e) {
                    setState(() => forgotPasswordMessage =
                    e.code == 'user-not-found'
                        ? 'No account found with this email'
                        : 'Error: ${e.message}');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: showRegistrationSuccess ? 50 : -100,
      left: 20,
      right: 20,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Account created successfully!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() => showRegistrationSuccess = false);
                },
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
            'Sign In',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          _entryField('Email', _controllerEmail, Icons.email, false),
          const SizedBox(height: 15),
          _entryField('Password', _controllerPassword, Icons.lock, true),
          const SizedBox(height: 10),
          _errorMessage(),
          _submitButton(),
          _forgotPasswordButton(),
          _notSignedUpButton(),
        ],
      ),
      secondChild: Column(
        children: [
          Text(
            'Create Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          _entryField('Username', _controllerUsername, Icons.person, false, showAvailability: true),
          const SizedBox(height: 15),
          _entryField('Email', _controllerEmail, Icons.email, false),
          const SizedBox(height: 15),
          _entryField('Password', _controllerPassword, Icons.lock, true),
          const SizedBox(height: 15),
          _entryField('Confirm Password', _controllerConfirmPassword, Icons.lock, true),
          const SizedBox(height: 10),
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
                            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
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
                            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
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
              _buildSuccessMessage(),
            ],
          ),
        ],
      ),
    );
  }
}