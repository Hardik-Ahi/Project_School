// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:virtual_training/auth.dart';
import 'package:virtual_training/teacher_UI/calendar_event.dart';

class TheCalendar extends StatefulWidget {
  final ClassroomUser classroomUser;
  const TheCalendar({required this.classroomUser, super.key});

  @override
  State<TheCalendar> createState() => _TheCalendarState();
}

class _TheCalendarState extends State<TheCalendar> {
  CalendarController cc = CalendarController();
  DateTime selectedDate = DateTime.now();
  List<Meeting> appointments = <Meeting>[];
  String teacherID = "";
  bool studentView = false;
  //DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

  @override
  void initState() {
    super.initState();
    teacherID = widget.classroomUser.userID;
    actions.add(addEventButton());
    actions.add(todayView());
    actions.add(popUpMenuButton());

    if (widget.classroomUser.position == "Student") {
      studentView = true;
      actions.removeAt(0); //no add event button for student
    }
    fetchAppointments();
  }

  void selectedAction(BuildContext context, int value) {
    switch (value) {
      case 0:
        cc.view = CalendarView.day;
        break;
      case 1:
        cc.view = CalendarView.week;
        break;
      case 2:
        cc.view = CalendarView.month;
        break;
    }
  }

  void fetchAppointments() async {
    DateTime startTime;
    DateTime endTime;
    int hours;
    int minutes;
    //int colourIndex;

    setState(() {
      appointments.clear();
    });

    CollectionReference classes;

    CollectionReference users = FirebaseFirestore.instance.collection("users");

    users.get().then((value) {
      for (var i in value.docs) {
        if (i['position'] != 'expert') {
          continue;
        }
        classes = users.doc(i.id).collection("classes_schedule");
        classes.get().then((querySnapshot) {
          for (var i in querySnapshot.docs) {
            startTime = DateTime.parse(i['date']);
            hours = int.parse(i['hours']);
            minutes = int.parse(i['minutes']);
            endTime = startTime.add(Duration(hours: hours, minutes: minutes));
            setState(() {
              appointments.add(Meeting(
                  startTime: startTime,
                  endTime: endTime,
                  subject: i['title'],
                  color: Colors.primaries[int.parse(i['colourIndex'])],
                  userID: i['userID']));
            });
          }
        });
      }
    });
  }

  void deleteAppointment(CalendarLongPressDetails clpd) async {
    Meeting apt;
    var t = clpd.appointments!.first;
    apt = t;
    if (clpd.appointments == null) {
      return;
    } else if (apt.userID != teacherID) {
      return;
    }

    CollectionReference classes = FirebaseFirestore.instance
        .collection("users")
        .doc(teacherID)
        .collection("classes_schedule");

    bool delete = false;
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Delete this event?"),
              content: Row(children: [
                TextButton(
                    onPressed: () {
                      delete = false;
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel")),
                const SizedBox(
                  width: 5,
                ),
                TextButton(
                    onPressed: () {
                      delete = true;
                      Navigator.of(context).pop();
                    },
                    child: const Text("OK"))
              ]),
            ));

    if (!delete) {
      print("delete is false");
      return;
    }

    print(apt.subject);

    QuerySnapshot docList = await classes.get();
    DocumentReference docRef;
    DocumentSnapshot docSnap;

    for (var i in docList.docs) {
      print(i.id);
      docRef = classes.doc(i.id);
      docSnap = await docRef.get();

      print(docSnap['date']);
      print(t.startTime.toString());
      print("");
      if (docSnap['date'] == t.startTime.toString()) {
        docRef.delete();
        print("done");
        break;
      }
    }

    setState(() {
      appointments.remove(t);
    });
  }

  List<Widget> actions = <Widget>[];

  Widget addEventButton() => ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => CalendarEventPage(
                    classroomUser: widget.classroomUser,
                    selectedDate: selectedDate,
                  )));
        },
        style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.orange.shade400,
            shadowColor: Colors.transparent),
        child: const Text(
          "Add Event",
          style: TextStyle(fontSize: 15),
        ),
      );

  Widget todayView() => ElevatedButton(
        onPressed: () {
          var nowDate = DateTime.now();
          cc.displayDate = DateTime(nowDate.year, nowDate.month, nowDate.day);
        },
        style: ElevatedButton.styleFrom(elevation: 0),
        child: const Text("Today"),
      );

  Widget popUpMenuButton() => PopupMenuButton(
      onSelected: (value) => selectedAction(context, value),
      itemBuilder: (context) => [
            const PopupMenuItem<int>(value: 0, child: Text("Day view")),
            const PopupMenuItem<int>(value: 1, child: Text("Week view")),
            const PopupMenuItem<int>(value: 2, child: Text("Month view"))
          ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
        actions: actions,
      ),
      body: SfCalendar(
        controller: cc,
        view: CalendarView.day,
        onSelectionChanged: (CalendarSelectionDetails csd) {
          if (cc.selectedDate != null) {
            selectedDate = cc.selectedDate!;
          }
        },
        dataSource: DataSource(appointments),
        onLongPress: deleteAppointment,
      ),
    );
  }
}

class Meeting {
  DateTime startTime;
  DateTime endTime;
  String subject;
  Color color;
  String userID;
  Meeting(
      {required this.startTime,
      required this.endTime,
      required this.subject,
      required this.color,
      required this.userID});
}

class DataSource extends CalendarDataSource {
  DataSource(List<Meeting> source) {
    appointments = source;
    //notifyListeners(type, data)
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].endTime;
  }

  @override
  String getSubject(int index) {
    return appointments![index].subject;
  }

  @override
  Color getColor(int index) {
    return appointments![index].color;
  }
}
