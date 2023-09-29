import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';

const List<String> list = <String>['720p/30fps', '1080p/30fps', '4K/30fps','720p/60fps','1080p/60fps','4K/60fps','1080p/120fps'];
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key,});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget{
  const CameraPage({
    super.key,
  });

  @override
  State <CameraPage> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraPage> {

  bool _isLoading = true;
  bool _isRecording = false;
  late CameraController _cameraController;

  String dropdownValue = list[4]; //默認1080p/60fps
  String camerastatus = "1080p/60fps";


  //設定相機的解析度與60fps//
  final MethodChannel _cameraConfigurationChannel = MethodChannel('samples.flutter.dev/camera_configuration');

  Future<void> setCameraConfiguration(int resolution) async {
    try {
      final bool success = await _cameraConfigurationChannel.invokeMethod('setCameraConfiguration', {'format': resolution});
      if (success) {
        print('相機解析度：$resolution 設定成功');
      } else {
        print('設定失敗 相機解析度：$resolution');
      }
    } on PlatformException catch (e) {
      print('Error: ${e.message}');
    }
  }
  //設定相機的解析度與60fps//

  Future<void> opencamera()async {
    Map<String, int> cameraConfigurations = {
      "1080p/60fps": 1080,
      "720p/60fps": 720,
      "4K/60fps": 2160,
      "1080p/120fps": 1080120,
    };

    int? configuration = cameraConfigurations[camerastatus];

    if (configuration != null) {
      await setCameraConfiguration(configuration);
    }

    await _cameraController.prepareForVideoRecording();
    await _cameraController.startVideoRecording();
    setState(() => _isRecording = true);
  }

  late File videofile;

  stoprecordVideo() async {
    final file = await _cameraController.stopVideoRecording();
    print(file.path);
    videofile = File(file.path);

    if(file != null)
    {
      var videoFilePath = videofile.path;
      await GallerySaver.saveVideo(videoFilePath);
      print(videoFilePath);
    }
    setState(() => _isRecording = false);
  }

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

    Map<String, ResolutionPreset> cameraConfigurations = {
      "720p/30fps": ResolutionPreset.high,
      "720p/60fps": ResolutionPreset.high,
      "1080p/30fps": ResolutionPreset.veryHigh,
      "1080p/60fps": ResolutionPreset.veryHigh,
      "1080p/120fps": ResolutionPreset.veryHigh,
      "4K/30fps": ResolutionPreset.ultraHigh,
      "4K/60fps": ResolutionPreset.ultraHigh,
    };

    ResolutionPreset resolutionPreset = cameraConfigurations[camerastatus] ?? ResolutionPreset.veryHigh; //默認使用VeryHigh

    _cameraController = CameraController(firstCamera, resolutionPreset);
    //// 720p (1280x720)high,
    //// 1080p (1920x1080)veryHigh,
    //// 2160p (3840x2160 on Android and iOS, 4096x2160 on Web)ultraHigh,
    await _cameraController.initialize();

    if (_cameraController.value.isInitialized) {
      print("相機當前設定：");
      print(_cameraController.value.previewSize);
    } else {
      print("相機初始化失敗！");
    }
    setState(() => _isLoading = false);
  }

  void _setCameraStatus(String value) {
    Map<String, String> cameraStatusMap = {
      '720p/30fps': '720p/30fps',
      '1080p/30fps': '1080p/30fps',
      '4K/30fps': '4K/30fps',
      '720p/60fps': '720p/60fps',
      '1080p/60fps': '1080p/60fps',
      '4K/60fps': '4K/60fps',
      '1080p/120fps': '1080p/120fps',
    };

    if (cameraStatusMap.containsKey(value)) {
      camerastatus = cameraStatusMap[value]!;

      if (['720p/30fps', '1080p/30fps', '4K/30fps'].contains(camerastatus)) {
        _initCamera();
      }
      print(camerastatus);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Center(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children:  <Widget>[
            Padding(padding: EdgeInsets.all(2),
              child: CameraPreview(_cameraController,
                child: Center(
                  child:
                  Text("+",style: TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                      decoration: TextDecoration.none),),),),),
            Padding(
              padding: EdgeInsets.all(50),
              child:
              FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: _isRecording ? () => stoprecordVideo() :
                    () => opencamera(),
                child: Icon(_isRecording == true? Icons.stop_sharp : Icons.circle,size: 50,),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                width: 140,
                height: 50,
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Text(
                    "相機解析度：",
                    style: TextStyle(fontSize: 20, color: Colors.white, decoration: TextDecoration.none),
                  ),
                ),
              ),
            ),
            Positioned(
                top: 20,
                left: 160,
                child:
                    Container(
                      height: 50,
                      width: 130,
                      color: Colors.black.withOpacity(0.4),
                      child:
                          Theme(data: Theme.of(context).copyWith(
                            canvasColor: Colors.black.withOpacity(0.4),),
                            child: Center(
                              child: Material(
                                color: Colors.transparent,
                                child: DropdownButton<String>(
                                  value: dropdownValue,
                                  icon: Icon(Icons.arrow_drop_down_circle_outlined,color: Colors.white,),
                                  elevation: 16,
                                  style: TextStyle(color: Colors.white,fontSize: 16),
                                  underline: Container(height: 2, color: Colors.white),
                                  onChanged: (String? value) {
                                    setState(() {
                                      dropdownValue = value!;
                                      _setCameraStatus(value);
                                    });
                                    },
                                  items: list.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),),
                            ),),
                    ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly ,
              children: <Widget>[
                const SizedBox(width: 200),
                Container(
                  height: 40,
                  width: 100,
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: _isRecording == true?
                    Text("正在錄影",style: TextStyle(color: Colors.white,fontSize: 20,decoration: TextDecoration.none),):
                    Text("暫停錄影",style: TextStyle(color: Colors.white,fontSize: 20,decoration: TextDecoration.none),),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical:80),
                )
              ],),
          ],
        ),
      );
    }
  }
}


