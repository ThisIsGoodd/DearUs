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
  static const int pageSize = 10; // 한 페이지에 표시할 게시글 수
  int currentPage = 0; // 현재 페이지
  List<DocumentSnapshot> _posts = []; // 현재 페이지의 게시글
  bool _isLoading = false;
  int totalPages = 1; // 전체 페이지 수 (초기값은 1)

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('category', isEqualTo: widget.category)
          .orderBy('createdAt', descending: true)
          .get();

      final allDocuments = querySnapshot.docs;
      setState(() {
        totalPages = (allDocuments.length / pageSize).ceil(); // 전체 페이지 계산
        _posts = allDocuments.skip(currentPage * pageSize).take(pageSize).toList(); // 현재 페이지 데이터
      });
    } catch (e) {
      print('Error loading posts: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changePage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < totalPages) {
      setState(() {
        currentPage = pageIndex;
        _loadPosts();
      });
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
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? Center(
                        child: Text(
                          '게시글이 없습니다.',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          var doc = _posts[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PostDetailPage(postId: doc.id),
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
                                    // 사진 미리보기 (오른쪽 상단)
                                    if (doc['imageBase64'] != null)
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Image.memory(
                                          base64Decode(doc['imageBase64']),
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(width: 12.0),

                                    // 게시글 정보
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // 제목
                                          Text(
                                            doc['title'],
                                            style: const TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          // 내용
                                          Text(
                                            doc['content'],
                                            maxLines: 2, // 최대 2줄로 표시
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 12.0),
                                          // 작성자, 작성시간, 조회수
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                '작성자: ${doc['nickname']}',
                                                style: TextStyle(
                                                  fontSize: 12.0,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(width: 16.0),
                                              Text(
                                                DateFormat('yyyy.MM.dd HH:mm')
                                                    .format(doc['createdAt']
                                                        .toDate()),
                                                style: TextStyle(
                                                  fontSize: 12.0,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(width: 16.0),
                                              Text(
                                                '조회수: ${doc['viewCount'] ?? 0}',
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
                      ),
          ),
          if (totalPages > 1) _buildPaginationControls(), // 페이지네이션 컨트롤
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewPostPage(category: widget.category),
            ),
          );
          _loadPosts(); // 게시글 작성 후 새로고침
        },
        backgroundColor: const Color(0xFFFDBEBE),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed:
                currentPage > 0 ? () => _changePage(currentPage - 1) : null,
          ),
          Text(
            '${currentPage + 1} / $totalPages',
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: currentPage < totalPages - 1
                ? () => _changePage(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
