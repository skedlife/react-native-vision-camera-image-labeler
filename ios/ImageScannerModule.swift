import Foundation
import UIKit
import React
import MLKitVision
import MLKitImageLabeling

@objc(ImageScannerModule)
class ImageScannerModule: NSObject {

    private var data: [Any] = []

    @objc(process:orientation:minConfidence:withResolver:withRejecter:)
    private func process(base64: String, orientation: String, minConfidence: Double, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        // Step 1: Decode Base64 string to Data
        guard let imageData = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else {
            reject("Error", "Invalid Base64 Image", nil)
            return
        }
        // Step 2: Create UIImage from Data
        guard let image = UIImage(data: imageData) else {
            reject("Error", "Unable to create Image from Base64", nil)
            return
        }
        let options = ImageLabelerOptions()
        options.confidenceThreshold = minConfidence as NSNumber
        let labeler = ImageLabeler.imageLabeler(options: options)
        do {
            let visionImage = VisionImage(image: image)
            visionImage.orientation = getOrientation(orientation: orientation)
            let labels = try labeler.results(in: visionImage)
            var data: [Any] = []
            for label in labels {
                var obj: [String: Any] = [:]
                obj["labelText"] = label.text
                obj["confidence"] = label.confidence
                data.append(obj)
            }
            resolve(data)
        } catch {
            reject("Error", "Processing Image", nil)
        }
    }

    @objc(old_process:orientation:minConfidence:withResolver:withRejecter:)
    private func old_process(uri: String,orientation:String,minConfidence:Double, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {

            let image =  UIImage(contentsOfFile: uri)
            let options = ImageLabelerOptions()
            options.confidenceThreshold = (minConfidence) as NSNumber
            let labeler = ImageLabeler.imageLabeler(options: options)
            if image != nil {
                do {
                    let visionImage = VisionImage(image: image!)
                    visionImage.orientation = getOrientation(orientation: orientation)
                    let labels = try labeler.results(in: visionImage)

                    for label in labels {
                        var obj : [String:Any] = [:]
                        obj["labelText"] = label.text
                        obj["confidence"] = label.confidence
                        data.append(obj)
                        if label.text.isEmpty {
                            resolve([])
                        }else{
                            resolve(data)
                        }
                    }
                }catch{
                    reject("Error","Processing Image",nil)
                }
            }else{
                reject("Error","Can't Find Photo",nil)
            }
    }

    private func imageFileToBase64(filePathString: String) -> String? {
      guard let url = URL(string: filePathString) else {
          print("Invalid URL string")
          return nil
      }
      let filePath = url.path // Converts file:///path/to/file.jpg to /path/to/file.jpg
      let fileManager = FileManager.default
      // Optionally check if file exists
      guard fileManager.fileExists(atPath: filePath) else {
          print("File does not exist at path: \(filePath)")
          return nil
      }
      do {
          let imageData = try Data(contentsOf: url)
          return imageData.base64EncodedString(options: .lineLength64Characters)
      } catch {
          print("Error reading file: \(error)")
          return nil
      }
    }

    @objc(toBase64:withResolver:withRejecter:)
    func toBase64(_ filePath: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        if let base64 = imageFileToBase64(filePathString: filePath) {
            resolve(base64)
        } else {
            reject("ERROR", "Failed to convert image to base64", nil)
        }
    }

    private func getOrientation(
      orientation: String
    ) -> UIImage.Orientation {
        switch orientation {
        case "portrait":
            return .right
        case "landscapeLeft":
            return .up
        case "portraitUpsideDown":
            return .left
        case "landscapeRight":
            return  .down
        default:
            return .up
        }

   }
}
