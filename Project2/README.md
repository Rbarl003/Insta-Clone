# Project 2 - Instagram-like Parse App

## Setup Instructions

### 1. Install ParseSwift via Swift Package Manager

1. In Xcode, g5 to **File > Add Package Dependencies...**
2. Enter the ParseSwift repository URL: `https://github.com/parse-community/Parse-Swift`
3. Select the latest version and click **Add Package**
4. Make sure ParseSwift is added to your target

### 2. Configure Back4App Credentials

Open `AppDelegate.swift` and replace the placeholder values with your Back4App credentials:

```swift
ParseSwift.initialize(
    applicationId: "YOUR_APP_ID_HERE",        // Replace with your App ID
    clientKey: "YOUR_CLIENT_KEY_HERE",        // Replace with your Client Key
    serverURL: URL(string: "https://parseapi.back4app.com")!
)
```

You can find these credentials in your Back4App dashboard:
- Go to https://www.back4app.com/
- Select your app
- Go to **App Settings > Security & Keys**
- Copy the **Application ID** and **Client Key**

### 3. Configure Info.plist for Photo Access

Add the following privacy descriptions to your `Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to upload images</string>
```

### 4. Project Structure

The project includes the following files:

- **AppDelegate.swift** - Parse initialization
- **SceneDelegate.swift** - Root view controller management (login vs feed)
- **User.swift** - Parse User model
- **Post.swift** - Parse Post model
- **LoginViewController.swift** - Login and signup screen
- **FeedViewController.swift** - Main feed with infinite scroll
- **CreatePostViewController.swift** - Create new posts with images
- **PostCell.swift** - Custom table view cell (embedded in FeedViewController)

### 5. Features Implemented

✅ **User Authentication**
- Sign up new users
- Log in existing users
- Log out
- Persist login session

✅ **Posts Feed**
- Display posts in a table view
- Infinite scroll pagination (loads 10 posts at a time)
- Pull to refresh
- Show username, image, caption, and relative timestamp

✅ **Create Posts**
- Select images from photo library
- Add captions
- Upload to Parse

### 6. Key Parse Concepts Used

**Querying Posts:**
```swift
var query = Post.query()
    .include("user")  // Include user data
    .order([.descending("createdAt")])  // Sort by newest
    .limit(10)  // Pagination
    .skip(page * 10)

let posts = try await query.find()
```

**Creating a Post:**
```swift
var post = Post()
post.caption = "My caption"
post.imageFile = ParseFile(name: "photo.jpg", data: imageData)
post.user = User.current

try await post.save()
```

**User Signup:**
```swift
var user = User()
user.username = "username"
user.password = "password"
try await user.signup()
```

**User Login:**
```swift
try await User.login(username: "username", password: "password")
```

**User Logout:**
```swift
try await User.logout()
```

### 7. Running the App

1. Make sure you've added your Back4App credentials
2. Build and run the app
3. You'll see the login screen
4. Create a new account or login
5. View the feed (will be empty initially)
6. Tap the compose button to create a post
7. Select an image and add a caption
8. Posts will appear in the feed

### 8. Back4App Dashboard

You can view your data in the Back4App dashboard:
- Go to **Database > Browser**
- You'll see tables for `User` and `Post`
- Click on each to view the stored data

## Customization

Feel free to extend the models with additional properties:

**User.swift:**
```swift
var displayName: String?
var profileImageFile: ParseFile?
var bio: String?
```

**Post.swift:**
```swift
var likesCount: Int?
var commentsCount: Int?
var location: String?
```

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+
- ParseSwift package

## Troubleshooting

**Issue: "Cannot find type 'ParseSwift'"**
- Make sure you've added the ParseSwift package via SPM

**Issue: "Request failed: unauthorized"**
- Check your App ID and Client Key are correct

**Issue: Photo picker doesn't appear**
- Make sure you've added NSPhotoLibraryUsageDescription to Info.plist

**Issue: App crashes on launch**
- Check that Parse is initialized before any Parse operations
- Verify your serverURL is correct


## Video Walkthrough

Watch a short video walkthrough of the project here:

https://www.loom.com/share/f317044221454a509f3ebc14289bc9e0

