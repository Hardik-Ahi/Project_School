// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'package:virtual_training/home_page.dart';

//checks for user state: logged in or not, and then displays appropriate screen
class Loader extends StatelessWidget {
  const Loader({super.key});

  Future<DocumentSnapshot<Map<String, dynamic>>> properAuth(String? uid) async {
    return await FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasData) {
          var userID = snapshot.requireData?.uid;

          return FutureBuilder(
            future: properAuth(userID),
            builder: (context, snap) {
              if (snap.hasData) {
                if (!snap.requireData.exists) {
                  //document data doesn't exist
                  return const SignUpPage();
                } else {
                  print(snap.requireData['position']);
                  var positionName = snap.requireData['position'];

                  return HomePage(
                      classroomUser: ClassroomUser(
                          name: snap.requireData['name'],
                          position: positionName[0].toUpperCase() +
                              positionName.substring(1),
                          userID: snap.requireData['userID'],
                          colourIndex: snap.requireData
                                  .data()!
                                  .containsKey("colourIndex")
                              ? int.parse(snap.requireData['colourIndex'])
                              : 0));
                }
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        } else if (snapshot.hasError) {
          print("error in authentication");
        }
        return const LoginPage();
      },
    );
  }
}

//ask user to login / sign up
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  void login() {
    final provider = Provider.of<AuthService>(context, listen: false);
    provider.authWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber.shade100,
      appBar: AppBar(
        title: const Text(
          "Login",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade100,
      ),
      body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            Container(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: ElevatedButton.icon(
                  onPressed: () => AuthService().authWithGoogle(),
                  icon: const FaIcon(FontAwesomeIcons.google),
                  label: const Text("Login with Google",
                      style: TextStyle(fontWeight: FontWeight.bold))),
            )
          ])),
    );
  }
}

//when user wants to sign up (create account)
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  List<String> typesOfUsers = ['expert', 'student'];
  String? selectedUser = 'student';
  User? firebaseUser = FirebaseAuth.instance.currentUser;
  int colourIndex = 0;

  submitSignUp(BuildContext context) async {
    firebaseUser = FirebaseAuth.instance.currentUser;
    final DocumentReference<Map<String, dynamic>> newUser;

    print("length is:");
    print(Colors.primaries.length);
    colourIndex = Random().nextInt(Colors.primaries.length);
    newUser =
        FirebaseFirestore.instance.collection('users').doc(firebaseUser?.uid);

    var json;

    if (selectedUser == 'student') {
      json = {
        'name': firebaseUser?.displayName,
        'position': selectedUser,
        'userID': firebaseUser?.uid,
      };
    } else {
      json = {
        'name': firebaseUser?.displayName,
        'position': selectedUser,
        'userID': firebaseUser?.uid,
        'colourIndex': colourIndex.toString()
      };
    }

    await newUser.set(json);

    if (!mounted) {
      return null;
    }
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return const Loader();
    }));
  }

  final divider = const SizedBox(
    height: 50,
  );

  Color scaffoldColor = Colors.green.shade100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sign Up",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        backgroundColor: Colors.green.shade200,
      ),
      backgroundColor: scaffoldColor,
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            padding: const EdgeInsets.fromLTRB(30, 50, 30, 50),
            child: Text(
              firebaseUser?.displayName ?? "New user",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                  fontSize: 20),
            )),
        Center(
            child: DropdownButton<String>(
          onChanged: (oneUser) => setState(() {
            selectedUser = oneUser;
          }),
          items: typesOfUsers
              .map((oneItem) => DropdownMenuItem<String>(
                  value: oneItem,
                  child: Text(oneItem, style: const TextStyle(fontSize: 20))))
              .toList(),
          value: selectedUser,
        )),
        Center(
            child: ElevatedButton.icon(
                onPressed: () => submitSignUp(context),
                icon: const Icon(Icons.done),
                label: const Text("Submit"))),
        divider,
        Center(
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: scaffoldColor,
                  elevation: 0,
                  shadowColor: Colors.transparent),
              onPressed: () => AuthService().signOutWithGoogle(),
              child: const Text(
                "Switch accounts",
                style: TextStyle(
                    decoration: TextDecoration.underline, fontSize: 20),
              )),
        )
      ]),
    );
  }
}
