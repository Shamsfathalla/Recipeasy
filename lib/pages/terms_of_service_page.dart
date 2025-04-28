import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(168, 64, 185, 1),
                Color.fromRGBO(110, 59, 226, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recipeasy Terms of Service',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last Updated: April 28, 2025\n',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const Text(
              '1. Acceptance of Terms\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'By accessing or using Recipeasy ("the App"), you agree to be bound by these Terms of Service. If you do not agree to all the terms, you may not use the App.',
            ),
            const SizedBox(height: 16),
            const Text(
              '2. Description of Service\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Recipeasy provides a platform for users to discover, save, and share recipes. Features include searching recipes, creating meal plans, managing shopping lists, and following other users.',
            ),
            const SizedBox(height: 16),
            const Text(
              '3. User Responsibilities\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'You are responsible for all content you post, including recipes, comments, and profile information. You agree not to post content that is unlawful, harmful, or infringes on others\' rights.',
            ),
            const SizedBox(height: 16),
            const Text(
              '4. Intellectual Property\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'While you retain ownership of your content, by posting you grant Recipeasy a license to use, display, and distribute your content within the App. Recipeasy\'s trademarks and logos may not be used without permission.',
            ),
            const SizedBox(height: 16),
            const Text(
              '5. Termination\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'We may terminate or suspend your account immediately for violations of these terms or for any other reason at our discretion.',
            ),
            const SizedBox(height: 16),
            const Text(
              '6. Limitation of Liability\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Recipeasy is not responsible for the accuracy of recipes or any health effects from following them. Use at your own risk. We are not liable for any damages resulting from use of the App.',
            ),
            const SizedBox(height: 16),
            const Text(
              '7. Changes to Terms\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'We may modify these terms at any time. Continued use after changes constitutes acceptance of the new terms.',
            ),
            const SizedBox(height: 16),
            const Text(
              '8. Contact Information\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'For any questions about these Terms, please contact us at support@recipeasyapp.com.',
            ),
          ],
        ),
      ),
    );
  }
}