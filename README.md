# Project 2 - *Instagram Clone*

Submitted by: **Ritch Barlatier**

**Instagram Clone** is an app that allows users to create accounts, share photos with captions, and view a feed of posts from all users. Built with Parse backend integration for user authentication and data persistence.

Time spent: **5** hours spent in total

## Required Features

The following **required** functionality is completed:

- [x] Users see an app icon in the home screen and a styled launch screen.
- [x] User can register a new account
- [x] User can log in with newly created account
- [x] App has a feed of posts when user logs in
- [x] User can upload a new post which takes in a picture from photo library and an optional caption    
- [x] User is able to logout    
 
The following **optional** features are implemented:

- [x] Users can pull to refresh their feed and see a loading indicator
- [x] Users can infinite-scroll in their feed to see past the 10 most recent photos
- [ ] Users can see location and time of photo upload in the feed    
- [x] User stays logged in when app is closed and open again    


The following **additional** features are implemented:

- [x] Async/await implementation for all Parse operations
- [x] Modern Swift concurrency throughout the app
- [x] Relative timestamps (e.g., "2 hours ago", "1 day ago")
- [x] Responsive UI with activity indicators during loading
- [x] Error handling with user-friendly alerts
- [x] Image compression for efficient uploads
- [x] Automatic HEIC to JPEG conversion

## Video Walkthrough

Link: https://www.loom.com/share/f317044221454a509f3ebc14289bc9e0

## Notes

Challenges encountered while building the app:

- Implementing infinite scroll with Parse pagination required careful state management to avoid duplicate posts
- Converting async/await Parse operations while maintaining smooth UI updates
- Handling photo library permissions and converting HEIC images to JPEG format
- Managing session persistence to keep users logged in across app launches
- Implementing pull-to-refresh without interfering with infinite scroll behavior

## License

    Copyright 2026 Ritch Barlatier

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
# Insta-Clone
