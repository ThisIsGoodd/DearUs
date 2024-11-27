// lib/models/connection_model.dart
// connection_model.dart: 사용자 연결 모델
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionModel {
  String userUid;
  String connectedUserUid;

  ConnectionModel({required this.userUid, required this.connectedUserUid});

  // Firestore에서 가져온 데이터를 모델로 변환하는 메서드
  factory ConnectionModel.fromMap(Map<String, dynamic> data) {
    return ConnectionModel(
      userUid: data['userUid'],
      connectedUserUid: data['connectedUserUid'],
    );
  }

  // 모델을 Firestore에 저장 가능한 형태로 변환하는 메서드
  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'connectedUserUid': connectedUserUid,
    };
  }
}

/*
파이어스토어에 데이터를 저장할 떄
final connection = ConnectionModel(userUid: currentUser.uid, connectedUserUid: otherUserUid);
await FirebaseFirestore.instance.collection('connections').doc(currentUser.uid).set(connection.toMap());

파이어스토어에서 데이터를 가져올 때
final snapshot = await FirebaseFirestore.instance.collection('connections').doc(currentUser.uid).get();
if (snapshot.exists) {
  final connection = ConnectionModel.fromMap(snapshot.data()!);
  // connection.connectedUserUid 사용 가능
}
*/