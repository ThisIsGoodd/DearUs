import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LinkUserPage extends StatefulWidget {
  @override
  _LinkUserPageState createState() => _LinkUserPageState();
}

class _LinkUserPageState extends State<LinkUserPage> {
  final _inviteCodeController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  String? _connectedUserNickname;

  @override
  void initState() {
    super.initState();
    _fetchConnectedUser();
  }

  Future<void> _fetchConnectedUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (snapshot.exists && snapshot.data()!['connectedUserUid'] != null) {
          final connectedUserUid = snapshot.data()!['connectedUserUid'];
          final connectedUserSnapshot = await FirebaseFirestore.instance.collection('users').doc(connectedUserUid).get();
          if (connectedUserSnapshot.exists) {
            setState(() {
              _connectedUserNickname = connectedUserSnapshot.data()!['nickname'];
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '연결된 사용자 정보를 가져오는 중 오류가 발생했습니다: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateInviteCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _inviteCodeController.text = user.uid;
      });
    }
  }

  Future<void> _connectUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final inviteCode = _inviteCodeController.text.trim();

        // 현재 사용자의 연결 상태 확인
        final currentUserSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (currentUserSnapshot.exists && currentUserSnapshot.data()!['connectedUserUid'] != null) {
          setState(() {
            _errorMessage = '이미 연결된 사용자가 있습니다.';
          });
          return;
        }

        // 연결하려는 사용자의 연결 상태 확인
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(inviteCode).get();
        if (snapshot.exists && inviteCode != currentUser.uid) {
          final connectedUserUid = snapshot.data()!['connectedUserUid'];
          if (connectedUserUid != null) {
            setState(() {
              _errorMessage = '연결하려는 사용자가 이미 다른 사용자와 연결되어 있습니다.';
            });
            return;
          }

          // 두 사용자 간 연결 처리
          WriteBatch batch = FirebaseFirestore.instance.batch();

          final currentUserDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
          final inviteUserDocRef = FirebaseFirestore.instance.collection('users').doc(inviteCode);

          batch.update(currentUserDocRef, {'connectedUserUid': inviteCode});
          batch.update(inviteUserDocRef, {'connectedUserUid': currentUser.uid});

          await batch.commit();

          setState(() {
            _connectedUserNickname = snapshot.data()!['nickname'];
          });
        } else {
          setState(() {
            _errorMessage = '유효하지 않은 초대 코드입니다.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '사용자 연결 중 오류가 발생했습니다: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disconnectUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (snapshot.exists && snapshot.data()!['connectedUserUid'] != null) {
          final connectedUserUid = snapshot.data()!['connectedUserUid'];

          // 연결 해제 처리
          await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
            'connectedUserUid': FieldValue.delete(),
          });
          await FirebaseFirestore.instance.collection('users').doc(connectedUserUid).update({
            'connectedUserUid': FieldValue.delete(),
          });

          setState(() {
            _connectedUserNickname = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '연결 해제 중 오류가 발생했습니다: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasConnectedUser = _connectedUserNickname != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '사용자 연결',
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
              child: hasConnectedUser
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 10),
                        ],
                        Text(
                          '연결된 사용자: $_connectedUserNickname',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: _disconnectUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFDBEBE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: Text(
                              '연결 해제',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 10),
                        ],
                        ElevatedButton(
                          onPressed: _generateInviteCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFDBEBE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Text(
                            '내 초대 코드 생성',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _inviteCodeController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: '내 초대 코드',
                            filled: true,
                            fillColor: Colors.pink.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          decoration: InputDecoration(
                            labelText: '연결할 사용자의 초대 코드 입력',
                            filled: true,
                            fillColor: Colors.pink.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          controller: _inviteCodeController,
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: _connectUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFDBEBE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: Text(
                              '사용자 연결',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}
