// ignore_for_file: file_names, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:parkflow/components/signOutComp.dart';
import 'package:parkflow/pages/settings/pages/profielPage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _showDefaultPage = true;
  bool _showProfielPage = false;

  void _onButton1Pressed() {
    setState(() {
      _showDefaultPage = false;
      _showProfielPage = true;
    });
  }

  void _onBackButtonPressed() {
    setState(() {
      _showDefaultPage = true;
      _showProfielPage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: _showProfielPage
            ? IconButton(
                onPressed: _onBackButtonPressed,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: Stack(
        children: [
          _showDefaultPage
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: _onButton1Pressed,
                        child: const Text('Profiel'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Button 2'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Button 3'),
                      ),
                      const SizedBox(height: 50),
                      const SignOutButton()
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          _showProfielPage ? const ProfielPage() : const SizedBox.shrink(),
        ],
      ),
    );
  }
}