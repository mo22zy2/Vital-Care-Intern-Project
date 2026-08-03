import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/base_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  const ChatMessage(this.text, {required this.isUser, this.isError = false});
}

class ChatProvider extends BaseProvider {
  final List<ChatMessage> _messages = [];
  bool _awaitingReply = false;

  ChatProvider() {
    _messages.add(const ChatMessage(
      'Hello! I\'m VitalCare\'s virtual assistant. Ask me about our doctors, services, '
      'pricing, insurance, or anything else about the hospital.',
      isUser: false,
    ));
  }

  List<ChatMessage> get messages => _messages;
  bool get isAwaitingReply => _awaitingReply;

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _awaitingReply) return;
    _messages.add(ChatMessage(trimmed, isUser: true));
    _awaitingReply = true;
    notifyListeners();
    final ok = await guard(() async {
      final res = await ApiClient.post(ApiConstants.chatAsk, body: {'text': trimmed, 'limit': 5});
      final answer = res['answer']?.toString();
      if (answer == null || answer.isEmpty) {
        throw StateError('empty answer');
      }
      _messages.add(ChatMessage(answer, isUser: false));
    }, errorMessage: 'Sorry, the assistant is unreachable right now. Please try again later.');
    _awaitingReply = false;
    if (!ok && error != null) {
      _messages.add(ChatMessage(error!, isUser: false, isError: true));
    }
    notifyListeners();
  }
}
