// user_model.dart: 사용자 정보 모델
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? uid;
  String? email;
  String? nickname;
  DateTime? birthdate;
  String? connectedUserUid;

  UserModel({
    this.uid,
    this.email,
    this.nickname,
    this.birthdate,
    this.connectedUserUid,
  });

  // Firestore에서 가져온 데이터를 모델로 변환하는 메서드
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      nickname: data['nickname'],
      birthdate: data['birthdate'] != null ? (data['birthdate'] as Timestamp).toDate() : null,
      connectedUserUid: data['connectedUserUid'],
    );
  }

  // 모델을 Firestore에 저장 가능한 형태로 변환하는 메서드
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'birthdate': birthdate != null ? Timestamp.fromDate(birthdate!) : null,
      'connectedUserUid': connectedUserUid,
    };
  }
}
