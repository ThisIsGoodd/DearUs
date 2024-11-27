import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../services/database_service.dart';

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
  final DatabaseService _databaseService = DatabaseService();
  User? currentUser = FirebaseAuth.instance.currentUser;

  String getChatId() {
    if (currentUser == null) {
      print('[DEBUG] Current user is null.');
      return '';
    }
    final chatId = currentUser!.uid.compareTo(widget.connectedUserUid) < 0
        ? '${currentUser!.uid}_${widget.connectedUserUid}'
        : '${widget.connectedUserUid}_${currentUser!.uid}';
    print('[DEBUG] Generated chatId: $chatId');
    return chatId;
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUser == null) {
      print('[DEBUG] Message is empty or current user is null.');
      return;
    }

    final chatId = getChatId();
    final message = ChatMessage(
      id: FirebaseFirestore.instance.collection('chats/$chatId/messages').doc().id,
      senderId: currentUser!.uid,
      receiverId: widget.connectedUserUid,
      message: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    try {
      await _databaseService.addChatMessage(message, chatId);
      print('[DEBUG] Message stored successfully.');
    } catch (e) {
      print('[DEBUG] Error storing message: $e');
    }

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
        title: Text('${widget.connectedUserNickname}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.connectedUserUid.isEmpty
                ? Center(child: Text('연결된 사용자가 없습니다.'))
                : StreamBuilder<List<ChatMessage>>(
                    stream: _databaseService.getChatMessages(chatId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('오류 발생: ${snapshot.error}'));
                      }

                      final messages = snapshot.data;

                      if (messages == null || messages.isEmpty) {
                        return Center(child: Text('채팅을 시작하세요.'));
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == currentUser!.uid;

                          bool showDateDivider = false;
                          if (index == 0 || !isSameDate(message.timestamp, messages[index - 1].timestamp)) {
                            showDateDivider = true;
                          }

                          return Column(
                            children: [
                              if (showDateDivider)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Divider(color: Colors.grey),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          DateFormat('yyyy-MM-dd').format(message.timestamp),
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                  padding: EdgeInsets.all(10),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blue : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.message,
                                        style: TextStyle(color: isMe ? Colors.white : Colors.black),
                                      ),
                                      SizedBox(height: 5),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          DateFormat('HH:mm').format(message.timestamp),
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요...',
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

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
