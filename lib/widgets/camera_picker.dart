import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'gallery_picker.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen(
      {Key? key, required this.cameraList, required this.color})
      : super(key: key);
  final Color color;
  final List<CameraDescription> cameraList;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen>
    with TickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late TabController _tabController;
  List<double> exposureList = [];
  XFile? image;
  final flashIcon = FlasModeNotifier();
  bool isCamera = true;

  double exposure = 0;
  int segmentedControlValue = 0;
  double _currentSliderValue = 20;
  double maxZoom = 1;
  double minZoom = 1;
  double curZoom = 1;
  double initialZoom = 1;
  bool isZooming = false;
  @override
  void initState() {
    super.initState();
    //  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle
    //     .dark); // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.cameraList.first,
      // Define the resolution to use.
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Next, initialize the controller. This returns a Future.

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      isCamera = _tabController.index == 0 ? true : false;
      segmentedControlValue = _tabController.index;
      setState(() {});
    });
  }

  void _onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_controller == null) {
      return;
    }

    //  final CameraController cameraController = _controller;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    _controller.setExposurePoint(offset);
    _controller.setFocusPoint(offset);
  }

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    ;
    await _initializeControllerFuture;
    minZoom = await _controller.getMinZoomLevel();
    maxZoom = await _controller.getMaxZoomLevel();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      //  extendBody: true,
      //  extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black38,
        elevation: 0,
        actions: isCamera
            ? [
                AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: isZooming ? 1 : 0,
                  child: CircleAvatar(
                      backgroundColor: Colors.black38,
                      child: Text(curZoom.toStringAsFixed(1))),
                ),
                IconButton(
                  icon: Icon(Icons.exposure),
                  onPressed: () async {
                    exposureList = [
                      await _controller.getMinExposureOffset(),
                      await _controller.getMaxExposureOffset(),
                      await _controller.getExposureOffsetStepSize()
                    ];
                    showMenu(
                      shape: const StadiumBorder(),
                      position: RelativeRect.fromSize(
                          const Rect.fromLTWH(0, 30, 20, 30), Size.zero),
                      context: context,
                      items: <PopupMenuEntry<double>>[
                        PopupMenuItem<double>(
                          enabled: false,
                          child: StatefulBuilder(
                            builder: (context, state) => Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Center(
                                    child: Text(
                                      exposure.round().toString(),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 150,
                                  child: CupertinoSlider(
                                    activeColor: Colors.amber,
                                    min: exposureList[0],
                                    max: exposureList[1],
                                    divisions: exposureList[2].round() != 0
                                        ? exposureList[2].round()
                                        : null,
                                    value: exposure,
                                    onChanged: (val) {
                                      state(() {
                                        exposure = val;
                                        _controller.setExposureOffset(val);

                                        // _controller.setExposureMode(
                                        //     ExposureMode.auto);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                ValueListenableBuilder<IconData>(
                    valueListenable: flashIcon,
                    builder: (context, icon, _) {
                      return IconButton(
                        icon: Icon(icon),
                        onPressed: () {
                          showMenu(
                            shape: const StadiumBorder(),
                            position: RelativeRect.fromSize(
                                const Rect.fromLTWH(0, 30, 20, 30), Size.zero),
                            context: context,
                            items: <PopupMenuEntry<double>>[
                              PopupMenuItem<double>(
                                enabled: false,
                                onTap: () {},
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        _controller.setFlashMode(FlashMode.off);
                                        flashIcon
                                            .changeFlasMode(Icons.flash_off);

                                        Navigator.of(context).pop();
                                      },
                                      icon: const Icon(
                                        Icons.flash_off,
                                        color: Colors.black,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _controller
                                            .setFlashMode(FlashMode.auto);
                                        flashIcon
                                            .changeFlasMode(Icons.flash_auto);

                                        Navigator.of(context).pop();
                                      },
                                      icon: Icon(
                                        Icons.flash_auto,
                                        color: Colors.black,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _controller
                                            .setFlashMode(FlashMode.always);
                                        flashIcon
                                            .changeFlasMode(Icons.flash_on);
                                        //    flashIcon = Icons.flash_on;
                                        Navigator.of(context).pop();
                                        setState(() {});
                                      },
                                      icon: Icon(
                                        Icons.flash_on,
                                        color: Colors.black,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _controller
                                            .setFlashMode(FlashMode.torch);
                                        flashIcon.changeFlasMode(
                                            Icons.flashlight_on);

                                        Navigator.of(context).pop();
                                        setState(() {});
                                      },
                                      icon: Icon(
                                        Icons.flashlight_on,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }),
                // IconButton(
                //   onPressed: () {
                //     _controller.setZoomLevel(2);
                //     setState(() {});
                //   },
                //   icon: Icon(Icons.zoom_out),
                // ),

                IconButton(
                  onPressed: () {
                    _controller = CameraController(
                      // Get a specific camera from the list of available cameras.
                      _controller.description.lensDirection ==
                              CameraLensDirection.back
                          ? widget.cameraList.last
                          : widget.cameraList.first,
                      // Define the resolution to use.
                      ResolutionPreset.max,
                    );
                    _initializeControllerFuture =
                        _controller.initialize().then((_) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {});
                    });
                  },
                  icon: Icon(Icons.switch_camera_outlined, color: Colors.white),
                ),
                //  VerticalDivider(color: Colors.white),
              ]
            : [],
        // title: const Text('Take a picture'),
      ),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                return AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: CameraPreview(
                    _controller,
                    child: LayoutBuilder(builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: (details) {
                          initialZoom = curZoom;
                        },
                        onScaleUpdate: (details) async {
                          isZooming = true;
                          final double scale = (initialZoom * details.scale)
                              .clamp(minZoom, maxZoom);
                          await _controller.setZoomLevel(scale);
                          curZoom = scale;
                          setState(() {});
                        },
                        onScaleEnd: (details) {
                          isZooming = false;

                          setState(() {});
                        },
                        onTapDown: (details) =>
                            _onViewFinderTap(details, constraints),
                      );
                    }),
                  ),
                );
              } else {
                // Otherwise, display a loading indicator.
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          // image != null ? CropSample(image: image!) : SizedBox(),
          GalleryPicker(
            onSelect: (file) {
              image = file;
              setState(() {});
            },
          )
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isCamera
          ? FloatingActionButton(
              //  elevation: 0,
              backgroundColor: Colors.white,
              // foregroundColor: Colors.transparent,
              // Provide an onPressed callback.
              onPressed: () async {
                // Take the Picture in a try / catch block. If anything goes wrong,
                // catch the error.
                try {
                  // Ensure that the camera is initialized.
                  await _initializeControllerFuture;

                  // Attempt to take a picture and get the file `image`
                  // where it was saved.
                  image = await _controller.takePicture();
                  setState(() {});

                  // If the picture was taken, display it on a new screen.
                  // await Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder: (context) => DisplayPictureScreen(
                  //       // Pass the automatically generated path to
                  //       // the DisplayPictureScreen widget.
                  //       imagePath: image!.path,
                  //     ),
                  //   ),
                  // );
                } catch (e) {
                  // If an error occurs, log the error to the console.
                  print(e);
                }
              },
              child: Icon(isCamera ? Icons.camera : Icons.photo_library,
                  color: widget.color))
          : null,
      bottomNavigationBar: BottomAppBar(
        color: Colors.black38,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (image != null)
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                            enableDrag: true,
                            isScrollControlled: true,
                            context: context,
                            builder: (context) => DisplayPictureScreen(
                                  imagePath: image!.path,
                                  onDelete: () {
                                    image = null;
                                    Navigator.of(context).pop();
                                    setState(() {});
                                  },
                                ));
                      },
                      child: CircleAvatar(
                        backgroundColor: widget.color,
                        backgroundImage:
                            image != null ? FileImage(File(image!.path)) : null,
                      ),
                    ),
                    SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop(image);
                      },
                      icon: Icon(Icons.check, color: Colors.white),
                    ),
                  ],
                ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CupertinoSlidingSegmentedControl(
                    groupValue: segmentedControlValue,
                    backgroundColor: Colors.black38,
                    thumbColor: widget.color,
                    children: const <int, Widget>{
                      0: Icon(Icons.camera, color: Colors.white),
                      1: Icon(Icons.photo_library, color: Colors.white),
                    },
                    onValueChanged: (value) {
                      setState(() {
                        segmentedControlValue = value as int;
                        _tabController.animateTo(segmentedControlValue);
                      });
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final VoidCallback onDelete;

  const DisplayPictureScreen(
      {Key? key, required this.imagePath, required this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.file(
              File(imagePath),
              // fit: BoxFit.contain,
            ),
          ),
          Container(
            height: 50,
            color: Colors.black,
            child: IconButton(
              icon: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                ],
              ),
              onPressed: onDelete,
            ),
          )
        ],
      ),
    );
  }
}

class FlasModeNotifier extends ValueNotifier<IconData> {
  FlasModeNotifier() : super(Icons.flash_auto);
  void changeFlasMode(IconData icon) {
    value = icon;
  }
}
