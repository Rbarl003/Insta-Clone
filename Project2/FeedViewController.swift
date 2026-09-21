//
//  FeedViewController.swift
//  Project2
//
//  Created by Ritch Barlatier on 9/20/26.
//

import UIKit
import ParseSwift

// Notification used when a new post is created successfully
extension Notification.Name {
    static let didCreatePost = Notification.Name("didCreatePost")
}

// MARK: - Image Cache
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        cache.countLimit = 100 // Store up to 100 images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    func image(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
    
    func setImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

class FeedViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView()
    private var posts: [Post] = []
    private var isLoading = false
    private var currentPage = 0
    private let postsPerPage = 10
    
    private let refreshControl = UIRefreshControl()
    
    private let footerLoadingIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.frame = CGRect(x: 0, y: 0, width: 0, height: 60)
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Listen for new posts being created so we can refresh exactly when they are saved
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidCreatePost(_:)), name: .didCreatePost, object: nil)
        loadPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh feed when returning from create post screen
        // Always refresh to show new posts
        loadPosts(refresh: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .didCreatePost, object: nil)
    }

    @objc private func handleDidCreatePost(_ notification: Notification) {
        // A post was created elsewhere in the app - refresh to include it
        print("📢 FeedViewController received didCreatePost notification!")
        if let post = notification.object as? Post {
            print("   New post ID: \(post.objectId ?? "unknown")")
            print("   Location: \(post.locationName ?? "none")")
        }
        print("🔄 Refreshing feed to show new post...")
        loadPosts(refresh: true)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Feed"
        
        // Setup logout button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
        
        // Setup compose button with camera icon
        let cameraButton = UIBarButtonItem(
            image: UIImage(systemName: "camera.fill"),
            style: .plain,
            target: self,
            action: #selector(composeTapped)
        )
        navigationItem.leftBarButtonItem = cameraButton
        
        // Setup table view
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PostCell.self, forCellReuseIdentifier: "PostCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 400
        
        // Setup refresh control
        refreshControl.addTarget(self, action: #selector(refreshPosts), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // Setup footer loading indicator
        tableView.tableFooterView = footerLoadingIndicator
    }
    
    // MARK: - Data Loading
    private func loadPosts(refresh: Bool = false) {
        guard !isLoading else { return }
        
        if refresh {
            currentPage = 0
        }
        
        isLoading = true
        footerLoadingIndicator.startAnimating()
        
        Task {
            do {
                print("🔄 Loading posts (refresh: \(refresh), page: \(currentPage))...")
                
                // Query posts, sorted by newest first
                let query = Post.query()
                    .include(["user", "imageFile"])  // Include related objects
                    .order([.descending("createdAt")])
                    .limit(postsPerPage)
                    .skip(currentPage * postsPerPage)
                
                // ParseSwift queries always fetch from server by default
                // No need for explicit cache policy
                let fetchedPosts = try await query.find()
                print("✅ Loaded \(fetchedPosts.count) posts from server")
                
                await MainActor.run {
                    if refresh {
                        self.posts = fetchedPosts
                    } else {
                        self.posts.append(contentsOf: fetchedPosts)
                    }
                    
                    self.currentPage += 1
                    self.isLoading = false
                    self.footerLoadingIndicator.stopAnimating()
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                await MainActor.run {
                    print("Error loading posts: \(error.localizedDescription)")
                    self.isLoading = false
                    self.footerLoadingIndicator.stopAnimating()
                    self.refreshControl.endRefreshing()
                    self.showAlert(message: "Failed to load posts: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func refreshPosts() {
        loadPosts(refresh: true)
    }
    
    @objc private func composeTapped() {
        let createPostVC = CreatePostViewController()
        let navController = UINavigationController(rootViewController: createPostVC)
        present(navController, animated: true)
    }
    
    @objc private func logoutTapped() {
        Task {
            do {
                try await User.logout()
                
                await MainActor.run {
                    navigateToLogin()
                }
            } catch {
                await MainActor.run {
                    showAlert(message: "Logout failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Navigation
    private func navigateToLogin() {
        let loginVC = LoginViewController()
        let navController = UINavigationController(rootViewController: loginVC)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = navController
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        }
    }
    
    // MARK: - Helper
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        cell.configure(with: posts[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FeedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Trigger infinite scroll when reaching the last few cells
        let threshold = posts.count - 3
        if indexPath.row >= threshold {
            loadPosts()
        }
    }
}

// MARK: - PostCell
class PostCell: UITableViewCell {
    
    // Track current image URL to prevent re-downloading
    private var currentImageURL: URL?
    private var imageLoadTask: Task<Void, Never>?
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Cancel any ongoing image load
        imageLoadTask?.cancel()
        imageLoadTask = nil
        currentImageURL = nil
        postImageView.image = nil
    }
    
    private func setupUI() {
        contentView.addSubview(usernameLabel)
        contentView.addSubview(postImageView)
        contentView.addSubview(captionLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(locationLabel)
        
        NSLayoutConstraint.activate([
            usernameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            usernameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            postImageView.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            postImageView.heightAnchor.constraint(equalToConstant: 300),
            
            captionLabel.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 12),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            captionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            dateLabel.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            locationLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            locationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with post: Post) {
        // Set username
        usernameLabel.text = post.user?.username ?? "Unknown"
        
        // Set caption
        if let caption = post.caption, !caption.isEmpty {
            captionLabel.text = caption
            captionLabel.isHidden = false
        } else {
            captionLabel.text = ""
            captionLabel.isHidden = true
        }
        
        // Debug: Log post data
        print("🔍 Configuring post \(post.objectId ?? "unknown"):")
        print("   Username: \(post.user?.username ?? "none")")
        print("   Caption: \(post.caption ?? "none")")
        print("   Location Name: \(post.locationName ?? "none")")
        print("   Created At: \(post.createdAt?.description ?? "none")")
        print("   Image File URL: \(post.imageFile?.url?.absoluteString ?? "none")")
        
        // Show date - this should ALWAYS show since createdAt is set by Parse
        if let createdAt = post.createdAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            let timeString = formatter.localizedString(for: createdAt, relativeTo: Date())
            dateLabel.text = timeString
            dateLabel.isHidden = false
            print("   ⏰ Showing time: \(timeString)")
        } else {
            dateLabel.text = "Just now"
            dateLabel.isHidden = false
            print("   ⏰ No createdAt, showing 'Just now'")
        }
        
        // Show location if available
        if let locationName = post.locationName, !locationName.isEmpty {
            locationLabel.text = "📍 \(locationName)"
            locationLabel.isHidden = false
            print("   📍 Showing location: \(locationName)")
        } else {
            locationLabel.text = ""
            locationLabel.isHidden = true
            print("   📍 No location data")
        }
        
        // Load image if available
        if let imageFile = post.imageFile, let url = imageFile.url {
            // Check cache first
            if let cachedImage = ImageCache.shared.image(for: url) {
                print("✅ Image loaded from cache for URL: \(url)")
                postImageView.image = cachedImage
                return
            }
            
            // Not in cache, download it
            // Cancel previous task if any
            imageLoadTask?.cancel()
            
            // Only download if this is a new URL
            if currentImageURL != url {
                currentImageURL = url
                
                imageLoadTask = Task {
                    do {
                        print("📥 Downloading image from URL: \(url)")
                        let (data, _) = try await URLSession.shared.data(from: url)
                        
                        // Check if task was cancelled
                        guard !Task.isCancelled else {
                            print("⏹ Image download cancelled")
                            return
                        }
                        
                        if let image = UIImage(data: data) {
                            // Cache the image
                            ImageCache.shared.setImage(image, for: url)
                            
                            await MainActor.run {
                                // Double-check we're still showing the same post
                                if self.currentImageURL == url {
                                    self.postImageView.image = image
                                    print("✅ Image loaded and displayed")
                                }
                            }
                        } else {
                            print("❌ Failed to create UIImage from data")
                        }
                    } catch {
                        // Only log if not cancelled
                        if !Task.isCancelled {
                            print("❌ Error downloading image: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } else {
            print("❌ No imageFile URL in post")
        }
    }
}
