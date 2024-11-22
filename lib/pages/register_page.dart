import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:last_dear_us/models/user_model.dart';
import 'package:last_dear_us/pages/login_page.dart';
import 'package:last_dear_us/services/database_service.dart';
import 'package:last_dear_us/widgets/custom_button.dart';
import 'package:last_dear_us/widgets/custom_text_field.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  DateTime? _selectedBirthdate;
  String? _errorMessage;

  Future<void> _register() async {
    setState(() {
      _errorMessage = null;
    });

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }
    if (_selectedBirthdate == null) {
      setState(() {
        _errorMessage = 'Please select your birthdate';
      });
      return;
    }

    try {
      // 닉네임 중복 체크
      bool nicknameExists = await DatabaseService().checkIfNicknameExists(_nicknameController.text.trim());
      if (nicknameExists) {
        setState(() {
          _errorMessage = 'Nickname is already taken';
        });
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Firestore에 사용자 정보 저장
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        email: _emailController.text.trim(),
        nickname: _nicknameController.text.trim(),
        birthdate: _selectedBirthdate!,
      );
      await DatabaseService().saveUser(newUser);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _errorMessage = 'The email address is already in use';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'The password is too weak';
        } else {
          _errorMessage = 'An error occurred. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  void _pickBirthdate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedBirthdate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 10),
            ],
            CustomTextField(
              controller: _emailController,
              label: 'Email',
            ),
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              obscureText: true,
            ),
            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              obscureText: true,
            ),
            CustomTextField(
              controller: _nicknameController,
              label: 'Nickname',
            ),
            SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(_selectedBirthdate == null
                      ? 'Select Birthdate'
                      : 'Birthdate: ${DateFormat('yyyy-MM-dd').format(_selectedBirthdate!)}'),
                ),
                TextButton(
                  onPressed: _pickBirthdate,
                  child: Text('Pick Date'),
                ),
              ],
            ),
            SizedBox(height: 20),
            CustomButton(
              onPressed: _register,
              text: 'Register',
            ),
          ],
        ),
      ),
    );
  }
}
