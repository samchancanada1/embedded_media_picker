import Flutter
import PhotosUI
import UIKit
import UniformTypeIdentifiers

public class EmbeddedMediaPickerPlugin: NSObject, FlutterPlugin {
  private var pendingResult: FlutterResult?
  private var activeDelegate: PickerDelegate?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "embedded_media_picker",
      binaryMessenger: registrar.messenger()
    )
    let instance = EmbeddedMediaPickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isEmbeddedPickerAvailable":
      result(false)
    case "pickMedia":
      pickMedia(arguments: call.arguments as? [String: Any], result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pickMedia(arguments: [String: Any]?, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(
        FlutterError(
          code: "already_active",
          message: "A media picker request is already active.",
          details: nil
        )
      )
      return
    }

    guard let presentingViewController = topViewController() else {
      result(
        FlutterError(
          code: "no_view_controller",
          message: "No foreground iOS view controller is available.",
          details: nil
        )
      )
      return
    }

    let options = PickerOptions(arguments: arguments)
    var configuration = PHPickerConfiguration(photoLibrary: .shared())
    configuration.selectionLimit = options.maxSelectionLimit
    configuration.filter = options.filter
    if #available(iOS 15.0, *), options.orderedSelection {
      configuration.selection = .ordered
    }

    let picker = PHPickerViewController(configuration: configuration)
    let delegate = PickerDelegate { [weak self] items, error in
      guard let self else { return }
      let pending = self.pendingResult
      self.pendingResult = nil
      self.activeDelegate = nil
      if let error {
        pending?(
          FlutterError(
            code: "load_failed",
            message: error.localizedDescription,
            details: nil
          )
        )
      } else {
        pending?(items.map(\.flutterMap))
      }
    }
    picker.delegate = delegate
    pendingResult = result
    activeDelegate = delegate
    presentingViewController.present(picker, animated: true)
  }

  private func topViewController() -> UIViewController? {
    let keyWindow = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { $0.isKeyWindow }

    var controller = keyWindow?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }
}

private struct PickerOptions {
  let mediaType: String
  let maxSelectionLimit: Int
  let orderedSelection: Bool

  init(arguments: [String: Any]?) {
    mediaType = arguments?["mediaType"] as? String ?? "imageAndVideo"
    let requestedLimit = arguments?["maxSelectionLimit"] as? Int ?? 1
    maxSelectionLimit = max(0, requestedLimit)
    orderedSelection = arguments?["orderedSelection"] as? Bool ?? false
  }

  var filter: PHPickerFilter? {
    switch mediaType {
    case "image":
      return .images
    case "video":
      return .videos
    default:
      return .any(of: [.images, .videos])
    }
  }
}

private final class PickerDelegate: NSObject, PHPickerViewControllerDelegate {
  typealias Completion = ([MediaItem], Error?) -> Void

  private let completion: Completion

  init(completion: @escaping Completion) {
    self.completion = completion
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)

    guard !results.isEmpty else {
      completion([], nil)
      return
    }

    let group = DispatchGroup()
    let lock = NSLock()
    var output = Array<MediaItem?>(repeating: nil, count: results.count)
    var firstError: Error?

    for (index, result) in results.enumerated() {
      guard let typeIdentifier = preferredTypeIdentifier(from: result.itemProvider) else {
        continue
      }

      group.enter()
      result.itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
        defer { group.leave() }

        if let error {
          lock.lock()
          if firstError == nil {
            firstError = error
          }
          lock.unlock()
          return
        }

        guard let url else { return }

        do {
          let copiedURL = try Self.copyToTemporaryFile(
            sourceURL: url,
            typeIdentifier: typeIdentifier,
            suggestedName: result.itemProvider.suggestedName
          )
          let item = MediaItem(
            url: copiedURL,
            typeIdentifier: typeIdentifier,
            fileName: copiedURL.lastPathComponent,
            sizeBytes: Self.fileSize(at: copiedURL),
            isTemporary: true
          )
          lock.lock()
          output[index] = item
          lock.unlock()
        } catch {
          lock.lock()
          if firstError == nil {
            firstError = error
          }
          lock.unlock()
        }
      }
    }

    group.notify(queue: .main) {
      self.completion(output.compactMap { $0 }, firstError)
    }
  }

  private func preferredTypeIdentifier(from provider: NSItemProvider) -> String? {
    let identifiers = provider.registeredTypeIdentifiers
    let preferredTypes = [
      UTType.image.identifier,
      UTType.movie.identifier,
      UTType.video.identifier,
      UTType.item.identifier,
    ]

    for preferredType in preferredTypes {
      for identifier in identifiers {
        guard
          let candidate = UTType(identifier),
          let target = UTType(preferredType)
        else {
          continue
        }
        if candidate.conforms(to: target) {
          return identifier
        }
      }
    }

    return identifiers.first
  }

  private static func copyToTemporaryFile(
    sourceURL: URL,
    typeIdentifier: String,
    suggestedName: String?
  ) throws -> URL {
    let fileExtension = UTType(typeIdentifier)?.preferredFilenameExtension
      ?? sourceURL.pathExtension
      .ifEmpty("tmp")
    let cleanName = suggestedName?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .ifEmpty(UUID().uuidString)
      ?? UUID().uuidString
    let baseName = (cleanName as NSString).deletingPathExtension
    let destination = FileManager.default.temporaryDirectory
      .appendingPathComponent("\(baseName)-\(UUID().uuidString)")
      .appendingPathExtension(fileExtension)

    if FileManager.default.fileExists(atPath: destination.path) {
      try FileManager.default.removeItem(at: destination)
    }
    try FileManager.default.copyItem(at: sourceURL, to: destination)
    return destination
  }

  private static func fileSize(at url: URL) -> Int64? {
    guard
      let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
      let size = attributes[.size] as? NSNumber
    else {
      return nil
    }
    return size.int64Value
  }
}

private struct MediaItem {
  let url: URL
  let typeIdentifier: String
  let fileName: String?
  let sizeBytes: Int64?
  let isTemporary: Bool

  var flutterMap: [String: Any?] {
    let mediaType = Self.mediaType(for: typeIdentifier)
    return [
      "uri": url.absoluteString,
      "type": mediaType,
      "mimeType": UTType(typeIdentifier)?.preferredMIMEType,
      "fileName": fileName,
      "sizeBytes": sizeBytes,
      "isTemporary": isTemporary,
    ]
  }

  private static func mediaType(for typeIdentifier: String) -> String {
    guard let type = UTType(typeIdentifier) else {
      return "unknown"
    }
    if type.conforms(to: .image) {
      return "image"
    }
    if type.conforms(to: .movie) || type.conforms(to: .video) {
      return "video"
    }
    return "unknown"
  }
}

private extension String {
  func ifEmpty(_ fallback: String) -> String {
    isEmpty ? fallback : self
  }
}
