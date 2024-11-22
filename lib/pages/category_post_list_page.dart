import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last_dear_us/pages/post_detail_page.dart';
import 'package:last_dear_us/pages/new_post_page.dart';

class CategoryPostListPage extends StatelessWidget {
  final String category;

  CategoryPostListPage({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category 게시판'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('category', isEqualTo: category)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('아직 게시글이 없습니다.'));
          }

          // 디버깅용 로그 추가
          print("Data Length: \${snapshot.data!.docs.length}");
          snapshot.data!.docs.forEach((doc) {
            print("Document Data: \${doc.data()}");  // 각 문서의 데이터 출력
          });

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['title']),
                subtitle: Text('작성자: ${doc['author']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailPage(postId: doc.id),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewPostPage(category: category),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
