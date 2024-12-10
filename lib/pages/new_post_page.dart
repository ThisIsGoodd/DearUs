import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class NewPostPage extends StatefulWidget {
  final String category;
  final bool isEditing;
  final String? postId;
  final String? existingTitle;
  final String? existingContent;

  const NewPostPage({
    required this.category,
    this.isEditing = false,
    this.postId,
    this.existingTitle,
    this.existingContent,
    Key? key,
  }) : super(key: key);

  @override
  _NewPostPageState createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _titleController.text = widget.existingTitle ?? '';
      _contentController.text = widget.existingContent ?? '';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _encodeImageToBase64(File image) async {
    try {
      final bytes = await image.readAsBytes();
      return base64Encode(bytes); // Base64 인코딩
    } catch (e) {
      print('Error encoding image to Base64: $e');
      return null;
    }
  }

  Future<void> _savePost() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      final nickname = userData?['nickname'] ?? '익명';

      String? imageBase64;
      if (_selectedImage != null) {
        imageBase64 = await _encodeImageToBase64(_selectedImage!);
      }

      final postData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'nickname': nickname,
        'userId': user.uid,
        'category': widget.category,
        'createdAt': FieldValue.serverTimestamp(),
        'viewCount': 0,
        'imageBase64': imageBase64, // Base64 이미지 데이터 저장
      };

      if (widget.isEditing && widget.postId != null) {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update(postData);
      } else {
        await FirebaseFirestore.instance.collection('posts').add(postData);
      }

      Navigator.pop(context);
    } catch (e) {
      print('Error saving post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글 작성/수정 중 오류가 발생했습니다.')),
      );
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
        backgroundColor: const Color(0xFFFDBEBE),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 입력 필드
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '제목',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 내용 입력 필드
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: '내용',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),

                    // 이미지 선택 버튼
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('사진 선택'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDBEBE),
                      ),
                    ),

                    // 선택한 이미지 미리보기
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Image.file(
                          _selectedImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 저장 버튼
                    ElevatedButton(
                      onPressed: _savePost,
                      child: Text(widget.isEditing ? '수정하기' : '작성하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDBEBE),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
