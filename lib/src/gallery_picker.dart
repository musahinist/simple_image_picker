import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryPicker extends StatefulWidget {
  final ValueSetter<XFile> onSelect;
  GalleryPicker({Key? key, required this.onSelect}) : super(key: key);

  @override
  _GalleryPickerState createState() => _GalleryPickerState();
}

class _GalleryPickerState extends State<GalleryPicker> {
  List<Widget> _mediaList = [];
  int currentPage = 0;
  int? lastPage;
  @override
  void initState() {
    super.initState();
    _fetchNewMedia();
  }

  _handleScrollEvent(ScrollNotification scroll) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33) {
      if (currentPage != lastPage) {
        _fetchNewMedia();
      }
    }
  }

  _fetchNewMedia() async {
    lastPage = currentPage;
    var result = await PhotoManager.requestPermission();
    if (result) {
      // success
//load the album list
      List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(onlyAll: true);
      print(albums.first.name);
      List<AssetEntity> media =
          await albums[0].getAssetListPaged(currentPage, 60);
      print(media);
      List<Widget> temp = [];
      for (var asset in media) {
        temp.add(
          FutureBuilder<Uint8List?>(
            future: asset.thumbDataWithSize(200, 200),
            builder: (BuildContext context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done)
                return Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: InkWell(
                        onTap: () async {
                          File? file = await asset.file;

                          widget.onSelect(XFile(file!.path));
                        },
                        child: Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (asset.type == AssetType.video)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 5, bottom: 5),
                          child: Icon(
                            Icons.videocam,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                );
              return Container();
            },
          ),
        );
      }
      setState(() {
        _mediaList.addAll(temp);
        currentPage++;
      });
    } else {
      // fail
      /// if result is fail, you can call `PhotoManager.openSetting();`  to open android/ios applicaton's setting to get permission
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scroll) {
        _handleScrollEvent(scroll);
        return false;
      },
      child: Container(
        decoration: BoxDecoration(),
        child: GridView.builder(
            itemCount: _mediaList.length,
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemBuilder: (BuildContext context, int index) {
              return _mediaList[index];
            }),
      ),
    );
  }
}
