import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';

const List<String> resolutions = [
  '720p/30fps',
  '1080p/30fps',
  '4K/30fps',
  '720p/60fps',
  '1080p/60fps',
  '4K/60fps',
  '1080p/120fps'
];

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CameraPage()),
            );
          },
          child: Text('Go to Camera'),
        ),
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _cameraController;
  bool _isLoading = true;
  bool _isRecording = false;
  String _selectedResolution = resolutions[4]; // 預設: 1080p/60fps

  final MethodChannel _cameraConfigurationChannel = MethodChannel('samples.flutter.dev/camera_configuration');

  @override
  void initState() {
    _initCamera();
    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    ResolutionPreset getResolutionPreset(String resolution) {
      switch (resolution) {
        case '720p/30fps':
        case '720p/60fps':
          return ResolutionPreset.high;
        case '4K/30fps':
        case '4K/60fps':
          return ResolutionPreset.ultraHigh;
        default:
          return ResolutionPreset.veryHigh;
      }
    }
    ResolutionPreset resolutionPreset = getResolutionPreset(_selectedResolution);

    _cameraController = CameraController(firstCamera, resolutionPreset);
    await _cameraController.initialize();

    await _setCameraConfiguration(720); //新增此段會導致崩潰？

    if (_cameraController.value.isInitialized) {
      print("Camera resolution: ${_cameraController.value.previewSize}");
    } else {
      print("Failed to initialize camera!");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _setCameraConfiguration(int resolution) async {
    try {
      final bool success = await _cameraConfigurationChannel.invokeMethod(
        'setCameraConfiguration',
        {'format': resolution},
      );
      if (success) {
        print('Camera resolution set to: $resolution');
      } else {
        print('Failed to set camera resolution: $resolution');
      }
    } on PlatformException catch (e) {
      print('Error: ${e.message}');
    }
  }

  Future<void> _openCamera() async {
    Map<String, int> cameraConfigurations = {
      "1080p/60fps": 1080,
      "720p/60fps": 720,
      "4K/60fps": 2160,
      "1080p/120fps": 1080120,
    };

    int? configuration = cameraConfigurations[_selectedResolution];
    if (configuration != null) {
      await _setCameraConfiguration(configuration);
    }

    await _cameraController.prepareForVideoRecording();
    await _cameraController.startVideoRecording();
    setState(() => _isRecording = true);
  }

  void _stopRecordVideo() async {
    final file = await _cameraController.stopVideoRecording();
    if (file != null) {
      var videoFilePath = file.path;
      await GallerySaver.saveVideo(videoFilePath);
      print(videoFilePath);
    }
    setState(() => _isRecording = false);
  }

  void _setCameraStatus(String value) {
    if (resolutions.contains(value)) {
      _selectedResolution = value;
      if (['720p/30fps', '1080p/30fps', '4K/30fps'].contains(_selectedResolution)) {
        _initCamera();
      }
      print(_selectedResolution);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Camera Page'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(2),
              child: CameraPreview(
                _cameraController,
                child: Center(
                  child: Text(
                    "+",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.02,
              left: null,   //置中
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10), // 左右各多出10
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(width: 10),
                      Text(
                        "Camera Resolution:",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      SizedBox(width: 10),
                      Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.black.withOpacity(0.4),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedResolution,
                          icon: Icon(
                            Icons.arrow_drop_down_circle_outlined,
                            color: Colors.white,
                          ),
                          elevation: 16,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          underline: Container(height: 2, color: Colors.white),
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _selectedResolution = value;
                                _setCameraStatus(value);
                              });
                            }
                          },
                          items: resolutions.map<DropdownMenuItem<String>>(
                                (String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: _isRecording ? _stopRecordVideo : _openCamera,
                child: Icon(
                  _isRecording ? Icons.stop_sharp : Icons.circle,
                  size: 50,
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              child: Container(
                height: 40,
                width: 100,
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: _isRecording
                      ? Text(
                    "Recording",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      decoration: TextDecoration.none,
                    ),
                  )
                      : Text(
                    "Paused",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
