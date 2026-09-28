//
//  CreatePostViewController.swift
//  Project2
//
//  Created by Ritch Barlatier on 9/20/26.
//

import UIKit
import PhotosUI
import Photos
import ParseSwift
import CoreLocation
import UniformTypeIdentifiers
import CoreImage

class CreatePostViewController: UIViewController {
    
    // MARK: - Properties
    private var selectedImage: UIImage?
    private var selectedAsset: PHAsset?
    private var photoMetadata: PhotoMetadata?
    private var imageLoadingIndicator: UIActivityIndicatorView?
    private let locationManager = CLLocationManager()
    
    // MARK: - UI Elements
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let libraryButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.bordered()
        configuration.title = "Library"
        configuration.image = UIImage(systemName: "photo")
        configuration.imagePadding = 6
        button.configuration = configuration
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let cameraButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.bordered()
        configuration.title = "Camera"
        configuration.image = UIImage(systemName: "camera")
        configuration.imagePadding = 6
        button.configuration = configuration
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let captionTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private let locationStatusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Select a photo to check its location."
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let useCurrentLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Use Current Location", for: .normal)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let postButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Share"
        configuration.image = UIImage(systemName: "square.and.arrow.up")
        configuration.imagePadding = 6
        configuration.cornerStyle = .medium
        button.configuration = configuration
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Create Post"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        captionTextView.text = ""
        captionTextView.accessibilityLabel = "Write a caption"

        let actionStack = UIStackView(arrangedSubviews: [libraryButton, cameraButton, postButton])
        actionStack.axis = .horizontal
        actionStack.alignment = .fill
        actionStack.distribution = .fillEqually
        actionStack.spacing = 8
        actionStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(actionStack)
        view.addSubview(captionTextView)
        view.addSubview(imageView)
        view.addSubview(locationStatusLabel)
        view.addSubview(useCurrentLocationButton)

        NSLayoutConstraint.activate([
            actionStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            actionStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionStack.heightAnchor.constraint(equalToConstant: 44),

            captionTextView.topAnchor.constraint(equalTo: actionStack.bottomAnchor, constant: 12),
            captionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            captionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            captionTextView.heightAnchor.constraint(equalToConstant: 72),

            imageView.topAnchor.constraint(equalTo: captionTextView.bottomAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            locationStatusLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            locationStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            locationStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            useCurrentLocationButton.topAnchor.constraint(equalTo: locationStatusLabel.bottomAnchor, constant: 4),
            useCurrentLocationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            useCurrentLocationButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])

        libraryButton.addTarget(self, action: #selector(libraryTapped), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
        useCurrentLocationButton.addTarget(self, action: #selector(useCurrentLocationTapped), for: .touchUpInside)
        postButton.addTarget(self, action: #selector(postTapped), for: .touchUpInside)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    // MARK: - Actions
    @objc private func libraryTapped() {
        requestPhotoLibraryAccess()
    }

    @objc private func cameraTapped() {
        presentCamera()
    }

    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(message: "The camera is not available on this device.")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.mediaTypes = [UTType.image.identifier]
        picker.allowsEditing = false
        picker.delegate = self

        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            picker.cameraDevice = .rear
        }

        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }

    private func requestPhotoLibraryAccess() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .notDetermined else {
            presentPhotoPicker()
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] _ in
            DispatchQueue.main.async {
                self?.presentPhotoPicker()
            }
        }
    }

    private func presentPhotoPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            showAlert(message: "The photo library is not available on this device.")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [UTType.image.identifier]
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)

        print("📷 Presenting system photo library picker...")
    }

    @objc private func useCurrentLocationTapped() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationStatusLabel.text = "Finding your current location…"
            locationManager.requestLocation()
        case .denied, .restricted:
            showAlert(message: "Location access is disabled. Enable it in Settings to attach your current location.")
        @unknown default:
            showAlert(message: "Location access is unavailable.")
        }
    }
    
    @objc private func postTapped() {
        guard let image = selectedImage else {
            showAlert(message: "Please select an image")
            return
        }


        guard User.current != nil else {
            showAlert(message: "Please sign in again before creating a post.")
            return
        }
        
        // Note: provider-based metadata extraction moved to the picker delegate where `provider` is available.
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            showAlert(message: "Failed to process image")
            return
        }
        
        // Show loading indicator
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        view.isUserInteractionEnabled = false
        
        Task { @MainActor in
            var uploadStage = "image file"
            do {
                print("🚀 Starting post creation...")
                
                // Create ParseFile with a unique name
                let fileName = "photo_\(UUID().uuidString).jpg"
                var imageFile = ParseFile(name: fileName, data: imageData)
                
                // IMPORTANT: Save the file first to get a URL
                print("📤 Uploading image file...")
                imageFile = try await imageFile.save()
                print("✅ Image uploaded successfully! URL: \(imageFile.url?.absoluteString ?? "no url")")
                
                // Create Post
                var post = Post()
                post.caption = captionTextView.text.isEmpty ? nil : captionTextView.text
                post.imageFile = imageFile
                post.user = User.current
                
                // Add photo metadata if available
                if let metadata = photoMetadata {
                    post.photoCreationDate = metadata.creationDate
                    print("📸 Adding photo creation date: \(metadata.creationDate?.description ?? "none")")
                    
                    // Add location data
                    if let location = metadata.location {
                        // Create ParseGeoPoint
                        let geoPoint = try ParseGeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                        post.location = geoPoint
                        print("📍 Adding location GeoPoint: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                        
                        // Get readable location name
                        do {
                            let locationName = try await LocationHelper.getShortLocationName(from: location)
                            post.locationName = locationName
                            print("📍 Location name resolved to: \(locationName)")
                        } catch {
                            // If geocoding fails, use coordinates as fallback
                            let fallbackName = String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude)
                            post.locationName = fallbackName
                            print("⚠️ Failed to resolve location name, using coordinates: \(fallbackName)")
                            print("   Error: \(error.localizedDescription)")
                        }
                    } else {
                        print("ℹ️ No location data in photo (photo.location is nil)")
                        print("   This is normal for: screenshots, downloaded images, or photos taken with Location Services off")
                    }
                } else {
                    print("ℹ️ No photo metadata available (photoMetadata is nil)")
                    print("   This means metadata extraction failed completely")
                }
                
                // Debug: Log what we're about to save
                print("💾 Saving post with:")
                print("   Caption: \(post.caption ?? "none")")
                print("   Location Name: \(post.locationName ?? "none")")
                print("   Image File URL: \(post.imageFile?.url?.absoluteString ?? "none")")
                print("   User: \(post.user?.username ?? "none")")
                
                // Save post
                uploadStage = "post record"
                let savedPost = try await post.save()
                print("✅ Post saved successfully!")
                print("   ObjectId: \(savedPost.objectId ?? "none")")
                print("   CreatedAt: \(savedPost.createdAt?.description ?? "none")")
                print("   Location Name: \(savedPost.locationName ?? "none")")
                print("   Location GeoPoint: \(savedPost.location != nil ? "YES" : "NO")")
                print("   Image File: \(savedPost.imageFile?.url?.absoluteString ?? "none")")
                
                uploadStage = "user's last-post date"
                guard var currentUser = User.current else {
                    throw PostCreationError.missingCurrentUser
                }
                currentUser.lastPostedDate = savedPost.createdAt ?? Date()
                let savedUser = try await currentUser.save()
                print("✅ Updated lastPostedDate: \(savedUser.lastPostedDate?.description ?? "none")")

                // Notify other parts of the app that a new post was created so they can refresh immediately
                print("📢 Posting didCreatePost notification to refresh feed...")
                NotificationCenter.default.post(name: .didCreatePost, object: savedPost)
                print("📢 Notification posted!")

                await MainActor.run {
                    activityIndicator.removeFromSuperview()
                    view.isUserInteractionEnabled = true
                    dismiss(animated: true)
                }
            } catch {
                print("❌ Error creating post: \(error)")
                await MainActor.run {
                    activityIndicator.removeFromSuperview()
                    view.isUserInteractionEnabled = true
                    showAlert(message: uploadErrorMessage(for: error, stage: uploadStage))
                }
            }
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Helper
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func uploadErrorMessage(for error: Error, stage: String) -> String {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return "The \(stage) could not reach the server. Check your internet connection and try again."
        }

        if nsError.code == 119 || nsError.code == 142 {
            return "The server does not allow this upload. Check the Post class permissions and file-storage settings."
        }

        let description = error.localizedDescription.lowercased()
        if description.contains("unauthorized") || description.contains("invalid key") {
            return "The server rejected the upload credentials. Check the Parse application ID and client key."
        }

        return "The \(stage) could not be uploaded (\(nsError.domain), code \(nsError.code)): \(error.localizedDescription)"
    }
}

// MARK: - UIImagePickerControllerDelegate
extension CreatePostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else {
            showAlert(message: "The selected photo could not be loaded.")
            return
        }

        selectedImage = image
        imageView.image = image

        if picker.sourceType == .camera {
            selectedAsset = nil
            var metadata = PhotoMetadata()
            metadata.creationDate = Date()
            metadata.width = Int(image.size.width * image.scale)
            metadata.height = Int(image.size.height * image.scale)
            photoMetadata = metadata
            locationStatusLabel.text = "Finding the photo's location…"
            postButton.isEnabled = false
            useCurrentLocationTapped()
        } else if let asset = info[.phAsset] as? PHAsset {
            selectedAsset = asset
            photoMetadata = PhotoMetadataHelper.extractMetadata(from: asset)
        } else {
            selectedAsset = nil
            photoMetadata = nil
        }
        updateLocationStatus()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension CreatePostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        print("📷 PHPicker delegate called with \(results.count) results")
        
        picker.dismiss(animated: true)
        
        guard let result = results.first else {
            print("ℹ️ No picker result (user cancelled or no selection)")
            return
        }
        
        // Show loading indicator
        showImageLoadingIndicator()
        
        let provider = result.itemProvider
        print("📷 Got item provider")
        print("📋 Available types: \(provider.registeredTypeIdentifiers)")
        
        if let assetIdentifier = result.assetIdentifier {
            loadAssetIfAvailable(assetIdentifier: assetIdentifier, fallbackProvider: provider)
        } else {
            photoMetadata = nil
            updateLocationStatus()
            loadImageFromProvider(provider)
        }
    }

    private func loadAssetIfAvailable(assetIdentifier: String, fallbackProvider: NSItemProvider) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else {
            photoMetadata = nil
            updateLocationStatus()
            loadImageFromProvider(fallbackProvider)
            return
        }

        selectedAsset = asset
        photoMetadata = PhotoMetadataHelper.extractMetadata(from: asset)
        updateLocationStatus()
        loadImageFromAsset(asset, fallbackProvider: fallbackProvider)
    }

    private func loadImageFromAsset(_ asset: PHAsset, fallbackProvider: NSItemProvider) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        options.version = .current

        let targetSize = CGSize(width: 2048, height: 2048)
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, info in
            guard let self else { return }

            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
            let isInCloud = (info?[PHImageResultIsInCloudKey] as? Bool) ?? false
            let error = info?[PHImageErrorKey] as? Error

            if let image, !isDegraded {
                print("✅ PhotoKit returned the selected image")
                self.finishImageLoading(with: image)
                return
            }

            if isCancelled || error != nil || (!isDegraded && !isInCloud) {
                if let error {
                    print("⚠️ PhotoKit image request failed: \(error.localizedDescription)")
                }
                self.loadContentEditingImage(from: asset, fallbackProvider: fallbackProvider)
            }
        }
    }

    private func loadContentEditingImage(from asset: PHAsset, fallbackProvider: NSItemProvider) {
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true

        asset.requestContentEditingInput(with: options) { [weak self] input, info in
            guard let self else { return }

            if let image = input?.displaySizeImage,
               image.size.width > 0,
               image.size.height > 0 {
                print("✅ Loaded PhotoKit display-size image")
                self.finishImageLoading(with: image)
                return
            }

            if let url = input?.fullSizeImageURL,
               let image = self.decodeImage(at: url) {
                print("✅ Loaded PhotoKit full-size image")
                self.finishImageLoading(with: image)
                return
            }

            if let error = info[PHContentEditingInputErrorKey] as? Error {
                print("⚠️ Content editing input failed: \(error.localizedDescription)")
            }
            self.loadImageFromProvider(fallbackProvider)
        }
    }

    private func decodeImage(at url: URL) -> UIImage? {
        if let image = UIImage(contentsOfFile: url.path),
           image.size.width > 0,
           image.size.height > 0 {
            return image
        }

        guard let ciImage = CIImage(contentsOf: url) else { return nil }
        let context = CIContext(options: [.cacheIntermediates: false])
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func updateLocationStatus() {
        DispatchQueue.main.async {
            if self.photoMetadata?.location != nil {
                self.locationStatusLabel.text = "The photo's saved location will be included."
                self.useCurrentLocationButton.isHidden = true
            } else {
                self.locationStatusLabel.text = "No location is stored in this photo."
                self.useCurrentLocationButton.isHidden = false
            }
        }
    }
    
    // MARK: - Provider-Based Loading
    private func loadImageFromProvider(_ provider: NSItemProvider) {
        let imageTypeIdentifiers = provider.registeredTypeIdentifiers.filter { identifier in
            UTType(identifier)?.conforms(to: .image) == true
        }

        guard !imageTypeIdentifiers.isEmpty else {
            finishImageLoading(with: nil, errorMessage: "The selected item does not contain a supported image.")
            return
        }

        // Loading the exact registered representation avoids unreliable HEIC-to-JPEG
        // conversions, particularly when an iOS app runs on Apple silicon Mac.
        loadDataRepresentation(
            from: provider,
            typeIdentifiers: imageTypeIdentifiers,
            index: 0
        )
    }

    private func loadDataRepresentation(
        from provider: NSItemProvider,
        typeIdentifiers: [String],
        index: Int
    ) {
        guard index < typeIdentifiers.count else {
            loadFileRepresentation(from: provider, typeIdentifiers: typeIdentifiers, index: 0)
            return
        }

        let typeIdentifier = typeIdentifiers[index]
        provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] data, error in
            guard let self else { return }

            if let data, let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 {
                print("✅ Loaded image data as \(typeIdentifier)")
                self.finishImageLoading(with: image)
                return
            }

            if let error {
                print("⚠️ Data representation \(typeIdentifier) failed: \(error.localizedDescription)")
            }
            self.loadDataRepresentation(from: provider, typeIdentifiers: typeIdentifiers, index: index + 1)
        }
    }

    private func loadFileRepresentation(
        from provider: NSItemProvider,
        typeIdentifiers: [String],
        index: Int
    ) {
        guard index < typeIdentifiers.count else {
            loadUIImageObject(from: provider)
            return
        }

        let typeIdentifier = typeIdentifiers[index]
        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] url, error in
            guard let self else { return }

            if let url,
               let data = try? Data(contentsOf: url),
               let image = UIImage(data: data),
               image.size.width > 0,
               image.size.height > 0 {
                print("✅ Loaded image file as \(typeIdentifier)")
                self.finishImageLoading(with: image)
                return
            }

            if let error {
                print("⚠️ File representation \(typeIdentifier) failed: \(error.localizedDescription)")
            }
            self.loadFileRepresentation(from: provider, typeIdentifiers: typeIdentifiers, index: index + 1)
        }
    }

    private func loadUIImageObject(from provider: NSItemProvider) {
        guard provider.canLoadObject(ofClass: UIImage.self) else {
            finishImageLoading(with: nil, errorMessage: "The selected image format could not be decoded.")
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self else { return }
            if let image = object as? UIImage, image.size.width > 0, image.size.height > 0 {
                self.finishImageLoading(with: image)
            } else {
                let detail = error?.localizedDescription ?? "No compatible image representation was returned."
                print("❌ All image loading strategies failed: \(detail)")
                self.finishImageLoading(
                    with: nil,
                    errorMessage: "This photo could not be decoded. Try exporting it as JPEG or PNG and selecting it again."
                )
            }
        }
    }

    private func finishImageLoading(with image: UIImage?, errorMessage: String? = nil) {
        DispatchQueue.main.async {
            self.hideImageLoadingIndicator()
            if let image {
                self.selectedImage = image
                self.imageView.image = image
                print("✅ Image displayed: \(image.size.width) x \(image.size.height)")
            } else if let errorMessage {
                self.showAlert(message: errorMessage)
            }
        }
    }
    
    // MARK: - Loading Indicator Helpers
    private func showImageLoadingIndicator() {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .systemGray
        imageView.addSubview(indicator)
        
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
        
        indicator.startAnimating()
        imageLoadingIndicator = indicator
        
        print("🔄 Showing image loading indicator...")
    }
    
    private func hideImageLoadingIndicator() {
        imageLoadingIndicator?.stopAnimating()
        imageLoadingIndicator?.removeFromSuperview()
        imageLoadingIndicator = nil
        print("✅ Image loading indicator hidden")
    }
}

// MARK: - CLLocationManagerDelegate
extension CreatePostViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            locationStatusLabel.text = "Finding your current location…"
            manager.requestLocation()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            locationStatusLabel.text = "Location access is disabled."
            useCurrentLocationButton.isHidden = false
            postButton.isEnabled = true
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        var metadata = photoMetadata ?? PhotoMetadata()
        metadata.location = location
        photoMetadata = metadata
        locationStatusLabel.text = "Your current location will be included."
        useCurrentLocationButton.isHidden = true
        postButton.isEnabled = true
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationStatusLabel.text = "Current location could not be determined."
        useCurrentLocationButton.isHidden = false
        postButton.isEnabled = true
        showAlert(message: "Could not determine your current location: \(error.localizedDescription)")
    }
}

private enum PostCreationError: LocalizedError {
    case missingCurrentUser

    var errorDescription: String? {
        "The post was uploaded, but the signed-in user could not be updated. Please sign in again."
    }
}
