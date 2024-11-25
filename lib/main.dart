// Main.dart 파일: 앱의 진입점
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:last_dear_us/pages/home_page.dart';
import 'package:last_dear_us/pages/calendar_page.dart';
import 'package:last_dear_us/pages/community_page.dart';
import 'package:last_dear_us/pages/profile_page.dart';
import 'package:last_dear_us/pages/login_page.dart';
import 'package:last_dear_us/pages/register_page.dart';
import 'package:last_dear_us/models/user_model.dart';
import 'package:last_dear_us/models/event_model.dart';
import 'package:last_dear_us/models/post_model.dart';
import 'package:last_dear_us/services/auth_service.dart';
import 'package:last_dear_us/services/database_service.dart';
import 'package:last_dear_us/utils/notification_utils.dart'; // NotificationUtils를 사용하기 위해 가져옴
import 'package:last_dear_us/utils/date_utils.dart'; // NotificationUtils를 사용하기 위해 가져옴
import 'package:last_dear_us/widgets/custom_button.dart';
import 'package:last_dear_us/widgets/custom_text_field.dart';
import 'package:last_dear_us/widgets/event_card.dart';
import 'package:last_dear_us/widgets/post_card.dart';
import 'package:intl/intl.dart';
import 'package:last_dear_us/pages/chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
  }

  Future<void> _initializeFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message while in foreground!');
      print('Message data: \${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: \${message.notification}');
        NotificationUtils.showNotification(
          0, // 알림 ID
          message.notification!.title ?? "알림 제목",
          message.notification!.body ?? "알림 내용",
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthWrapper(),
    );
  }
}

// AuthWrapper: 로그인 상태에 따라 페이지 전환
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // FirebaseAuth를 사용하여 로그인 상태 확인
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasData) {
          return MainNavigation();
        } else {
          return LoginPage();
        }
      },
    );
  }
}

// Bottom Navigation을 통해 네 페이지로 이동 가능하게 설정
class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    HomePage(),
    SharedCalendarPage(),
    CommunityPage(),
    ChatPage(connectedUserUid: 'exampleConnectedUserUid'),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat), // 채팅 아이콘 추가
            label: 'Chat', // 채팅 라벨 추가
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.pink.shade100, // 네비게이션바 배경 색상을 연한 분홍색으로 설정
        selectedItemColor: const Color.fromARGB(255, 172, 14, 77), // 선택된 아이템의 색상을 진한 분홍색으로 설정
        unselectedItemColor: const Color.fromARGB(255, 240, 171, 194), // 선택되지 않은 아이템의 색상을 연한 분홍색으로 설정
      ),
    );
  }
}
