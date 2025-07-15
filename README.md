# flutter_camera_60fps_ios

Creating a video recording application with Flutter camera package that allows setting resolution and frame rates of 60fps and 120fps.

## Overview

### Chinese Version:

使用 Flutter Camera 套件實現了一款支持設置解析度及高幀率（60fps 和 120fps）的錄影 App。

- **系統支持**：目前僅支持 iOS。

- **格式支持**：該應用支持以下 7 種錄影格式：

  - 720p/30fps
  - 1080p/30fps
  - 4K/30fps
  - 720p/60fps
  - 1080p/60fps
  - 4K/60fps
  - 1080p/120fps

### English Version:

This project uses the Flutter Camera package to create a video recording application capable of configuring resolution and high frame rates (60fps and 120fps).

- **Supported System**: Currently available for iOS only.

- **Supported Formats**: The app supports the following seven video recording formats:

  - 720p/30fps
  - 1080p/30fps
  - 4K/30fps
  - 720p/60fps
  - 1080p/60fps
  - 4K/60fps
  - 1080p/120fps

---

## Project Preview

<p align="center">
<img src="https://github.com/oakleychen0707/flutter_camera_60fps_ios/assets/98889131/89143f07-168b-4492-bfc7-c0d015f71282" width=300>
</p>

## Implementation Details

This project bridges Flutter and native iOS code through **Platform Channels**, enabling precise camera configuration. The primary files involved are:

- `main.dart`: Contains Flutter code.
- `AppDelegate.swift`: Manages iOS-native camera configurations.

### Platform Channels Reference:
- Documentation: [Flutter China Platform Channels](https://doc.flutterchina.club/platform-channels/)

---

### Step 1: Add Dependencies

Add the following packages to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: # Used for accessing and controlling the device camera
  gallery_saver: # Used for saving captured photos or videos to the gallery
```

### Step 2: Request Permissions

Add camera and microphone usage permissions to ios/Runner/Info.plist:

```
<key>NSCameraUsageDescription</key>
<string>your usage description here</string>
<key>NSMicrophoneUsageDescription</key>
<string>your usage description here</string>
```

### Step 3: Implement Platform Channels in `main.dart`

The following example demonstrates how to configure camera resolution and frame rate:

```dart
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

1. Create a `_cameraConfigurationChannel` to communicate with the native platform (iOS).

2. Define a `setCameraConfiguration` function that takes an integer parameter `resolution` (representing the camera's resolution and fps).

3. Inside the function, use `_cameraConfigurationChannel.invokeMethod` to call the native method `setCameraConfiguration` and pass the `resolution` parameter.

4. If the configuration is successful (`success` is `true`), a message will be displayed indicating that the camera resolution has been successfully set. Otherwise, a failure message will be shown.

5. If an exception occurs while calling the native method (e.g., platform not supported), the `PlatformException` will be caught and the error message will be printed.

### Step 4: Configure Camera in `AppDelegate.swift`

Below is the complete implementation for `AppDelegate.swift`:

```swift
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

#### 1. Import Required Modules  
`UIKit`, `Flutter`, and `AVFoundation` are imported to enable iOS and Flutter integration and handle camera configurations.

#### 2. AppDelegate Class Definition  
The `AppDelegate` class extends `FlutterAppDelegate`, serving as the main delegate for the Flutter application.

#### 3. setCameraFps Method  
- This method handles calls from Flutter to configure the camera's FPS.  
- It retrieves the default video device (camera).  
- Depending on the `format` value received from Flutter, it updates the camera's resolution and FPS settings.  
- Configuration results (success or failure) are returned to Flutter.  

#### 4. Application Launch Setup  
- The `application(_:didFinishLaunchingWithOptions:)` method sets up the communication channel between Flutter and the native iOS platform.  
- The channel `cameraFpsChannel` is linked to the `setCameraFps` method.

⚠️ **Note:** Since the camera plugin is configured to use 30fps by default, the above implementation is only necessary for enabling frame rates higher than 30fps through communication with the native platform.

The following mappings represent the resolution and frame rate configurations supported:

- 720 → 720p/60fps (HD resolution at 60fps)
- 1080 → 1080p/60fps (Full HD resolution at 60fps)
- 2160 → 4K/60fps (Ultra HD resolution at 60fps)
- 1080120 → 1080p/120fps (Full HD resolution at 120fps for high-speed recording)

### Step 5: Explore Supported Formats

To identify other supported formats, use the following code snippet:

```swift
for format in device.formats{
 let mediaType = format.mediaType
  let formatDescription = format.formatDescription
  let videoFieldOfView = format.videoFieldOfView
// 印出 mediaType、formatDescription 和 videoFieldOfView 屬性
  print("The format of \(format) is \(mediaType) \(formatDescription) with \(videoFieldOfView) degrees")
}
```

You can then modify the code accordingly:

```swift
device.activeFormat = device.formats[36]
device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 60)
device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 60)
```

•  device.formats[36] → 設定錄影格式
•  timescale：60 → 設定 fps

# Conclusion
The above guide provides a complete workflow for implementing a high-frame-rate video recording application using Flutter and iOS native code. Additional details like widgets are available in the source files.

Feel free to explore and enhance the project further!
