import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/socket_provider.dart';
import '../../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String orderId;
  final String currentUserId; // هاد ID الشخص اللي فاتح التطبيق (سائق أو زبون)

  const ChatScreen(
      {super.key, required this.orderId, required this.currentUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<MessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    // البدء بالاستماع للرسائل فور فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocketProvider>().listenToMessages((data) {
        if (mounted && data['orderId'] == widget.orderId) {
          setState(() {
            _messages.add(MessageModel.fromJson(data));
          });
        }
      });
    });
  }

  void _send() {
    if (_controller.text.isNotEmpty) {
      context
          .read<SocketProvider>()
          .sendMessage(widget.orderId, widget.currentUserId, _controller.text);
      // إضافتها للقائمة محلياً عشان تظهر فوراً
      setState(() {
        _messages.add(MessageModel(
            senderId: widget.currentUserId,
            text: _controller.text,
            time: DateTime.now()));
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("الدردشة مع الطرف الآخر"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // عشان الرسائل الجديدة تطلع من تحت
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages.reversed.toList()[index];
                bool isMe = msg.senderId == widget.currentUserId;
                return _buildChatBubble(msg, isMe);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.black : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
        ),
        child: Text(msg.text,
            style: TextStyle(color: isMe ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                  hintText: "اكتب رسالة...", border: InputBorder.none),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.send, color: Colors.black),
              onPressed: _send),
        ],
      ),
    );
  }
}
