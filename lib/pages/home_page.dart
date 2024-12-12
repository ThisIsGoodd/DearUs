// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:last_dear_us/pages/category_post_list_page.dart';

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
  int? _daysSinceMeeting;

  final List<String> categories = ['맛집', '카페', '데이트코스', '선물'];

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
              _calculateDaysSinceMeeting();
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
            final connectedUserSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(connectedUserUid)
                .get();
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

  Future<void> _updateNicknamesInBackground() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').get();

      for (var userDoc in userSnapshot.docs) {
        final newNickname = userDoc.data()['nickname'];
        final userId = userDoc.id;

        final postQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: userId)
            .get();

        for (var post in postQuery.docs) {
          await post.reference.update({'nickname': newNickname});
        }
      }
    } catch (e) {
      print('Error updating nicknames: $e');
    }
  }

  void _calculateAnniversaries() {
    if (_selectedDate == null) return;
    final now = DateTime.now();
    _anniversaries.clear();

    for (int i = 100; i <= 10000; i += 100) {
      final anniversary = _selectedDate!.add(Duration(days: i));
      if (anniversary.isAfter(now)) {
        _anniversaries.add({
          'date': anniversary,
          'description': '${i}일 기념일',
        });
      }
    }

    for (int i = 1; i <= 100; i++) {
      final anniversary = DateTime(
          _selectedDate!.year + i, _selectedDate!.month, _selectedDate!.day);
      if (anniversary.isAfter(now)) {
        _anniversaries.add({
          'date': anniversary,
          'description': '${i}주년 기념일',
        });
      }
    }

    if (_connectedUserBirthday != null) {
      for (int i = 0; i <= 100; i++) {
        final birthdayAnniversary = DateTime(
            now.year + i, _connectedUserBirthday!.month, _connectedUserBirthday!.day);
        if (birthdayAnniversary.isAfter(now)) {
          _anniversaries.add({
            'date': birthdayAnniversary,
            'description': '${_connectedUserNickname ?? '연결된 사용자'}의 생일',
          });
        }
      }
    }

    _anniversaries.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    if (_anniversaries.length > 50) {
      _anniversaries = _anniversaries.sublist(0, 50);
    }
  }

  void _calculateDaysSinceMeeting() {
    if (_selectedDate != null) {
      final now = DateTime.now();
      final difference = now.difference(_selectedDate!).inDays;
      setState(() {
        _daysSinceMeeting = difference;
      });
    }
  }

  void _showAnniversariesModal() {
    showDialog(
      context: context,
      builder: (context) {
        final groupedAnniversaries = <String, List<Map<String, dynamic>>>{};
        for (var anniversary in _anniversaries) {
          final dateKey = DateFormat('yyyy-MM-dd').format(anniversary['date']);
          if (!groupedAnniversaries.containsKey(dateKey)) {
            groupedAnniversaries[dateKey] = [];
          }
          groupedAnniversaries[dateKey]!.add(anniversary);
        }

        final dateKeys = groupedAnniversaries.keys.toList();

        return AlertDialog(
          title: Center(
            child: Text(
              '스토리',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFDBEBE),
              ),
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: dateKeys.length,
              itemBuilder: (context, index) {
                final dateKey = dateKeys[index];
                final events = groupedAnniversaries[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        dateKey,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54),
                      ),
                    ),
                    ...events.map((event) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '- ${event['description']}',
                          style: TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
              separatorBuilder: (context, index) => Divider(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Dear US',
              style: TextStyle(
                color: Color(0xFFFDBEBE),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (_daysSinceMeeting != null)
                  Center(
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxHeight: 300,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 300,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/logo.png'),
                                fit: BoxFit.contain,
                                colorFilter: ColorFilter.mode(
                                  Colors.white.withOpacity(0.2),
                                  BlendMode.dstATop,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '함께한 시간은',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '$_daysSinceMeeting일',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFDBEBE),
                                ),
                              ),
                              SizedBox(height: 50),
                              Text(
                                '${DateFormat('yyyy.MM.dd ~').format(_selectedDate!)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextButton(
                onPressed: _showAnniversariesModal,
                child: Text(
                  '스토리',
                  style: TextStyle(
                    color: Color(0xFFFDBEBE),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.2, // 높이 설정 조정
              child: GridView.builder(
                padding: EdgeInsets.zero, // 패딩 제거
                physics: NeverScrollableScrollPhysics(), // 스크롤 비활성화
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2개씩 배치
                  mainAxisSpacing: 8.0, // 세로 간격
                  crossAxisSpacing: 8.0, // 가로 간격
                  childAspectRatio: 3.5, // 버튼 비율 조정
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CategoryPostListPage(category: categories[index]),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.pink[100],
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
