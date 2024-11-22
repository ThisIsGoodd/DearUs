import 'package:flutter/material.dart';
import 'package:last_dear_us/pages/category_post_list_page.dart';

class CommunityPage extends StatelessWidget {
  final List<String> categories = ['맛집', '카페', '데이트코스', '선물'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('커뮤니티'),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(categories[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryPostListPage(category: categories[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
