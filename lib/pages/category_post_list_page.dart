import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:last_dear_us/pages/post_detail_page.dart';
import 'package:last_dear_us/pages/new_post_page.dart';

class CategoryPostListPage extends StatefulWidget {
  final String category;

  const CategoryPostListPage({required this.category, Key? key})
      : super(key: key);

  @override
  _CategoryPostListPageState createState() => _CategoryPostListPageState();
}

class _CategoryPostListPageState extends State<CategoryPostListPage> {
  @override
  void initState() {
    super.initState();
    _updateNicknamesOnLoad();
  }

  Future<void> _updateNicknamesOnLoad() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').get();

      for (var userDoc in userSnapshot.docs) {
        final newNickname = userDoc.data()['nickname'];
        final userId = userDoc.id;

        // 해당 사용자가 작성한 모든 게시물 닉네임 업데이트
        final postQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: userId)
            .get();

        for (var post in postQuery.docs) {
          await post.reference.update({'nickname': newNickname});
        }
      }
    } catch (e) {
      print('Error updating nicknames: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.category} 게시판',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFDBEBE),
        elevation: 1.0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('category', isEqualTo: widget.category)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                '게시글이 없습니다.',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final data = post.data() as Map<String, dynamic>?;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailPage(postId: post.id),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 3.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFFFDBEBE), width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        if (data?.containsKey('imageBase64') == true &&
                            data?['imageBase64'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.memory(
                              base64Decode(data!['imageBase64']),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data?['title'] ?? '제목 없음',
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                data?['content'] ?? '내용 없음',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '작성자: ${data?['nickname'] ?? '알 수 없음'}',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  Text(
                                    data?.containsKey('createdAt') == true
                                        ? DateFormat('yyyy.MM.dd HH:mm')
                                            .format(
                                                data!['createdAt'].toDate())
                                        : '작성일 없음',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  Text(
                                    '조회수: ${data?['viewCount'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewPostPage(category: widget.category),
            ),
          );
        },
        backgroundColor: const Color(0xFFFDBEBE),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
