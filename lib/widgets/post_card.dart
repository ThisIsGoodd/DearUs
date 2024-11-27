// lib/widgets/post_card.dart
// PostCard 위젯 정의
import 'package:flutter/material.dart';
import 'package:last_dear_us/models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(post.title),
        subtitle: Text(post.content),
        trailing: Text("조회수: ${post.viewCount}"),
      ),
    );
  }
}