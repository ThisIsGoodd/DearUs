// Post 모델 정의
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String authorUid;
  final String title;
  final String content;
  final DateTime createdAt;
  final int viewCount;

  PostModel({
    required this.postId,
    required this.authorUid,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.viewCount,
  });

  factory PostModel.fromMap(Map<String, dynamic> data) {
    return PostModel(
      postId: data['postId'],
      authorUid: data['authorUid'],
      title: data['title'],
      content: data['content'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      viewCount: data['viewCount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorUid': authorUid,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'viewCount': viewCount,
    };
  }
}