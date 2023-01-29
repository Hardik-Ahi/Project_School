import 'drawing_handler.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:screenshot/screenshot.dart';

//drawing page
class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends HandleDrawingActions {
  //extends 'Handler...' in order to separate all methods from all widget renderings

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.lightBlue.shade200,
        appBar: AppBar(
          title: const Text(
            "Drawing Page",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton(
                onSelected: (value) => selectedAction(context, value),
                itemBuilder: (context) => [
                      const PopupMenuItem<int>(
                          value: 0, child: Text("Add Text")),
                      const PopupMenuItem<int>(value: 1, child: Text("Save")),
                    ])
          ],
        ),
        body: Column(
          children: [
            SafeArea(
                child: SizedBox(
                    width: MediaQuery.of(context)
                        .size
                        .width, //getting width of device
                    height: 0.75 *
                        (MediaQuery.of(context)
                            .size
                            .height), //getting height of device
                    child: image!.existsSync()
                        ? Screenshot(
                            controller: ssController,
                            child: Stack(
                              alignment: Alignment.center,
                              children: allTexts,
                            ))
                        : const Text("image not selected"))),
            Expanded(
                child: Center(
              child: ElevatedButton.icon(
                  onPressed: () => updateImg(),
                  icon: const FaIcon(FontAwesomeIcons.file),
                  label: const Text(
                    "Choose a file",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
            ))
          ],
        ));
  }
}
