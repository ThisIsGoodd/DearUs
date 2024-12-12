import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditPostPage extends StatefulWidget {
  final String postId;

  const EditPostPage({required this.postId, Key? key}) : super(key: key);

  @override
  _EditPostPageState createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _existingImageBase64;
  File? _selectedImage;
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
      final docSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          _titleController.text = data['title'];
          _contentController.text = data['content'];
          _existingImageBase64 = data['imageBase64']; // 기존 이미지 데이터 가져오기
        });
      }
    } catch (e) {
      print('Error loading post data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _updatePost() async {
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
      String? imageBase64;

      if (_selectedImage != null) {
        // 새 이미지를 선택한 경우
        imageBase64 = await _encodeImageToBase64(_selectedImage!);
      } else {
        // 새 이미지를 선택하지 않으면 기존 이미지를 유지
        imageBase64 = _existingImageBase64;
      }

      final updatedData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'imageBase64': imageBase64, // 업데이트된 이미지 데이터
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update(updatedData);

      Navigator.pop(context);
    } catch (e) {
      print('Error updating post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글 수정 중 오류가 발생했습니다.')),
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
        title: const Text('게시글 수정'),
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

                    // 기존 이미지 또는 새 이미지 미리보기
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Image.file(
                          _selectedImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (_existingImageBase64 != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Image.memory(
                          base64Decode(_existingImageBase64!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 저장 버튼
                    ElevatedButton(
                      onPressed: _updatePost,
                      child: const Text('수정하기'),
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
