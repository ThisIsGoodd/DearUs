// lib/pages/edit_post_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPostPage extends StatefulWidget {
  final String postId;

  EditPostPage({required this.postId});

  @override
  _EditPostPageState createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      DocumentSnapshot postSnapshot = await FirebaseFirestore.instance.collection('posts').doc(widget.postId).get();
      if (postSnapshot.exists) {
        setState(() {
          _titleController.text = postSnapshot['title'];
          _contentController.text = postSnapshot['content'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '게시글 데이터를 불러오는 중 오류가 발생했습니다: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePost() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '제목과 내용을 모두 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = '게시글 수정 중 오류가 발생했습니다: ${e.toString()}';
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
        title: Text('게시글 수정', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFFDBEBE), // 앱 바 배경색
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
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '제목',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFDBEBE)),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: '내용',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFDBEBE)),
                      ),
                    ),
                    maxLines: 5,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updatePost,
                    child: _isLoading 
                        ? CircularProgressIndicator() 
                        : Text('게시글 수정'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFDBEBE),
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      textStyle: TextStyle(color: Colors.white), // 글자색을 흰색으로 설정
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ).copyWith(
                      foregroundColor: MaterialStateProperty.all(Colors.white), // 글자색 설정
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
