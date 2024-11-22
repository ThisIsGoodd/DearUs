// EditProfilePage.dart: 내 정보 수정 페이지
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nicknameController = TextEditingController();
  final _birthdateController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            _nicknameController.text = data['nickname'] ?? '';
            _birthdateController.text = data['birthdate'] != null
                ? (data['birthdate'] as Timestamp).toDate().toString().split(' ')[0]
                : '';
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '사용자 정보를 불러오는 중 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'nickname': _nicknameController.text.trim(),
          'birthdate': Timestamp.fromDate(DateTime.parse(_birthdateController.text)),
        });
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '사용자 정보를 저장하는 중 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 정보 수정'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                    SizedBox(height: 10),
                  ],
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(labelText: '닉네임'),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _birthdateController,
                    decoration: InputDecoration(labelText: '생년월일 (yyyy-MM-dd)'),
                    onTap: () async {
                      DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        _birthdateController.text = date.toString().split(' ')[0];
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveUserData,
                    child: Text('저장'),
                  ),
                ],
              ),
            ),
    );
  }
}