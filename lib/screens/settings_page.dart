import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.dark_mode_outlined),
            title: Text('Dark Mode'),
            subtitle: Text('Change application appearance'),
          ),
          ListTile(
            leading: Icon(Icons.language_outlined),
            title: Text('Language'),
            subtitle: Text('English'),
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            subtitle: Text('Digital Malaysia Connect'),
          ),
        ],
      ),
    );
  }
}