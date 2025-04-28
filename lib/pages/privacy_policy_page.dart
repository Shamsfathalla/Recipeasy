import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
              'Recipeasy Privacy Policy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last Updated: April 28, 2025\n',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const Text(
              '1. Information We Collect\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'We collect information you provide when creating an account, posting content, or using features. This may include:',
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Account information (name, email, username)'),
                  Text('• Recipes you create or save'),
                  Text('• Meal plans and shopping lists'),
                  Text('• Interactions with other users'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '2. How We Use Information\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'We use your information to:',
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Provide and improve the App\'s functionality'),
                  Text('• Personalize your experience'),
                  Text('• Communicate with you about your account'),
                  Text('• Ensure compliance with our terms'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '3. Data Sharing\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'We do not sell your personal data. Information may be shared:',
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• With service providers who assist in operating the App'),
                  Text('• When required by law or to protect our rights'),
                  Text('• With your consent for specific purposes'),
                ],
              ),
            ),
            const Text(
              'Public recipes, profiles, and comments are visible to other users as part of the App\'s functionality.',
            ),
            const SizedBox(height: 16),
            const Text(
              '4. Data Security\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'We implement security measures to protect your information, but no system is completely secure. You are responsible for keeping your password confidential.',
            ),
            const SizedBox(height: 16),
            const Text(
              '5. Your Choices\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'You can:',
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Update account information in settings'),
                  Text('• Delete your account at any time'),
                  Text('• Adjust notification preferences'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '6. Children\'s Privacy\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Recipeasy is not intended for children under 13. We do not knowingly collect data from children under 13.',
            ),
            const SizedBox(height: 16),
            const Text(
              '7. Changes to This Policy\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'We may update this policy. Continued use after changes constitutes acceptance of the new policy.',
            ),
            const SizedBox(height: 16),
            const Text(
              '8. Contact Us\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'For questions about this policy, contact us at privacy@recipeasyapp.com.',
            ),
          ],
        ),
      ),
    );
  }
}