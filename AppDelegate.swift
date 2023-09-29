import UIKit
import Flutter
import AVFoundation // Add this line for importing AVFoundation module

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    @objc func setCameraFps(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                try device.lockForConfiguration()
                device.whiteBalanceMode = .locked
                if let arguments = call.arguments as? [String: Any],
                   let format = arguments["format"] as? Int {
                    switch format {
                        case 720:
                            device.activeFormat = device.formats[18]
                            device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 60)
                            device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 60)
                            print(device.activeFormat.videoSupportedFrameRateRanges.first!.maxFrameRate)
                        case 1080:
                            device.activeFormat = device.formats[30]
                            device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 60)
                            device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 60)
                            print(device.activeFormat.videoSupportedFrameRateRanges.first!.maxFrameRate)
                        case 2160:
                            device.activeFormat = device.formats[55]
                            device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 60)
                            device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 60)
                            print(device.activeFormat.videoSupportedFrameRateRanges.first!.maxFrameRate)
                        case 1080120:
                            device.activeFormat = device.formats[36]
                            device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 120)
                            device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 120)
                            print(device.activeFormat.videoSupportedFrameRateRanges.first!.maxFrameRate)
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
