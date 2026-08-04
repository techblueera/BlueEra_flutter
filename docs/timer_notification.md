Act as a Senior Flutter Developer.

I am building an eCommerce application similar to Amazon and Flipkart.

Tech Stack
------------
- Flutter (latest stable)
- Firebase Cloud Messaging (FCM)
- flutter_local_notifications
- Android
- iOS

Objective
----------
When an offer notification arrives:

1. Receive FCM notification.
2. Display a beautiful local notification.
3. Notification should contain:
    - Offer Image
    - Product Name
    - Discount %
    - Countdown Timer (60 seconds)
    - "Shop Now" button
    - "Dismiss" button
4. The notification countdown should update every second.
5. If the user taps Shop Now:
    - Open Offer Screen.
6. If timer reaches 0:
    - Automatically remove notification.
7. If app is terminated:
    - Handle FCM correctly.
8. If app is background:
    - Show notification.
9. If app is foreground:
    - Create local notification manually.

Android Requirements
--------------------
- Firebase Messaging
- flutter_local_notifications
- Notification Channel
- High Priority
- Big Picture Style
- Heads-up Notification
- Full source code
- Notification ID management
- Update notification every second
- Deep Linking

iOS Requirements
----------------
- APNs configuration
- Firebase Messaging
- flutter_local_notifications
- Rich Notification Support
- Notification Service Extension
- Download notification image
- Deep Linking
- Foreground notification handling

Backend Payload
----------------
Provide JSON payload examples for:

1. Simple offer

2. Big image offer

3. Flash sale

4. Category offer

5. Timer-based offer

Payload should include:

notificationId
title
body
image
type
offerId
productId
categoryId
discount
expiryTime
deeplink
priority
sound
badge
click_action
mutable_content
content_available

Generate:
- Flutter code
- Android Manifest changes
- Info.plist changes
- Firebase configuration
- APNs configuration
- Notification Service Extension
- Complete folder structure
- Best practices
- Production-ready architecture
