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
  final _selectedDateController = TextEditingController(); // 처음 만난 날 필드
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
            _selectedDateController.text = data['selectedDate'] != null
                ? (data['selectedDate'] as Timestamp).toDate().toString().split(' ')[0]
                : ''; // 처음 만난 날 로드
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
          'selectedDate': Timestamp.fromDate(DateTime.parse(_selectedDateController.text)), // 처음 만난 날 저장
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      readOnly: onTap != null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '내 정보 수정',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFFFDBEBE),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
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
                  _buildTextField(
                    controller: _nicknameController,
                    labelText: '닉네임',
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    controller: _birthdateController,
                    labelText: '생년월일 (yyyy-MM-dd)',
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
                  _buildTextField(
                    controller: _selectedDateController,
                    labelText: '처음 만난 날 (yyyy-MM-dd)',
                    onTap: () async {
                      DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        _selectedDateController.text = date.toString().split(' ')[0];
                      }
                    },
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFDBEBE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text(
                        '저장',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
