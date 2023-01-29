// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:virtual_training/image_viewer.dart';
import 'package:virtual_training/auth.dart';
import 'package:virtual_training/calendar_view.dart';
import 'package:virtual_training/teacher_UI/drawing_page.dart';

class HomePage extends StatefulWidget {
  final ClassroomUser classroomUser;
  const HomePage({required this.classroomUser, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void logout(BuildContext context) {
    final provider = Provider.of<AuthService>(context, listen: false);
    provider.signOutWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideBar(
        classroomUser: widget.classroomUser,
      ),
      appBar: AppBar(
        title: const Text(
          "Home",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        backgroundColor: Colors.lightBlue,
      ),
      backgroundColor: Colors.pink.shade100,
      body: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Center(
          child: ElevatedButton.icon(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
            label: const Text(
              "Logout",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
          ),
        ),
      ]),
    );
  }
}

//sidebar for navigation on home screen
class SideBar extends StatefulWidget {
  final ClassroomUser classroomUser;
  const SideBar({required this.classroomUser, super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  List<Widget> sideBarActions = <Widget>[];

  @override
  void initState() {
    sideBarActions.add(const SizedBox(
      height: 100,
    ));
    sideBarActions.add(Center(
        child: Column(children: [
      Text(
        widget.classroomUser.name,
        style: const TextStyle(
            fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      Text(
        widget.classroomUser.position,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.white,
        ),
      )
    ])));
    sideBarActions.add(dividerSpace);
    sideBarActions.add(buildListTile(
        text: "View Images",
        icon: Icons.image,
        onClicked: () => selectedItem(context, 0)));
    sideBarActions.add(dividerSpace);
    sideBarActions.add(buildListTile(
        text: "Class Schedule",
        icon: FontAwesomeIcons.calendar,
        onClicked: () => selectedItem(context, 1)));
    sideBarActions.add(dividerSpace);
    if (widget.classroomUser.position == "Expert") {
      sideBarActions.add(buildListTile(
          text: "Drawing Page",
          icon: Icons.draw,
          onClicked: () => selectedItem(context, 2)));
    }
    sideBarActions.add(dividerSpace);
    sideBarActions.add(Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          child: ElevatedButton.icon(
            onPressed: () => deleteAccount(context),
            icon: const FaIcon(FontAwesomeIcons.trash),
            label: const Text("Delete Account"),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
          ))
    ])));
    super.initState();
  }

  void selectedItem(BuildContext context, int index) {
    Navigator.of(context).pop();
    switch (index) {
      case 0:
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const ImageList()));
        break;
      case 1:
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => TheCalendar(
                  classroomUser: widget.classroomUser,
                )));
        break;
      case 2:
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const DrawingPage()));
        break;
    }
  }

  final padding = const EdgeInsets.symmetric(horizontal: 20);

  final dividerSpace = const SizedBox(
    height: 20,
  );

  Widget buildListTile(
      {required String text,
      required IconData icon,
      required VoidCallback? onClicked}) {
    const fontColor = Colors.white;
    const hoverColor = Colors.white60;

    return ListTile(
      leading: Icon(
        icon,
        color: fontColor,
      ),
      title: Text(
        text,
        style: const TextStyle(color: fontColor),
      ),
      onTap: onClicked,
      hoverColor: hoverColor,
    );
  }

  Future<bool> deleteAccountConfirmation(BuildContext context) async {
    bool delete = false;

    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Delete Account?"),
              content: const Text(
                  "All data associated with this account will be deleted.\nDo you want to continue?"),
              actions: [
                TextButton(
                    onPressed: () {
                      delete = false;
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () {
                      delete = true;
                      Navigator.of(context).pop();
                    },
                    child: const Text("OK"))
              ],
            ));

    return delete;
  }

  void deleteAccount(BuildContext context) async {
    bool delete = await deleteAccountConfirmation(context);

    if (!delete) {
      return;
    }
    if (widget.classroomUser.position == "Expert") {
      CollectionReference colRef = FirebaseFirestore.instance
          .collection("users")
          .doc(widget.classroomUser.userID)
          .collection("classes_schedule");
      QuerySnapshot qs = await colRef.get();
      for (var element in qs.docs) {
        element.reference.delete();
      }
    }
    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.classroomUser.userID)
        .delete();
    AuthService().signOutWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Material(
          color: Colors.blue.shade500,
          child: Padding(
              padding: padding, child: Column(children: sideBarActions))),
    );
  }
}
