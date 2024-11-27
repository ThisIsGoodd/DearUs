import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:last_dear_us/models/user_model.dart';
import 'package:last_dear_us/pages/login_page.dart';
import 'package:last_dear_us/services/database_service.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

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

  final DatabaseService _databaseService = DatabaseService();

  int _currentStep = 0; // 현재 단계
  final int _totalSteps = 4; // 총 단계 수

  Future<void> _register() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      // Firebase Auth로 사용자 생성
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

      await _databaseService.saveUser(newUser);

      // 회원가입 성공 시 로그인 페이지로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _errorMessage = '이미 사용 중인 이메일입니다.';
        } else if (e.code == 'weak-password') {
          _errorMessage = '비밀번호가 너무 약합니다.';
        } else {
          _errorMessage = '회원가입 중 오류가 발생했습니다. 다시 시도해주세요.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '회원가입 중 오류가 발생했습니다. 다시 시도해주세요.';
      });
    }
  }

  Future<void> _nextStep() async {
    setState(() {
      _errorMessage = null;
    });

    if (_currentStep == 0) {
      // 닉네임 중복 체크
      if (_nicknameController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = '닉네임을 입력해주세요.';
        });
        return;
      }
      bool nicknameExists = await _databaseService.checkIfNicknameExists(_nicknameController.text.trim());
      if (nicknameExists) {
        setState(() {
          _errorMessage = '이미 사용 중인 닉네임입니다.';
        });
        return;
      }
    } else if (_currentStep == 1) {
      // 이메일 중복 체크
      if (_emailController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = '이메일을 입력해주세요.';
        });
        return;
      }
      try {
        final List<String> signInMethods =
            await FirebaseAuth.instance.fetchSignInMethodsForEmail(_emailController.text.trim());
        if (signInMethods.isNotEmpty) {
          setState(() {
            _errorMessage = '이미 사용 중인 이메일입니다.';
          });
          return;
        }
      } catch (e) {
        setState(() {
          _errorMessage = '이메일 확인 중 오류가 발생했습니다.';
        });
        return;
      }
    } else if (_currentStep == 2) {
      // 비밀번호 확인
      if (_passwordController.text.trim().isEmpty || _confirmPasswordController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = '비밀번호를 입력해주세요.';
        });
        return;
      }
      if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
        setState(() {
          _errorMessage = '비밀번호가 일치하지 않습니다.';
        });
        return;
      }
    } else if (_currentStep == 3) {
      // 생년월일 확인
      if (_selectedBirthdate == null) {
        setState(() {
          _errorMessage = '생년월일을 선택해주세요.';
        });
        return;
      }
    }

    // 다음 단계로 이동
    setState(() {
      if (_currentStep < _totalSteps - 1) {
        _currentStep++;
      } else {
        _register(); // 마지막 단계에서 회원가입 처리
      }
    });
  }

  Future<void> _pickBirthdate() async {
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

  Widget _buildStepProgressBar() {
    return StepProgressIndicator(
      totalSteps: _totalSteps,
      currentStep: _currentStep + 1,
      size: 8,
      selectedColor: Color(0xFFFDBEBE),
      unselectedColor: Colors.grey[300]!,
      roundedEdges: Radius.circular(10),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: // 닉네임 입력 단계
        return TextField(
          controller: _nicknameController,
          decoration: InputDecoration(
            hintText: '닉네임 입력',
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      case 1: // 이메일 입력 단계
        return TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: '이메일 입력',
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      case 2: // 비밀번호 입력 단계
        return Column(
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '비밀번호 입력',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '비밀번호 확인',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        );
      case 3: // 생년월일 선택 단계
        return Row(
          children: [
            Expanded(
              child: Text(
                _selectedBirthdate == null
                    ? '생년월일을 선택하세요'
                    : '생년월일: ${DateFormat('yyyy-MM-dd').format(_selectedBirthdate!)}',
                style: TextStyle(fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: _pickBirthdate,
              child: Text(
                'Pick Date',
                style: TextStyle(
                  color: Color(0xFFFDBEBE),
                ),
              ),
            ),
          ],
        );
      default:
        return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFFDBEBE)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Image.asset(
          'assets/logo.png',
          height: 40,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            _buildStepProgressBar(),
            SizedBox(height: 20),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
            ],
            _buildStepContent(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFDBEBE),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _currentStep < _totalSteps - 1 ? '다음' : '회원가입 완료',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
