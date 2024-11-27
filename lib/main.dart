// Main.dart 파일: 앱의 진입점
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:last_dear_us/pages/chat_page.dart';
import 'package:last_dear_us/pages/home_page.dart';
import 'package:last_dear_us/pages/calendar_page.dart';
import 'package:last_dear_us/pages/profile_page.dart';
import 'package:last_dear_us/pages/login_page.dart';
import 'package:last_dear_us/pages/register_page.dart';
import 'package:last_dear_us/utils/notification_utils.dart';

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
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        NotificationUtils.showNotification(
          0,
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
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
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

  String? connectedUserUid;
  String? connectedUserNickname;

  @override
  void initState() {
    super.initState();
    _fetchConnectedUserInfo();
  }

  Future<void> _fetchConnectedUserInfo() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final String uid = userDoc['connectedUserUid'] ?? '';

        if (uid.isNotEmpty) {
          final DocumentSnapshot connectedUserDoc =
              await FirebaseFirestore.instance.collection('users').doc(uid).get();

          if (connectedUserDoc.exists) {
            setState(() {
              connectedUserUid = uid;
              connectedUserNickname = connectedUserDoc['nickname'] ?? 'Unknown'; // 연결된 사용자 닉네임
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      HomePage(),
      SharedCalendarPage(),
      (connectedUserUid != null && connectedUserNickname != null)
          ? ChatPage(
              connectedUserUid: connectedUserUid!,
              connectedUserNickname: connectedUserNickname!,
            )
          : Center(child: CircularProgressIndicator()),
      ProfilePage(),
    ];

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

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
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.pink.shade100,
        selectedItemColor: const Color.fromARGB(255, 172, 14, 77),
        unselectedItemColor: const Color.fromARGB(255, 240, 171, 194),
      ),
    );
  }
}
