import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final bool compact;

  const ChatScreen({super.key, this.compact = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtl = TextEditingController();
  final _scrollCtl = ScrollController();

  static const _suggestions = [
    'What doctors are available?',
    'Do you accept insurance?',
    'How can I book an appointment?',
  ];

  @override
  void dispose() {
    _inputCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final msg = (text ?? _inputCtl.text).trim();
    if (msg.isEmpty) return;
    context.read<ChatProvider>().send(msg);
    _inputCtl.clear();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtl.hasClients) {
        _scrollCtl.animateTo(
          _scrollCtl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ChatProvider>();
    final compact = widget.compact;
    final padding = compact ? 16.0 : 28.0;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(padding, compact ? 16 : 24, padding, 0),
          child: Row(
            children: [
              Text('AI Assistant', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: compact ? 20 : null)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('RAG · powered',
                    style: TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w600)),
              ),
              if (compact) ...[
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close chat',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtl,
            padding: EdgeInsets.symmetric(horizontal: padding),
            itemCount: prov.messages.length + (prov.isAwaitingReply ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= prov.messages.length) return const _TypingBubble();
              return _MessageBubble(message: prov.messages[i]);
            },
          ),
        ),
        _SuggestionChips(
          suggestions: _suggestions,
          enabled: !prov.isAwaitingReply,
          onTap: _send,
        ),
        _Composer(controller: _inputCtl, onSend: _send, sending: prov.isAwaitingReply, compact: compact),
        SizedBox(height: compact ? 12 : 16),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 640),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (isError ? AppColors.danger.withValues(alpha: 0.08) : AppColors.bg),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 14),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: isUser ? Colors.white : (isError ? AppColors.danger : AppColors.text),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1),
                duration: Duration(milliseconds: 500 + i * 150),
                curve: Curves.easeInOut,
                builder: (context, v, _) => Opacity(
                  opacity: v,
                  child: Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final bool enabled;
  final ValueChanged<String> onTap;

  const _SuggestionChips({required this.suggestions, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final s in suggestions)
            ActionChip(
              label: Text(s, style: const TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
              backgroundColor: AppColors.info.withValues(alpha: 0.08),
              side: BorderSide(color: AppColors.info.withValues(alpha: 0.3)),
              labelStyle: const TextStyle(color: AppColors.info, fontSize: 12),
              onPressed: enabled ? () => onTap(s) : null,
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool sending;
  final bool compact;

  const _Composer({required this.controller, required this.onSend, required this.sending, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 16 : 28),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Ask about doctors, services, insurance...',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: sending ? null : (v) => onSend(v),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: sending ? null : () => onSend(''),
            icon: const Icon(Icons.send_rounded, size: 20),
            color: AppColors.primary,
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }
}
