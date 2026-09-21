//
//  CreatePostViewController.swift
//  Project2
//
//  Created by Ritch Barlatier on 9/20/26.
//

import UIKit
import PhotosUI
import ParseSwift
import CoreLocation

class CreatePostViewController: UIViewController {
    
    // MARK: - Properties
    private var selectedImage: UIImage?
    private var selectedAsset: PHAsset?
    private var photoMetadata: PhotoMetadata?
    private var imageLoadingIndicator: UIActivityIndicatorView?
    
    // MARK: - UI Elements
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let selectImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select Image", for: .normal)
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
    
    private let postButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Post", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
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
        
        view.addSubview(imageView)
        view.addSubview(selectImageButton)
        view.addSubview(captionTextView)
        view.addSubview(postButton)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalToConstant: 300),
            
            selectImageButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            selectImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            captionTextView.topAnchor.constraint(equalTo: selectImageButton.bottomAnchor, constant: 20),
            captionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            captionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            captionTextView.heightAnchor.constraint(equalToConstant: 100),
            
            postButton.topAnchor.constraint(equalTo: captionTextView.bottomAnchor, constant: 20),
            postButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            postButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            postButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        selectImageButton.addTarget(self, action: #selector(selectImageTapped), for: .touchUpInside)
        postButton.addTarget(self, action: #selector(postTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func selectImageTapped() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        // Use .current to get original image data
        // Our multi-strategy loader handles all formats (JPEG, PNG, HEIC, etc.)
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
        
        print("📷 Presenting PHPicker with .current mode...")
    }
    
    @objc private func postTapped() {
        guard let image = selectedImage else {
            showAlert(message: "Please select an image")
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
        
        Task {
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
                let savedPost = try await post.save()
                print("✅ Post saved successfully!")
                print("   ObjectId: \(savedPost.objectId ?? "none")")
                print("   CreatedAt: \(savedPost.createdAt?.description ?? "none")")
                print("   Location Name: \(savedPost.locationName ?? "none")")
                print("   Location GeoPoint: \(savedPost.location != nil ? "YES" : "NO")")
                print("   Image File: \(savedPost.imageFile?.url?.absoluteString ?? "none")")
                
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
                    showAlert(message: "Failed to create post: \(error.localizedDescription)")
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
        
        // ULTIMATE FIX: If we have an asset identifier, load directly from PHAsset
        // This completely bypasses PHPicker's conversion issues
        if let assetIdentifier = result.assetIdentifier {
            print("🎯 DIRECT ASSET LOADING: Using PHAsset (most reliable method)")
            loadImageFromPHAsset(identifier: assetIdentifier)
        } else {
            print("📷 No asset ID, using provider-based loading")
            loadImageFromProvider(provider)
        }
    }
    
    // MARK: - Direct PHAsset Loading (Most Reliable)
    private func loadImageFromPHAsset(identifier: String) {
        print("📸 Fetching PHAsset for identifier: \(identifier)")
        
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        
        guard let asset = fetchResult.firstObject else {
            print("❌ Could not fetch PHAsset")
            DispatchQueue.main.async {
                self.hideImageLoadingIndicator()
                self.showAlert(message: "Could not access photo from library")
            }
            return
        }
        
        print("✅ Got PHAsset, requesting image...")
        self.selectedAsset = asset
        
        // Extract metadata immediately (we have the asset)
        self.photoMetadata = PhotoMetadataHelper.extractMetadata(from: asset)
        print("✅ Metadata extracted")
        if let metadata = self.photoMetadata {
            print("   Creation date: \(metadata.creationDate?.description ?? "Unknown")")
            if let location = metadata.location {
                print("   Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
        
        // Request the actual image data from Photos framework
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true // Allow iCloud downloads
        options.isSynchronous = false
        options.version = .current
        
        // Request target size - use a reasonable size to avoid memory issues
        let targetSize = CGSize(width: 2048, height: 2048)
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, info in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.hideImageLoadingIndicator()
            }
            
            // Check for errors
            if let error = info?[PHImageErrorKey] as? Error {
                print("❌ PHImageManager error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert(message: "Failed to load image from Photos library")
                }
                return
            }
            
            // Check if image is in iCloud and downloading
            if let isInCloud = info?[PHImageResultIsInCloudKey] as? Bool, isInCloud {
                print("☁️ Image is in iCloud, downloading...")
                // The request will retry automatically with isNetworkAccessAllowed = true
                return
            }
            
            // Check if this is the final image (not a degraded preview)
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            if isDegraded {
                print("⏳ Received degraded preview, waiting for full quality...")
                return
            }
            
            guard let image = image else {
                print("❌ No image returned from PHImageManager")
                DispatchQueue.main.async {
                    self.showAlert(message: "Failed to load image")
                }
                return
            }
            
            print("✅ PHAsset image loaded successfully!")
            print("   Size: \(image.size.width) x \(image.size.height)")
            print("   Scale: \(image.scale)")
            
            DispatchQueue.main.async {
                self.selectedImage = image
                self.imageView.image = image
                print("✅ Image displayed in imageView")
            }
        }
    }
    
    // MARK: - Provider-Based Loading (Fallback for non-library images)
    private func loadImageFromProvider(_ provider: NSItemProvider) {
        print("📷 Loading from provider (screenshots, downloads, etc.)")
        
        guard provider.canLoadObject(ofClass: UIImage.self) else {
            print("❌ Provider cannot load UIImage")
            DispatchQueue.main.async {
                self.hideImageLoadingIndicator()
                self.showAlert(message: "Cannot load this image type")
            }
            return
        }
        
        print("📷 Using loadObject(ofClass: UIImage.self)...")
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.hideImageLoadingIndicator()
            }
            
            if let error = error {
                print("❌ Failed to load image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert(message: "Failed to load image. Please try again.")
                }
                return
            }
            
            guard let image = object as? UIImage else {
                print("❌ Object is not a UIImage")
                DispatchQueue.main.async {
                    self.showAlert(message: "Invalid image format")
                }
                return
            }
            
            guard image.size.width > 0 && image.size.height > 0 else {
                print("❌ Invalid image dimensions")
                DispatchQueue.main.async {
                    self.showAlert(message: "Invalid image size")
                }
                return
            }
            
            print("✅ Provider image loaded successfully!")
            print("   Size: \(image.size.width) x \(image.size.height)")
            
            DispatchQueue.main.async {
                self.selectedImage = image
                self.imageView.image = image
                print("✅ Image displayed in imageView")
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
