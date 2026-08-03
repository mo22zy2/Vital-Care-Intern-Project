import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../../features/chat/screens/chat_screen.dart';

class FloatingChatButton extends StatelessWidget {
  const FloatingChatButton({super.key});

  void _openChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const Dialog(
        insetPadding: EdgeInsets.all(24),
        child: SizedBox(
          width: 440,
          height: 620,
          child: ChatScreen(compact: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _openChat(context),
      tooltip: 'AI Assistant',
      backgroundColor: AppColors.primary,
      elevation: 4,
      child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
    );
  }
}
