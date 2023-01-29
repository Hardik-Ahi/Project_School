//google authentication code

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:google_sign_in/google_sign_in.dart'; //plugin

class ClassroomUser {
  final String userID;
  final String name;
  final String position; //teacher or student
  final int colourIndex;

  ClassroomUser(
      {this.colourIndex = 0,
      required this.name,
      required this.position,
      required this.userID}); //constructor

  static ClassroomUser fromJson(Map<String, dynamic> json) => ClassroomUser(
      name: json['name'],
      position: json['position'],
      userID: json['userID']); //creating user object from json data
}

class AuthService extends ChangeNotifier {
  static GoogleSignInAuthentication? authentication;
  //1. verify user with google (aka very basic sign-in with google)
  Future<String?> authWithGoogle() async {
    /*ultimately we need to sign in to an instance of FirebaseAuth with a credential.

    that credential is given to us by GoogleAuthProvider class. But in order to give that credential to us, it needs an id token
    and access token as inputs.
    
    to get those tokens, we need to authenticate those users against Google (not firebase).

    for this we need to sign the user in to google.
    */

    final GoogleSignIn googleSignIn =
        GoogleSignIn(); // instance of the googlesignin class; contains various methods

    try {
      final GoogleSignInAccount?
          account = //get the account of the user using the pop-up page
          await googleSignIn.signIn(); //'?' because this can be null

      final GoogleSignInAuthentication? authentication = await account
          ?.authentication; //this holds our token after successful sign-in; 'account?' because it can be null

      final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: authentication?.idToken,
          accessToken: authentication
              ?.accessToken); //getting the credential from googleauthprovider using the tokens we got from authentication

      await FirebaseAuth.instance.signInWithCredential(
          credential); //final step: signing in to firebase with the credential

      //authentication.idToken has the token we need.

      notifyListeners();
      return authentication?.idToken;
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  //2. sign out
  signOutWithGoogle() async {
    //signing out from firebase by first disconnecting account from app using google
    await GoogleSignIn().disconnect();
    FirebaseAuth.instance.signOut();
    notifyListeners();
  }
}
