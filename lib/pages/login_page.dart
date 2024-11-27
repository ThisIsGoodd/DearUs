import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:last_dear_us/main.dart';
import 'package:last_dear_us/pages/register_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _errorMessage;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      // Firebase Auth로 로그인 시도
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 이메일 인증 여부 확인
      if (!userCredential.user!.emailVerified) {
        setState(() {
          _errorMessage = '이메일 인증이 완료되지 않았습니다. 이메일을 확인해주세요.';
        });

        // 이메일 인증 재발송 옵션 제공
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.pink),
                SizedBox(width: 8),
                Text(
                  '이메일 인증 필요',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
            content: Text(
              '이메일 인증이 완료되지 않았습니다. 인증 이메일을 다시 보내시겠습니까?',
              style: TextStyle(color: Colors.grey[800]),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await userCredential.user!.sendEmailVerification();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('인증 이메일이 다시 발송되었습니다.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.pink,
                    ),
                  );
                },
                child: Text(
                  '다시 보내기',
                  style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '취소',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
        return;
      }

      // 이메일 인증 완료된 경우 메인 페이지로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainNavigation()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          _errorMessage = '이메일이 존재하지 않거나 비밀번호가 틀렸습니다.';
        } else {
          _errorMessage = '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
      });
    }
  }

  void _navigateToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 80),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logo_pull.png', // 로고 이미지 경로
                      height: 250,
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
              SizedBox(height: 40),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
              ],
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: '이메일 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '비밀번호 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '계속하기',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _navigateToRegisterPage,
                  child: Text(
                    '계정이 없으신가요? 회원가입',
                    style: TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
