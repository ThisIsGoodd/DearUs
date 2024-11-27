import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';

class ChatPage extends StatefulWidget {
  final String connectedUserUid;
  final String connectedUserNickname;

  const ChatPage({
    Key? key,
    required this.connectedUserUid,
    required this.connectedUserNickname,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  User? currentUser = FirebaseAuth.instance.currentUser;

  String getChatId() {
    if (currentUser == null) return '';
    return currentUser!.uid.compareTo(widget.connectedUserUid) < 0
        ? '${currentUser!.uid}_${widget.connectedUserUid}'
        : '${widget.connectedUserUid}_${currentUser!.uid}';
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUser == null) return;

    final chatId = getChatId();

    final message = ChatMessage(
      id: FirebaseFirestore.instance.collection('messages').doc().id,
      senderId: currentUser!.uid,
      receiverId: widget.connectedUserUid,
      message: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(message.id)
        .set({
          ...message.toMap(),
          'chatId': chatId,
        });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatId = getChatId();

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.connectedUserNickname}'), // 닉네임 출력
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('chatId', isEqualTo: chatId)
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('오류 발생: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('메시지가 없습니다.'));
                }

                final messages = snapshot.data!.docs
                    .map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser!.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message.message,
                          style: TextStyle(color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
