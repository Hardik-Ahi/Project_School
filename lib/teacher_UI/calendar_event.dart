// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:virtual_training/auth.dart';

class CalendarEventPage extends StatefulWidget {
  final DateTime selectedDate;
  final ClassroomUser classroomUser;
  const CalendarEventPage(
      {required this.selectedDate, required this.classroomUser, super.key});

  @override
  State<CalendarEventPage> createState() => _CalendarEventPageState();
}

class _CalendarEventPageState extends State<CalendarEventPage> {
  DateTime eventDate = DateTime.now();
  String eventTitle = "calendarEvent";
  TimeOfDay timeOfDay = const TimeOfDay(hour: 0, minute: 0);
  int hours = 1;
  int minutes = 0;
  String teacherID = "";
  //DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

  @override
  void initState() {
    super.initState();
    eventDate = widget.selectedDate;
    timeOfDay = TimeOfDay.fromDateTime(eventDate);
    teacherID = widget.classroomUser.userID;
  }

  TextEditingController eventTitleController = TextEditingController();

  String formatTime(DateTime dateTime) {
    return DateFormat.Hms().format(dateTime);
  }

  void timePickerPopUp() async {
    TimeOfDay? newTimeOfDay =
        await showTimePicker(context: context, initialTime: timeOfDay);

    if (newTimeOfDay == null) {
      return;
    }
    setState(() {
      timeOfDay = newTimeOfDay;
      eventDate = DateTime(eventDate.year, eventDate.month, eventDate.day,
          timeOfDay.hour, timeOfDay.minute);
    });
  }

  Widget datePicker() => Container(
      padding: const EdgeInsets.all(10),
      child: Text("${eventDate.day}/ ${eventDate.month}/ ${eventDate.year}"));

  Widget timePicker() => Container(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: timePickerPopUp,
        child: Text(timeOfDay.format(context)),
      ));

  Widget eventTitleField() => Container(
      padding: const EdgeInsets.all(10),
      child: TextField(
        decoration: InputDecoration(hintText: "Event title: $eventTitle"),
        controller: eventTitleController,
      ));

  Widget submitButton() => Container(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: submitEventToFirebase,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        child: const Text("Submit"),
      ));

  Widget hoursSelect() => Container(
        padding: const EdgeInsets.all(10),
        child: Text("${hours.toStringAsFixed(1)} hours"),
      );

  Widget minutesSelect() => Container(
        padding: const EdgeInsets.all(10),
        child: Text("${minutes.toStringAsFixed(0)} minutes"),
      );

  void submitEventToFirebase() async {
    final DocumentReference<Map<String, dynamic>> newEvent;

    newEvent = FirebaseFirestore.instance
        .collection("users")
        .doc(teacherID)
        .collection("classes_schedule")
        .doc();

    if (eventTitleController.text != "") {
      setState(() {
        eventTitle = eventTitleController.text;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields.")));
      return;
    }

    final json = {
      "title": eventTitle,
      "date": eventDate.toString(),
      "hours": hours.toString(),
      "minutes": minutes.toString(),
      "colourIndex": widget.classroomUser.colourIndex.toString(),
      "userID": teacherID
    };

    await newEvent.set(json);

    if (!mounted) {
      return null;
    }

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Created event. Refresh to view.")));
    Navigator.pop(context);
  }

  final verticalPadding = const SizedBox(
    height: 50,
  );

  final horizontalPadding = const SizedBox(width: 20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Create an event"),
      ),
      body: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          verticalPadding,
          Row(
            children: [const Text("Date: "), horizontalPadding, datePicker()],
          ),
          verticalPadding,
          Row(
            children: [const Text("Time: "), horizontalPadding, timePicker()],
          ),
          verticalPadding,
          hoursSelect(),
          Slider(
            value: hours.toDouble(),
            min: 0.0,
            max: 12.0,
            onChanged: (value) => setState(() {
              hours = value.toInt();
            }),
          ),
          verticalPadding,
          minutesSelect(),
          Slider(
            value: minutes.toDouble(),
            min: 0.0,
            max: 59.0,
            onChanged: (value) => setState(() {
              minutes = value.toInt();
            }),
          ),
          eventTitleField(),
          verticalPadding,
          submitButton(),
        ],
      )),
    );
  }
}
