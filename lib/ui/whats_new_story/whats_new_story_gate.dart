import 'package:flutter/material.dart';
import 'package:profit_from_it_investors/network/whats_new_story_service.dart';
import 'package:profit_from_it_investors/ui/dashboard_screen/dashboard_screen.dart';
import 'package:profit_from_it_investors/ui/whats_new_story/whats_new_story_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';

/// Single entry point after a verified session: cold launch, OTP login,
/// or completion of the existing app-version release notes.
class WhatsNewStoryGate extends StatefulWidget {
  const WhatsNewStoryGate({super.key});

  @override
  State<WhatsNewStoryGate> createState() => _WhatsNewStoryGateState();
}

class _WhatsNewStoryGateState extends State<WhatsNewStoryGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _continue());
  }

  Future<void> _continue() async {
    final story = await WhatsNewStoryService.fetchForToday();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => story == null
            ? const DashboardScreen()
            : WhatsNewStoryScreen(story: story),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 34, color: AppColor.primary),
              SizedBox(height: 16),
              Text('Preparing your investor dashboard',
                  style: TextStyle(
                      color: Color(0xFF162B4E),
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 18),
              SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColor.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
