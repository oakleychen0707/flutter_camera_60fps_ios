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
