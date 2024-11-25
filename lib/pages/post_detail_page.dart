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

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _listenForComments();
  }

  void _initializeNotifications() {
    final InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _listenForComments() {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docChanges.isNotEmpty) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            _sendNotification("새 댓글이 작성되었습니다", change.doc['content']);
          }
        }
      }
    });
  }

  Future<void> _sendNotification(String title, String body) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        channelDescription: 'channel_description',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails);
  }

  Future<void> _deletePost(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).delete();
      Navigator.pop(context);
    } catch (e) {
      _showErrorDialog('게시글 삭제 중 오류가 발생했습니다: $e');
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
        title: Text('게시글 상세'),
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
                Text(post['title'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('작성자: ${post['nickname']}'),
                SizedBox(height: 20),
                Text(post['content']),
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
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _deletePost(context),
                        child: Text('삭제'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ],
                  ),
                Divider(height: 40),
                Text('댓글', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 10),
                ],
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

                          return ListTile(
                            title: Text(comment['author']),
                            subtitle: Text(comment['content']),
                            trailing: isCommentAuthor
                                ? IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () => _deleteComment(comment.id),
                                  )
                                : null,
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
