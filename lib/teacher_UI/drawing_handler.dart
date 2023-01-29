//multiple drawing utilities
// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uri_to_file/uri_to_file.dart';
import 'drawing_page.dart';

abstract class HandleDrawingActions extends State<DrawingPage> {
  //this class extends the state of DrawingPage, so it can modify it.

// image / screenshot work
  File? image = File("");
  String nameOfFile = "";

  void updateImg() async {
    image = await chooseImg();
    image ??= File("");
    setState(() {
      image = image;
      allTexts.clear();
      allTexts.add(Image.file(image!, fit: BoxFit.scaleDown));
    });
  }

  final ssController = ScreenshotController();

//saves the screenshot to the gallery first, then to firestore
  Future<String> saveSS(Uint8List bytes) async {
    //Uint8List is a datatype (class) for storing a sequence of bytes (here from an image)

    await Permission.storage.request();

    final time = DateTime.now().toIso8601String().replaceAll(":", "_").replaceAll(
        ".",
        "-"); //iso8601 is the worldwide standard format for time- and date- related data exchange; like ASCII
    nameOfFile = "screenshot_$time";
    final result = await ImageGallerySaver.saveImage(bytes, name: nameOfFile);

    File file;

    //print(result['filePath']);
    try {
      file = await toFile(
          result['filePath']); //converts the 'content uri' to the file
    } catch (e) {
      print(e);
      return "";
    }
    final reference =
        FirebaseStorage.instance.ref().child("images/$nameOfFile");

    UploadTask uploadTask = reference.putFile(file);

    await uploadTask.whenComplete(() {});

    return result['filePath']; //accessing filePath property of the result.
  }

  Future<File?> chooseImg() async {
    //choosing image from gallery
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image == null) {
        canDraw = false;
        return null;
      }
      canDraw = true;
      final file = File(image.path);
      return file;
    } catch (e) {
      return null;
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void ss(BuildContext context) async {
    final shot = await ssController.capture();

    if (shot == null) {
      return;
    }
    var completed = await saveSS(shot);
    if (completed == "") {
      return;
    }
    showMessage("Saved to firebase");
  }

//appending new text to the image work
  List<Widget> allTexts = [];

  final textController = TextEditingController();
  bool canDraw = false;

  Color textColour = Colors.red;

  void addTextWidget() {
    final newText = Text(
      textController.text,
      style: TextStyle(
          backgroundColor: Colors.red.withOpacity(0),
          color: textColour,
          fontWeight: FontWeight.bold,
          fontSize: 40),
    );
    setState(() {
      if (allTexts.length >= 2) {
        allTexts.removeLast();
      }
      allTexts.add(newText);
    });
    Navigator.of(context).pop();
  }

//input text box
  void textBox(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: const Text("Add Text"),
              content: TextField(
                autocorrect: false,
                decoration:
                    const InputDecoration(hintText: "Enter some text..."),
                controller: textController,
              ),
              actions: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                          width: 30,
                          child: ElevatedButton(
                            onPressed: () => {textColour = Colors.white},
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: const CircleBorder(
                                    side: BorderSide(
                                        color: Colors.black, width: 1))),
                            child: const Text(""),
                          )),
                      SizedBox(
                          width: 30,
                          child: ElevatedButton(
                            onPressed: () => {textColour = Colors.black},
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: const CircleBorder(
                                    side: BorderSide(
                                        color: Colors.yellow, width: 1))),
                            child: const Text(""),
                          )),
                      SizedBox(
                          width: 30,
                          child: ElevatedButton(
                            onPressed: () => {textColour = Colors.green},
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: const CircleBorder(
                                    side: BorderSide(
                                        color: Colors.black, width: 1))),
                            child: const Text(""),
                          )),
                      SizedBox(
                          width: 30,
                          child: ElevatedButton(
                            onPressed: () => {textColour = Colors.blue},
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: const CircleBorder(
                                    side: BorderSide(
                                        color: Colors.black, width: 1))),
                            child: const Text(""),
                          )),
                      ElevatedButton(
                          onPressed: () => addTextWidget(),
                          child: const Text(
                            "Submit",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          )),
                    ])
              ],
            ));
  }

//popup menu action controller
  void selectedAction(BuildContext context, int value) {
    if (canDraw == false) {
      return;
    }
    switch (value) {
      case 0: //allow text to be placed on top of this image
        textBox(context);
        break;
      case 1:
        //save to gallery/firebase
        ss(context);
        break;
    }
  }
}
