# flutter_camera_60fps_ios

[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Foakleychen0707%2Fflutter_camera_60fps_ios%2Ftree%2Fmain&count_bg=%23473DC8&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

中文說明：

使用 Flutter camera 套件 製作了可以設置解析度與 60fps 與 120fps 的錄影系統。

目前只支援iOS系統。

此專案以支援以下7種格式的錄影App（720p/30fps、1080p/30fps、4K/30fps、720p/60fps、1080p/60fps、4K/60fps、1080p/120fps）。

---
English instructions：

Using the Flutter camera package to create a video recording application that allows for adjusting the resolution and frame rates to 60fps and 120fps.

Please note that this feature is currently available only on iOS.

This project supports video recording in seven formats: 720p/30fps, 1080p/30fps, 4K/30fps, 720p/60fps, 1080p/60fps, 4K/60fps, and 1080p/120fps.


The following project results image.
（以下為專案成果圖）

<img src= https://github.com/oakleychen0707/flutter_camera_60fps_ios/assets/98889131/89143f07-168b-4492-bfc7-c0d015f71282 width="40%" height="40%">

------------------------------------------------------------------------------------------------------------------

主要是透過 Flutter 與 iOS 原生碼去溝通，實現方式是使用 main.dart 與 iOS的 AppDelegate.swift 之間建立平台通道執行特定的代碼。

平台通道可以參考：https://doc.flutterchina.club/platform-channels/

## 首先，先將以下套件加入 pubspec.yaml

•  camera：用於訪問和控制設備相機的套件

官方文檔：https://pub.dev/packages/camera

•  gallery_saver：將拍攝的相片或影片保存到手機的套件

官方文檔：https://pub.dev/packages/camera

```
dependencies:
  flutter:
    sdk: flutter
  camera:
  gallery_saver:
```

### 取得訪問相機的權限，新增兩行到 ios/Runner/Info.plist

```
<key>NSCameraUsageDescription</key>
<string>your usage description here</string>
<key>NSMicrophoneUsageDescription</key>
<string>your usage description here</string>
```
## 接下來，建立「平台溝通」（main.dart）

```
//設定相機的解析度與fps//
//1.
  final MethodChannel _cameraConfigurationChannel = MethodChannel('samples.flutter.dev/camera_configuration');
//2.
  Future<void> _setCameraConfiguration(int resolution) async {
    try {
//3.
      final bool success = await _cameraConfigurationChannel.invokeMethod(
        'setCameraConfiguration',
        {'format': resolution},
      );
//4.
      if (success) {
        print('Camera resolution set to: $resolution');
      } else {
        print('Failed to set camera resolution: $resolution');
      }
//5.
    } on PlatformException catch (e) {
      print('Error: ${e.message}');
    }
  }
  //設定相機的解析度與fps//
```

1. 建立一個 ```_cameraConfigurationChannel``` 的通道，用來與原生平台溝通（iOS）

2. 定義一個 ```setCameraConfiguration``` 的函式，接收一個整數參數 ```resolution```（用來代表相機的解析度與fps）

3. 函式裡使用 ```_cameraConfigurationChannel.invokeMethod``` 來呼叫原生代碼中的 ```setCameraConfiguration```，並傳遞 ```resolution``` 參數

4. 如果設定成功（```success``` 為 ```true```），則會顯示一條訊息表示相機解析度設定成功，否則顯示設定失敗的訊息

5. 如果在呼叫原生方法時出現異常（例如平台不支援等），則會捕獲 ```PlatformException``` 並輸出錯誤訊息

## AppDelegate.swift 的部分（ios/Runner/AppDelegate.swift）

以下是完整的 AppDelegate.swift

```
//1.
import UIKit
import Flutter
import AVFoundation // Add this line for importing AVFoundation module

@UIApplicationMain
//2.
@objc class AppDelegate: FlutterAppDelegate {
//3.
    @objc func setCameraFps(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                try device.lockForConfiguration()
                device.whiteBalanceMode = .locked
                if let arguments = call.arguments as? [String: Any],
                   let format = arguments["format"] as? Int {
                    switch format {
                        case 720:
                            setCameraFormat(device, formatIndex: 18, minFrameDuration: CMTimeMake(value: 1, timescale: 60))
                        case 1080:
                            setCameraFormat(device, formatIndex: 30, minFrameDuration: CMTimeMake(value: 1, timescale: 60))
                        case 2160:
                            setCameraFormat(device, formatIndex: 55, minFrameDuration: CMTimeMake(value: 1, timescale: 60))
                        case 1080120:
                            setCameraFormat(device, formatIndex: 36, minFrameDuration: CMTimeMake(value: 1, timescale: 120))
                        default:
                            break
                    }
                    device.unlockForConfiguration()
                    result(true) // Return success
                }
            } catch {
                result(false) // Return failure
            }
        } else {
            result(false) // Return failure
        }
    }

    func setCameraFormat(_ device: AVCaptureDevice, formatIndex: Int, minFrameDuration: CMTime) {
        device.activeFormat = device.formats[formatIndex]
        device.activeVideoMinFrameDuration = minFrameDuration
        device.activeVideoMaxFrameDuration = minFrameDuration
        print(device.activeFormat.videoSupportedFrameRateRanges.first!.maxFrameRate)
    }
//4.
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

        let cameraFpsChannel = FlutterMethodChannel(name: "samples.flutter.dev/camera_configuration",
                                                    binaryMessenger: controller.binaryMessenger)

        cameraFpsChannel.setMethodCallHandler(setCameraFps(_:result:))

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

1. 首先，導入 UIKit、Flutter 和 AVFoundation 模組

2. ```AppDelegate``` 類別繼承自 ```FlutterAppDelegate```，這是 Flutter 應用程式的主要代理（delegate）

3. ```setCameraFps``` 方法是一個原生方法，接收來自 Flutter 的呼叫（```FlutterMethodCall```），並提供一個回傳結果的 callback（```FlutterResult```）

•  它先檢查是否能取得預設的視訊裝置（相機）

•  如果成功取得，則嘗試對相機進行配置設定

•  根據 Flutter 傳遞的參數（arguments）中的 format 值，切換相機的格式和fps

•  最後，解鎖相機配置，並根據設定的結果回傳成功或失敗

4. ```application(_:didFinishLaunchingWithOptions:)``` 方法是應用程式啟動時的回調方法

•  在這裡，它設定了 Flutter 與原生 iOS 之間的通訊通道（channel）```cameraFpsChannel```，並指定了方法為 ```setCameraFps```



__因為 camera套件本身就是設置成30fps，所以上面組要是針對30fps以上才需要與原生平台溝通__

•  720 → 720p/60fps

•  1080 → 1080p/60fps

•  2160 → 4K/60fps

•  1080120 → 1080p/120fps

## 如果想要其他的錄影格式，可以使用以下程式碼，去印出設備所支援的所有格式

```
for format in device.formats{
 let mediaType = format.mediaType
  let formatDescription = format.formatDescription
  let videoFieldOfView = format.videoFieldOfView
// 印出mediaType、formatDescription和videoFieldOfView屬性
  print("The format of \(format) is \(mediaType) \(formatDescription) with \(videoFieldOfView) degrees")
}
```
並依據印出的格式修改程式碼

```
device.activeFormat = device.formats[36]
device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 60)
device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 60)
```

•  device.formats[36] → 設定錄影格式

•  timescale：60 → 設定 fps

# 結語

Widget 就不詳細介紹了～ 可直接查看 main.dart 與 AppDelegate.swift(記得添加套件依賴與訪問權限！)

當初也是踩了不少坑，才成功做出來🥲

希望有幫助到大家！
