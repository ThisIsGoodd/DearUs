// ProfilePage.dart: 내 정보 관리 페이지
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:last_dear_us/pages/login_page.dart';
import 'package:last_dear_us/pages/edit_profile_page.dart';
import 'package:last_dear_us/pages/link_user_page.dart';
import 'package:last_dear_us/pages/contact_us_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage()),
    );
  }

  void _navigateToLinkUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LinkUserPage()),
    );
  }

  void _navigateToContactUs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContactUsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: _navigateToEditProfile,
              child: Text('내 정보 수정'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _navigateToLinkUser,
              child: Text('사용자 연결'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _navigateToContactUs,
              child: Text('문의사항 작성'),
            ),
            Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _signOut,
                  child: Text('Logout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
