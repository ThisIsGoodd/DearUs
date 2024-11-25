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
        title: Text(
          '$category 게시판',
          style: TextStyle(color: Colors.black), // 제목 텍스트 색상
        ),
        centerTitle: true, // 제목을 가운데 정렬
        backgroundColor: Colors.white, // AppBar 배경색 흰색
        elevation: 1.0, // AppBar 그림자 효과
        iconTheme: IconThemeData(color: Colors.black), // 뒤로가기 버튼 아이콘 색상
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('category', isEqualTo: category)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // 로딩 상태 처리
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // 게시글이 없을 경우 처리
          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('아직 게시글이 없습니다.'));
          }

          // 게시글 리스트 출력
          return ListView.builder(
            padding: const EdgeInsets.all(16.0), // 리스트 전체 패딩 추가
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0), // 카드 간 간격 추가
                elevation: 2.0, // 카드 그림자
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), // 카드 모서리 둥글게
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0), // 카드 내부 여백
                  title: Text(
                    doc['title'], // 게시글 제목
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '작성자: ${doc['nickname']}', // 작성자 닉네임 출력
                    style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                  ),
                  onTap: () {
                    // 게시글 상세 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailPage(postId: doc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 새 게시글 작성 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewPostPage(category: category),
            ),
          );
        },
        child: Icon(Icons.add), // 플러스 아이콘
      ),
    );
  }
}
