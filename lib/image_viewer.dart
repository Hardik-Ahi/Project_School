// ignore_for_file: avoid_print

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

//main class
class ImageList extends StatefulWidget {
  const ImageList({super.key});

  @override
  State<ImageList> createState() => _ImageListState();
}

class _ImageListState extends State<ImageList> {
  int imageCount = 0;
  @override
  void initState() {
    //use this to execute a function as soon as this widget is built; like void Start() in Unity
    getImages();
    super.initState();
  }

  List<String> imageList = <String>[];

  void getImages() async {
    /**create reference instance for firestore
     * list() or listAll()
     * loop through them, store their names into array
     */

    final ListResult allImages =
        await FirebaseStorage.instance.ref().child("images/").listAll();

    for (Reference element in allImages.items) {
      imageList.add(element.name);
    }

    setState(() {
      imageList = imageList;
      imageCount = imageList.length;
    });
  }

  void viewFullImage() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.amber.shade100,
        appBar: AppBar(title: Text("Images: $imageCount")),
        body: ListView.builder(
            itemCount: imageList.length,
            itemBuilder: (context, index) {
              return ImageCard(imageName: imageList[index]);
            }));
  }
}

//the card that is an element of the list view
class ImageCard extends StatelessWidget {
  final String imageName;
  const ImageCard({required this.imageName, super.key});

  void viewOneImage(String name, BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return OneImageView(imageName: imageName);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
        child: SizedBox(
            height: 75,
            child: ElevatedButton.icon(
              onPressed: () => viewOneImage(imageName, context),
              icon: const Icon(
                Icons.image,
                color: Colors.black,
              ),
              label: Text(
                imageName,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade300,
                  shadowColor: Colors.black,
                  elevation: 0.1),
            )));
  }
}

//when clicking on any card in the list
class OneImageView extends StatefulWidget {
  final String imageName;
  const OneImageView({required this.imageName, super.key});

  @override
  State<OneImageView> createState() => _OneImageViewState();
}

class _OneImageViewState extends State<OneImageView> {
  late Future<String> imageURL;

  Future<String> getTheImage() async {
    final imageName = widget.imageName;
    final refer = FirebaseStorage.instance.ref().child("images/$imageName");
    return await refer.getDownloadURL();
  }

  @override
  void initState() {
    super.initState();
    imageURL = getTheImage();
  }

  void downloadImage() {
    Navigator.of(context).pop();

    final theImg = widget.imageName;
    Reference imageRef = FirebaseStorage.instance.ref().child("images/$theImg");
    //final Directory dir = Directory("/storage/emulated/0/Download");
    final filePath = "/storage/emulated/0/Download/$theImg.jpg";
    final downloadTask = imageRef.writeToFile(File(filePath));

    downloadTask.snapshotEvents.listen((event) {
      switch (event.state) {
        case TaskState.success:
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Downloaded")));
          break;
        case TaskState.running:
          break;
        case TaskState.canceled:
          break;
        case TaskState.paused:
          break;
        case TaskState.error:
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error: could not download file")));
          break;
      }
    });
  }

  Future openDownloadBox() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text("Download image"),
            content: ElevatedButton.icon(
              onPressed: () => downloadImage(),
              icon: const Icon(FontAwesomeIcons.download),
              label:
                  const Text("Download", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600),
            ),
          ));

  final double minScale = 1;
  final double maxScale = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.lightBlue.shade100,
        appBar: AppBar(
          title: Text(widget.imageName),
          backgroundColor: Colors.lightBlue.shade300,
        ),
        body: FutureBuilder(
          future: imageURL,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print("error fetching the image");
              return const Material(child: Text("error"));
            } else if (snapshot.hasData) {
              String theURL = snapshot.data!;
              return Center(
                child: SafeArea(
                    child: Container(
                        padding: const EdgeInsets.all(5),
                        child: GestureDetector(
                            onLongPress: () => openDownloadBox(),
                            child: InteractiveViewer(
                                panEnabled: true,
                                minScale: minScale,
                                maxScale: maxScale,
                                child: Image(
                                    image: NetworkImage(theURL),
                                    fit: BoxFit.scaleDown))))),
              );
            } else {
              return const Center(
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        ));
  }
}
