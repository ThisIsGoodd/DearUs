// lib/pages/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:last_dear_us/utils/notification_utils.dart';

class SharedCalendarPage extends StatefulWidget {
  @override
  _SharedCalendarPageState createState() => _SharedCalendarPageState();
}

class _SharedCalendarPageState extends State<SharedCalendarPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<Appointment> _appointments = [];
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

   Future<void> _fetchAppointments() async {
    if (currentUser != null) {
      try {
        print("Fetching events for user: \${currentUser!.uid}");
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
        final connectedUserUid = userDoc.data()?['connectedUserUid'];
        
        List<Appointment> fetchedAppointments = [];

        // 현재 사용자와 연결된 사용자의 약속을 가져오기
        List<String> userUids = [currentUser!.uid];
        if (connectedUserUid != null) {
          userUids.add(connectedUserUid);
        }

        for (String uid in userUids) {
          QuerySnapshot snapshot = await FirebaseFirestore.instance
              .collection('events')
              .where('userId', isEqualTo: uid)
              .get();

          fetchedAppointments.addAll(snapshot.docs.map((doc) {
            final description = doc['description'] ?? '';
            return Appointment(
              startTime: (doc['startTime'] as Timestamp).toDate(),
              endTime: (doc['endTime'] as Timestamp).toDate(),
              subject: doc['title'],
              color: uid == currentUser!.uid ? Colors.blue : Colors.green,
              notes: '\${doc.id}|||\$description',
            );
          }).toList());
        }

        if (mounted) {
          setState(() {
            _appointments = fetchedAppointments;
          });
        }
      } catch (e) {
        print("Error while fetching events: \$e");
        if (mounted) {
          _showErrorDialog('일정을 불러오는 중 오류가 발생했습니다: \$e');
        }
      }
    }
  }

  Future<void> _addEvent(AppointmentDetails details) async {
    if (currentUser != null) {
      try {
        DocumentReference eventRef = await FirebaseFirestore.instance.collection('events').add({
          'userId': currentUser!.uid,
          'title': details.title,
          'startTime': Timestamp.fromDate(details.startTime),
          'endTime': Timestamp.fromDate(details.endTime),
          'description': details.description,
        });

        await eventRef.update({
          'eventId': eventRef.id
        });

        if (mounted) {
          _fetchAppointments();
        }

        // 연결된 사용자에게 알림 보내기
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
        final connectedUserUid = userDoc.data()?['connectedUserUid'];
        if (connectedUserUid != null) {
          final connectedUserDoc = await FirebaseFirestore.instance.collection('users').doc(connectedUserUid).get();
          final connectedUserToken = connectedUserDoc.data()?['fcmToken'];
          if (connectedUserToken != null) {
            NotificationUtils.showNotification(
              0,
              '새로운 일정이 추가되었습니다',
              '\${details.title} 일정이 추가되었습니다.',
            );
          }
        }
      } catch (e) {
        print("Error adding event: \$e");
        if (mounted) {
          _showErrorDialog('일정을 추가하는 중 오류가 발생했습니다: \$e');
        }
      }
    }
  }

  Future<void> _deleteEvent(Appointment appointment) async {
    if (currentUser != null && appointment.notes != null) {
      final eventId = appointment.notes!.split('|||')[0];
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .get();
            
        if (snapshot.exists && snapshot.data()?['userId'] == currentUser!.uid) {
          await FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .delete();
          _fetchAppointments();
        } else {
          _showErrorDialog('삭제 권한이 없습니다.');
        }
      } catch (e) {
        _showErrorDialog('삭제 중 오류가 발생했습니다: \$e');
      }
    }
  }

  Future<void> _editEvent(Appointment appointment) async {
    if (currentUser != null && appointment.notes != null) {
      final eventId = appointment.notes!.split('|||')[0];
      String description = appointment.notes!.split('|||')[1];
      String title = appointment.subject;
      DateTime startTime = appointment.startTime;
      DateTime endTime = appointment.endTime;

      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // 모서리 둥글게
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 제목
                        Text(
                          '일정 수정',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFDBEBE), // 메인 색상
                          ),
                        ),
                        SizedBox(height: 16),

                        // 일정 제목 입력 필드
                        TextField(
                          controller: TextEditingController(text: title),
                          decoration: InputDecoration(
                            labelText: '일정 제목',
                            labelStyle: TextStyle(color: Color(0xFFFDBEBE)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white, // 배경을 흰색으로 설정
                          ),
                          onChanged: (value) => title = value,
                        ),
                        SizedBox(height: 16),

                        // 일정 내용 입력 필드
                        TextField(
                          controller: TextEditingController(text: description),
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: '일정 내용',
                            labelStyle: TextStyle(color: Color(0xFFFDBEBE)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white, // 배경을 흰색으로 설정
                          ),
                          onChanged: (value) => description = value,
                        ),
                        SizedBox(height: 16),

                        // 시간 선택
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 시작 시간
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '시작 시간',
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      DateTime? pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: startTime,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (pickedDate != null) {
                                        TimeOfDay? pickedTime = await showTimePicker(
                                          context: context,
                                          initialTime:
                                              TimeOfDay.fromDateTime(startTime),
                                        );
                                        if (pickedTime != null) {
                                          setState(() {
                                            startTime = DateTime(
                                              pickedDate.year,
                                              pickedDate.month,
                                              pickedDate.day,
                                              pickedTime.hour,
                                              pickedTime.minute,
                                            );
                                          });
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.white, // 버튼 텍스트 색상
                                      side: BorderSide(color: Color(0xFFFDBEBE)), // 테두리 색상
                                    ),
                                    child: Text(
                                      '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // 종료 시간
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '종료 시간',
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      DateTime? pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: endTime,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (pickedDate != null) {
                                        TimeOfDay? pickedTime = await showTimePicker(
                                          context: context,
                                          initialTime:
                                              TimeOfDay.fromDateTime(endTime),
                                        );
                                        if (pickedTime != null) {
                                          setState(() {
                                            endTime = DateTime(
                                              pickedDate.year,
                                              pickedDate.month,
                                              pickedDate.day,
                                              pickedTime.hour,
                                              pickedTime.minute,
                                            );
                                          });
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.white, // 버튼 텍스트 색상
                                      side: BorderSide(color: Color(0xFFFDBEBE)), // 테두리 색상
                                    ),
                                    child: Text(
                                      '${endTime.year}-${endTime.month.toString().padLeft(2, '0')}-${endTime.day.toString().padLeft(2, '0')} ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // 액션 버튼 (취소, 저장)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                '취소',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                if (currentUser != null &&
                                    appointment.notes != null) {
                                  try {
                                    final snapshot = await FirebaseFirestore.instance
                                        .collection('events')
                                        .doc(eventId)
                                        .get();

                                    if (snapshot.exists &&
                                        snapshot.data()?['userId'] ==
                                            currentUser!.uid) {
                                      await FirebaseFirestore.instance
                                          .collection('events')
                                          .doc(eventId)
                                          .update({
                                        'title': title,
                                        'startTime': Timestamp.fromDate(startTime),
                                        'endTime': Timestamp.fromDate(endTime),
                                        'description': description,
                                      });
                                      _fetchAppointments();
                                    } else {
                                      _showErrorDialog('수정 권한이 없습니다.');
                                    }
                                  } catch (e) {
                                    _showErrorDialog('수정 중 오류가 발생했습니다: \$e');
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Color(0xFFFDBEBE), // 버튼 색상
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // 버튼 둥글게
                                ),
                              ),
                              child: Text('저장'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }
  }


  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('오류'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('확인'),
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
        title: Text('일정 공유 달력', 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFFFDBEBE),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SfCalendar(
        view: CalendarView.month,
        dataSource: AppointmentDataSource(_appointments),
        monthViewSettings: MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
          showTrailingAndLeadingDates: false,
          dayFormat: 'EEE',
          agendaStyle: AgendaStyle(
            backgroundColor: Color(0xFFFFF9F9),
            appointmentTextStyle: TextStyle(color: Colors.black),
          ),
        ),
        onTap: (CalendarTapDetails details) {
          if (details.appointments != null && details.appointments!.isNotEmpty) {
            // Display list of appointments for the selected date
            List<Appointment> selectedAppointments = details.appointments!.cast<Appointment>();
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // 모서리 둥글게
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 제목
                        Text(
                          '일정 목록',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFDBEBE), // 메인 색상
                          ),
                        ),
                        SizedBox(height: 16),

                        // 일정 목록
                        Container(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: selectedAppointments.length,
                            itemBuilder: (context, index) {
                              Appointment appointment = selectedAppointments[index];
                              bool isAuthor =
                                  appointment.notes != null && appointment.color == Colors.blue;

                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // 카드 둥글게
                                ),
                                elevation: 2, // 그림자 효과
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        isAuthor ? Color(0xFFFDBEBE) : Colors.green,
                                    child: Icon(
                                      isAuthor ? Icons.person : Icons.group,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    appointment.subject,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${appointment.startTime.year}-${appointment.startTime.month.toString().padLeft(2, '0')}-${appointment.startTime.day.toString().padLeft(2, '0')} ${appointment.startTime.hour.toString().padLeft(2, '0')}:${appointment.startTime.minute.toString().padLeft(2, '0')} ~ ${appointment.endTime.year}-${appointment.endTime.month.toString().padLeft(2, '0')}-${appointment.endTime.day.toString().padLeft(2, '0')} ${appointment.endTime.hour.toString().padLeft(2, '0')}:${appointment.endTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  trailing: isAuthor
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit, color: Colors.blue),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                _editEvent(appointment);
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red),
                                              onPressed: () {
                                                // 삭제 확인 팝업 표시
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: Text('삭제 확인'),
                                                      content: Text('이 일정을 삭제하시겠습니까?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(context).pop(),
                                                          child: Text(
                                                            '취소',
                                                            style: TextStyle(
                                                                color: Colors.grey),
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                            Navigator.of(context).pop();
                                                            _deleteEvent(appointment);
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            foregroundColor: Colors.white,
                                                            backgroundColor:
                                                                Color(0xFFFDBEBE),
                                                          ),
                                                          child: Text('삭제'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        )
                                      : Icon(
                                          Icons.circle,
                                          color: Colors.pink,
                                          size: 10,
                                        ),
                                ),
                              );
                            },
                          ),
                        ),

                        // 닫기 및 일정 추가 버튼
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                '닫기',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showAddEventDialog(details.date!);
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Color(0xFFFDBEBE), // 메인 색상
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('일정 추가'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );


          } else if (details.targetElement == CalendarElement.calendarCell) {
            // Allow adding new appointments by tapping on empty calendar cells
            _showAddEventDialog(details.date!);
          }
        },
      ),
    );
  }

  void _showAddEventDialog(DateTime date) {
    DateTime startTime = date;
    DateTime endTime = date.add(Duration(hours: 1));
    String title = '';
    String description = '';
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // 둥근 모서리
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 제목
                    Text(
                      '새 일정 추가',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFDBEBE), // 메인 색상
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // 일정 제목 입력 필드
                    TextField(
                      decoration: InputDecoration(
                        labelText: '일정 제목',
                        labelStyle: TextStyle(color: Color(0xFFFDBEBE)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white, // 배경을 흰색으로 설정
                      ),
                      onChanged: (value) => title = value,
                    ),
                    SizedBox(height: 16),
                    
                    // 일정 내용 입력 필드
                    TextField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: '일정 내용',
                        labelStyle: TextStyle(color: Color(0xFFFDBEBE)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white, // 배경을 흰색으로 설정
                      ),
                      onChanged: (value) => description = value,
                    ),
                    SizedBox(height: 16),

                    // 시간 선택 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 시작 시간
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '시작 시간',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: startTime,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (pickedDate != null) {
                                    TimeOfDay? pickedTime = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(startTime),
                                    );
                                    if (pickedTime != null) {
                                      setState(() {
                                        startTime = DateTime(
                                          pickedDate.year,
                                          pickedDate.month,
                                          pickedDate.day,
                                          pickedTime.hour,
                                          pickedTime.minute,
                                        );
                                      });
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black, backgroundColor: Colors.white, // 버튼 텍스트 색상
                                  side: BorderSide(color: Color(0xFFFDBEBE)), // 테두리 색상
                                ),
                                child: Text(
                                  '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        // 종료 시간
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '종료 시간',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: endTime,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (pickedDate != null) {
                                    TimeOfDay? pickedTime = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(endTime),
                                    );
                                    if (pickedTime != null) {
                                      setState(() {
                                        endTime = DateTime(
                                          pickedDate.year,
                                          pickedDate.month,
                                          pickedDate.day,
                                          pickedTime.hour,
                                          pickedTime.minute,
                                        );
                                      });
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black, backgroundColor: Colors.white, // 버튼 텍스트 색상
                                  side: BorderSide(color: Color(0xFFFDBEBE)), // 테두리 색상
                                ),
                                child: Text(
                                  '${endTime.year}-${endTime.month.toString().padLeft(2, '0')}-${endTime.day.toString().padLeft(2, '0')} ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // 액션 버튼 (추가, 취소)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            '취소',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (title.isEmpty) {
                              _showErrorDialog('일정 제목을 입력해주세요.');
                              return;
                            }
                            Navigator.of(context).pop();
                            final details = AppointmentDetails(
                              title,
                              startTime,
                              endTime,
                              description,
                            );
                            _addEvent(details);
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: Color(0xFFFDBEBE), // 텍스트 색상
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // 버튼 둥글게
                            ),
                          ),
                          child: Text('추가'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class AppointmentDetails {
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String description;

  AppointmentDetails(this.title, this.startTime, this.endTime, this.description);

  String get subject => title;
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> appointments) {
    this.appointments = appointments;
  }
}
