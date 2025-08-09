import 'package:flutter/material.dart';
import 'package:uniparkpay/widgets/app/content_page.dart';

class SettingsPage extends ContentPage {
  const SettingsPage({super.key}) : super(title: 'Settings');

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.settings, size: 50),
        const SizedBox(height: 20),
        const Text('App settings will be displayed here'),
        // Add theme toggle
        // Add notification settings
        // Add account preferences
      ],
    );
  }
}