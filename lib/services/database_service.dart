// lib/services/database_service.dart
// DatabaseService: Firestore 관련 서비스
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last_dear_us/models/event_model.dart';
import 'package:last_dear_us/models/post_model.dart';
import 'package:last_dear_us/models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 사용자 정보 저장
  Future<void> saveUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print(e.toString());
    }
  }

  // 이벤트 추가
  Future<void> addEvent(EventModel event) async {
    try {
      await _db.collection('events').doc(event.eventId).set(event.toMap());
    } catch (e) {
      print(e.toString());
    }
  }

  // 게시글 추가
  Future<void> addPost(PostModel post) async {
    try {
      await _db.collection('posts').doc(post.postId).set(post.toMap());
    } catch (e) {
      print(e.toString());
    }
  }
  // 닉네임 중복 체크 메서드
  Future<bool> checkIfNicknameExists(String nickname) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking nickname: $e');
      return false;
    }
  }
}
