import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'src/camera_picker.dart';

export 'image_picker.dart';

class ImagePicker extends StatefulWidget {
  const ImagePicker(
      {Key? key, required this.onSelect, this.child, required this.color})
      : super(key: key);
  final ValueSetter<XFile?> onSelect;
  final Widget? child;
  final Color color;

  @override
  State<ImagePicker> createState() => _ImagePickerState();
}

class _ImagePickerState extends State<ImagePicker> {
  XFile? file;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        List<CameraDescription> cameraList = await availableCameras();
        if (!mounted) return;
        Navigator.of(context)
            .push(
          MaterialPageRoute<XFile>(
            builder: (context) =>
                TakePictureScreen(cameraList: cameraList, color: widget.color),
          ),
        )
            .then((file) {
          widget.onSelect(file);

          this.file = file;
          setState(() {});
        });
      },
      child: SizedBox(
        height: 50,
        child: widget.child ??
            CircleAvatar(
              backgroundImage:
                  file != null ? FileImage(File(file!.path)) : null,
            ),
      ),
    )
        // FutureBuilder<List<CameraDescription>>(
        //     future: availableCameras(),
        //     builder: (context, snapshot) {
        //       if (snapshot.connectionState == ConnectionState.done) {
        //         return TakePictureScreen(
        //             cameraList: snapshot.data!, onSelect: onSelect);
        //       } else {
        //         return Center(
        //           child: const CircularProgressIndicator.adaptive(),
        //         );
        //       }
        //     }),
        ;
  }
}
