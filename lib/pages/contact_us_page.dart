// ContactUsPage.dart: 문의사항 작성 페이지
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactUsPage extends StatefulWidget {
  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _messageController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('inquiries').add({
          'userUid': user.uid,
          'message': _messageController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = '사용자 인증에 실패했습니다. 다시 로그인해주세요.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '메시지 전송 중 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('문의사항 작성'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                    SizedBox(height: 10),
                  ],
                  TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: '문의사항을 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    child: Text('문의사항 전송'),
                  ),
                ],
              ),
            ),
    );
  }
}
