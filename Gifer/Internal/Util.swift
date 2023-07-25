import AppKit
import AVFoundation
import Photos
import UniformTypeIdentifiers

extension URL {
    var encodeID: String {
        return self.pathComponents[self.pathComponents.count-1]
    }
}

struct CreateGIFOption {
    static var `default` = CreateGIFOption()
    
    var scale: CGFloat = 1
    var maxSize: CGSize? = nil
    var maxDuration: TimeInterval? = nil
}

func createGIF(from url: URL, exportTo distinationDir: URL, _ opt: CreateGIFOption = .default, updateProgress: @escaping (String, CGFloat) -> Void = { _,_ in }) async {
    let asset = AVURLAsset(url: url)
    guard let track = try? await asset.load(.tracks).first,
          let size = try? await track.load(.naturalSize),
          let frameRate = try? await track.load(.nominalFrameRate),
          let d = try? await asset.load(.duration).seconds else {
        print("load asset track error")
        return
    }
    
    var duration = d
    if let maxDuration = opt.maxDuration, duration > maxDuration {
        duration = maxDuration
    }
    
    let totalFrames = Int(duration * TimeInterval(frameRate))
    let delayBetweenFrames: TimeInterval = 1.0 / TimeInterval(frameRate)
    
    var timeValues: [NSValue] = []
    
    for frameNumber in 0 ..< totalFrames {
        let seconds = TimeInterval(delayBetweenFrames) * TimeInterval(frameNumber)
        let time = CMTime(seconds: seconds, preferredTimescale: Int32(NSEC_PER_SEC))
        timeValues.append(NSValue(time: time))
    }
    
    let generator = AVAssetImageGenerator(asset: asset)
    generator.requestedTimeToleranceBefore = CMTime(seconds: 0.05, preferredTimescale: 600)
    generator.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: 600)
    
    generator.maximumSize = CGSize(width: size.width*opt.scale, height: size.height*opt.scale)
    if let maxSize = opt.maxSize {
        var wRatio = CGFloat(1)
        var hRatio = CGFloat(1)
        if generator.maximumSize.width > maxSize.width {
            wRatio = maxSize.width/generator.maximumSize.width
        }
        
        if generator.maximumSize.height > maxSize.height {
            hRatio = maxSize.height/generator.maximumSize.height
        }
        
        if hRatio < wRatio {
            generator.maximumSize = CGSize(width: generator.maximumSize.width * hRatio,
                                           height: generator.maximumSize.height * hRatio)
        } else {
            generator.maximumSize = CGSize(width: generator.maximumSize.width * wRatio,
                                           height: generator.maximumSize.height * wRatio)
        }
    }
    
    // Set up resulting image
    let fileProperties: [String: Any] = [
        kCGImagePropertyGIFDictionary as String: [
            kCGImagePropertyGIFLoopCount as String: 0
        ]
    ]
    
    let frameProperties: [String: Any] = [
        kCGImagePropertyGIFDictionary as String: [
            kCGImagePropertyGIFDelayTime: delayBetweenFrames

        ]
    ]
    let name = url.pathComponents[url.pathComponents.count-1]
    print("Converting \(name)...")
    let resultingFileURL = distinationDir.appendingPathComponent("\(name).gif")
    guard let destination = CGImageDestinationCreateWithURL(resultingFileURL as CFURL, UTType.gif.identifier as CFString, totalFrames, nil) else {
        print("can't create CGImage destination url")
        return
    }
    
    CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
    
    print("Converting to GIF...")
    var framesProcessed = 0
    let startTime = CFAbsoluteTimeGetCurrent()
    
    generator.generateCGImagesAsynchronously(forTimes: timeValues) { (requestedTime, resultingImage, actualTime, result, error) in
        guard let resultingImage = resultingImage else { return }
        
        framesProcessed += 1
        updateProgress(url.encodeID, CGFloat(framesProcessed)/CGFloat(totalFrames))
        
        CGImageDestinationAddImage(destination, resultingImage, frameProperties as CFDictionary)
        
        if framesProcessed == totalFrames {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("Done converting to GIF! Frames processed: \(framesProcessed) • Total time: \(timeElapsed) s.")
            
            // Save to Photos just to check…
            let ok = CGImageDestinationFinalize(destination)
            updateProgress(url.encodeID, ok ? 2: -1)
        }
    }
}
