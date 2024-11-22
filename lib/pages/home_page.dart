import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? _selectedDate;
  DateTime? _connectedUserBirthday;
  String? _connectedUserNickname;
  List<Map<String, dynamic>> _anniversaries = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSelectedDate();
    _loadConnectedUserBirthday();
  }

  Future<void> _loadSelectedDate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data.containsKey('selectedDate')) {
            setState(() {
              _selectedDate = (data['selectedDate'] as Timestamp).toDate();
              _calculateAnniversaries();
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '기념일 데이터를 불러오는 중 오류가 발생했습니다.';
      });
    }
  }

  Future<void> _loadConnectedUserBirthday() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snapshot.exists) {
          final connectedUserUid = snapshot.data()?['connectedUserUid'];
          if (connectedUserUid != null) {
            final connectedUserSnapshot = await FirebaseFirestore.instance.collection('users').doc(connectedUserUid).get();
            if (connectedUserSnapshot.exists) {
              final birthdate = connectedUserSnapshot.data()?['birthdate'];
              _connectedUserNickname = connectedUserSnapshot.data()?['nickname'];
              if (birthdate != null) {
                setState(() {
                  _connectedUserBirthday = (birthdate as Timestamp).toDate();
                  _calculateAnniversaries();
                });
              }
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '연결된 사용자 생일 데이터를 불러오는 중 오류가 발생했습니다.';
      });
    }
  }

  void _calculateAnniversaries() {
    if (_selectedDate == null) return;
    final now = DateTime.now();
    _anniversaries.clear();

    // 100일 단위 기념일 계산
    for (int i = 100; i <= 10000; i += 100) {
      final anniversary = _selectedDate!.add(Duration(days: i));
      if (anniversary.isAfter(now)) {
        _anniversaries.add({
          'date': anniversary,
          'description': '${i}일 기념일',
        });
      }
    }

    // 1년 단위 기념일 계산
    for (int i = 1; i <= 100; i++) {
      final anniversary = DateTime(_selectedDate!.year + i, _selectedDate!.month, _selectedDate!.day);
      if (anniversary.isAfter(now)) {
        _anniversaries.add({
          'date': anniversary,
          'description': '${i}주년 기념일',
        });
      }
    }

    // 연결된 사용자 생일 계산
    if (_connectedUserBirthday != null) {
      for (int i = 0; i <= 100; i++) {
        final birthdayAnniversary = DateTime(now.year + i, _connectedUserBirthday!.month, _connectedUserBirthday!.day);
        if (birthdayAnniversary.isAfter(now)) {
          _anniversaries.add({
            'date': birthdayAnniversary,
            'description': '${_connectedUserNickname ?? '연결된 사용자'}의 생일',
          });
        }
      }
    }

    // 날짜 기준 오름차순 정렬
    _anniversaries.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // 최대 50개만 유지
    if (_anniversaries.length > 50) {
      _anniversaries = _anniversaries.sublist(0, 50);
    }
  }

  Future<void> _pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(Duration(days: 365 * 10)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _calculateAnniversaries();
      });
      _saveSelectedDate(date);
    }
  }

  Future<void> _saveSelectedDate(DateTime date) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'selectedDate': Timestamp.fromDate(date),
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '날짜 저장 중 오류가 발생했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Padding(
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
            if (_selectedDate == null)
              ElevatedButton(
                onPressed: () => _pickDate(),
                child: Text('날짜 선택'),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('선택한 날짜: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'),
                  TextButton(
                    onPressed: () => _pickDate(),
                    child: Text('날짜 수정'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text('다가오는 기념일들:'),
              Expanded(
                child: ListView.builder(
                  itemCount: _anniversaries.length,
                  itemBuilder: (context, index) {
                    final anniversary = _anniversaries[index];
                    return ListTile(
                      title: Text('${DateFormat('yyyy-MM-dd').format(anniversary['date'])} - ${anniversary['description']}'),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
