import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last_dear_us/pages/edit_post_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;

  PostDetailPage({required this.postId});

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _incrementViewCount(); // 조회수 증가
  }

  void _initializeNotifications() {
    final InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('게시글 삭제'),
        content: Text('정말로 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // 다이얼로그 먼저 닫기
                Navigator.of(dialogContext).pop();
                
                // 게시글 삭제
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.postId)
                    .delete();

                if (context.mounted) {
                  // 게시글 목록으로 돌아가면서 새로고침을 위한 결과값 전달
                  Navigator.of(context).pop(true); // true를 반환하여 삭제 완료를 알림
                }
              } catch (e) {
                if (context.mounted) {
                  _showErrorDialog('게시글 삭제 중 오류가 발생���습니다: $e');
                }
              }
            },
            child: Text('삭제'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      );
    },
  );
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
    _showErrorDialog('댓글 작성 중 오류�� 발생했습니다: ${e.toString()}');
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
        title: Text('오류'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('확인'),
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
      title: Text(
        '게시글 상세',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Color(0xFFFDBEBE),
      iconTheme: IconThemeData(color: Colors.black),
    ),
    body: StreamBuilder(
      stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('게시글을 불러오는 중 오류가 발생했습니다.'));
        }

        var post = snapshot.data!;
        bool isAuthor = user != null && user.uid == post['userId'];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 게시글 제목
              Text(
                post['title'],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
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
              SizedBox(height: 20),
              // 게시글 내용
              Text(
                post['content'],
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20),
              if (isAuthor)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditPostPage(postId: widget.postId)),
                        );
                      },
                      child: Text('수정'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFDBEBE),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _showDeleteConfirmationDialog(context);
                      },
                      child: Text('삭제'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              Divider(height: 40, thickness: 1.0, color: Colors.grey[300]),
              Text('댓글', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: '댓글 입력',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _addComment,
                child: _isLoading ? CircularProgressIndicator() : Text('댓글 작성'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFDBEBE),
                ),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('createdAt', descending: false)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('댓글이 없습니다.'));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var comment = snapshot.data!.docs[index];
                        bool isCommentAuthor = user != null && user.uid == comment['userId'];

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
                                    icon: Icon(Icons.delete),
                                    onPressed: () => _deleteComment(comment.id),
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
