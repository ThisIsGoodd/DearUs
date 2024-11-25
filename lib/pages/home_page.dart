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

  void _calculateDaysSinceMeeting() {
    if (_selectedDate != null) {
      final now = DateTime.now();
      final difference = now.difference(_selectedDate!).inDays;
      setState(() {
        _daysSinceMeeting = difference;
      });
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
        _calculateDaysSinceMeeting();
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
                color: Color(0xFFFDBEBE), // 글자 색상 변경
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
                    // 날짜 헤더
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        dateKey,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                    // 이벤트 리스트
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
              separatorBuilder: (context, index) => Divider(color: Colors.grey), // 섹션 구분선
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
      appBar: AppBar(
        title: Text(
          'Dear US',
          style: TextStyle(
            color: Color(0xFFFDBEBE), // 텍스트 색상 FDBEBE
          ),
        ),
        centerTitle: true, // 텍스트를 중앙 정렬
        backgroundColor: Colors.transparent, // AppBar 배경 투명
        elevation: 0, // 그림자 제거
        iconTheme: IconThemeData(color: Color(0xFFFDBEBE)), // 아이콘 색상도 변경
      ),
      body: Column(
        children: <Widget>[
          Padding(
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
                      Text('처음만난 날: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _pickDate(),
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFFFDBEBE), // 버튼 텍스트 색상 FDBEBE
                            ),
                            child: Text('날짜 수정'),
                          ),
                          TextButton(
                            onPressed: () => _showAnniversariesModal(),
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFFFDBEBE), // 버튼 텍스트 색상 FDBEBE
                            ),
                            child: Text('스토리'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_daysSinceMeeting != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Center(
                        child: Text(
                          '두 사람이 함께한 시간은 $_daysSinceMeeting일입니다!',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center, // 텍스트 중앙 정렬
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          Spacer(), // 위 콘텐츠를 상단으로 밀어줌
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            decoration: BoxDecoration(
              color: Colors.white, // 배경색 (선택 사항)
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)), // 위쪽 둥근 모서리
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(), // 그리드 자체는 스크롤 불가능
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2x2 레이아웃
                mainAxisSpacing: 16.0, // 세로 간격
                crossAxisSpacing: 16.0, // 가로 간격
                childAspectRatio: 1.0, // 정사각형 비율
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryPostListPage(category: categories[index]),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.pink[100], // 박스 색상
                      borderRadius: BorderRadius.circular(8.0), // 둥근 모서리
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
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
