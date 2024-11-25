import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewPostPage extends StatefulWidget {
  final String category;
  final bool isEditing;
  final String? postId;
  final String? existingTitle;
  final String? existingContent;

  NewPostPage({
    required this.category,
    this.isEditing = false,
    this.postId,
    this.existingTitle,
    this.existingContent,
  });

  @override
  _NewPostPageState createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _titleController.text = widget.existingTitle ?? '';
      _contentController.text = widget.existingContent ?? '';
    }
  }

  Future<void> _savePost() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Firestore에서 현재 사용자의 닉네임 가져오기
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userData = userDoc.data();
        final nickname = userData?['nickname'] ?? '익명'; // 닉네임이 없으면 '익명' 사용

        if (widget.isEditing && widget.postId != null) {
          // 게시글 수정
          await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
            'title': _titleController.text.trim(),
            'content': _contentController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // 새로운 게시글 작성
          await FirebaseFirestore.instance.collection('posts').add({
            'title': _titleController.text.trim(),
            'content': _contentController.text.trim(),
            'nickname': nickname, // 닉네임 저장
            'userId': user.uid,
            'category': widget.category,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        Navigator.pop(context);
      }
    } catch (e) {
      print('게시글 작성/수정 중 오류 발생: $e');
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
        title: Text(widget.isEditing ? '게시글 수정' : '게시글 작성'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: '제목'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(labelText: '내용'),
                    maxLines: 5,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _savePost,
                    child: Text(widget.isEditing ? '수정하기' : '작성하기'),
                  ),
                ],
              ),
      ),
    );
  }
}
