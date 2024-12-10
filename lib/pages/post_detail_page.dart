import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last_dear_us/pages/edit_post_page.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({required this.postId, Key? key}) : super(key: key);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _incrementViewCount(); // 조회수 증가
  }

  Future<void> _incrementViewCount() async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({'viewCount': FieldValue.increment(1)});
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '댓글 내용을 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .add({
          'content': _commentController.text.trim(),
          'author': user.displayName ?? '익명',
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _commentController.clear();
      }
    } catch (e) {
      _showErrorDialog('댓글 작성 중 오류가 발생했습니다: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      _showErrorDialog('댓글 삭제 중 오류가 발생했습니다: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('오류'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '게시글 상세',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFDBEBE),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('게시글을 불러오는 중 오류가 발생했습니다.'));
          }

          final post = snapshot.data!;
          final isAuthor = user != null && user.uid == post['userId'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 게시글 제목
                Text(
                  post['title'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                // 작성자, 작성 시간, 조회수
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '작성자: ${post['nickname']}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Text(
                      '조회수: ${post['viewCount'] ?? 0}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 게시글 내용
                Text(
                  post['content'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // 이미지 표시
                if (post['imageBase64'] != null)
                  Image.memory(
                    base64Decode(post['imageBase64']),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                const SizedBox(height: 20),

                // 수정/삭제 버튼
                if (isAuthor)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPostPage(
                                postId: widget.postId,
                              ),
                            ),
                          );
                        },
                        child: const Text('수정'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDBEBE),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('posts')
                              .doc(widget.postId)
                              .delete();
                          Navigator.pop(context);
                        },
                        child: const Text('삭제'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                const Divider(height: 40, thickness: 1.0, color: Colors.grey),
                const Text(
                  '댓글',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // 댓글 입력 필드
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: '댓글 입력',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // 댓글 작성 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _addComment,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('댓글 작성'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDBEBE),
                  ),
                ),

                // 댓글 목록
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .collection('comments')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('댓글이 없습니다.'));
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final comment = snapshot.data!.docs[index];
                          final isCommentAuthor =
                              user != null && user.uid == comment['userId'];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 2.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ListTile(
                              title: Text(comment['author']),
                              subtitle: Text(comment['content']),
                              trailing: isCommentAuthor
                                  ? IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          _deleteComment(comment.id),
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
