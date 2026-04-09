# 🚀 Notification Events - Quick Reference

## ⚡ Event Publishing Code Template

```javascript
const event = {
  operation: "EVENT_NAME",
  sender_user: "user_id_string", // The ID of the user who triggered the event
  receiver_users: ["recipient_id_1", "recipient_id_2"], // An array of user IDs
  type: ["push_notification", "notification"], // MANDATORY: Array of desired delivery channels
  data: { title: "Title", message: "Message", /* event-specific fields */ },
  timestamp: new Date().toISOString()
};

// Publish to Kafka topic: 'notification.service'
await producer.send({
  topic: 'notification.service',
  messages: [{ value: JSON.stringify(event) }]
});
```

## 📋 Event Operations

| Operation | Key Fields in `data` | Use Case |
|---|---|---|
| `RIDE_ORDER_CREATED` | `orderId`, `title`, `message` | Customer creates a new ride request. |
| `RIDE_ORDER_ACCEPTED` | `orderId`, `riderId`, `title`, `message` | Rider accepts a ride request. |
| `RIDE_ORDER_REJECTED` | `orderId`, `riderId`, `title`, `message` | Rider rejects a ride request. |
| `RIDE_ORDER_CANCELLED` | `orderId`, `title`, `message` | Ride order is cancelled. |
| `RIDE_PAYMENT_CONFIRMED` | `orderId`, `title`, `message` | Customer's payment for ride is confirmed. |
| `RIDE_ORDER_PICKED_UP` | `orderId`, `title`, `message` | Rider picks up the package. |
| `RIDE_ORDER_COMPLETED` | `orderId`, `title`, `message` | Rider delivers the package. |
| `RIDER_ONBOARDING_COMPLETE` | `title`, `message` | Rider finishes onboarding process. |
| `SENT_CONNECTION_REQUEST` | `senderName`, `title`, `message` | User sends a connection request. |
| `RECEIVED_CONNECTION_REQUEST` | `senderName`, `title`, `message` | User receives a connection request. |
| `ACCEPTED_CONNECTION_REQUEST` | `senderName`, `title`, `message` | User accepts a connection request. |
| `CREATED_POST` | `senderName`, `title`, `message` | User creates a new post. |
| `LIKED_POST` | `senderName`, `title`, `message` | User likes another user's post. |
| `COMMENTED_ON_POST` | `senderName`, `title`, `message` | User comments on another user's post. |
| `REPOSTED_POST` | `senderName`, `title`, `message` | User reposts another user's post. |
| `LIKED_REEL` | `senderName`, `title`, `message` | User likes another user's reel. |
| `COMMENTED_ON_REEL` | `senderName`, `title`, `message` | User comments on another user's reel. |
| `REPOSTED_REEL` | `senderName`, `title`, `message` | User reposts another user's reel. |
| `TAGGED_IN_REEL` | `senderName`, `title`, `message` | User is tagged in a reel. |
| `SENT_MESSAGE` | `senderName`, `title`, `message` | User sends a direct message. |
| `COMMENTED_ON_MESSAGE` | `senderName`, `title`, `message` | User comments on a message. |
| `LIKED_MESSAGE` | `senderName`, `title`, `message` | User likes a message. |
| `REPORTED_POST` | `senderName`, `title`, `message` | User reports a post. |
| `REPORTED_REEL` | `senderName`, `title`, `message` | User reports a reel. |
| `REPORTED_MESSAGE` | `senderName`, `title`, `message` | User reports a message. |
| `TAGGED_IN_POST` | `senderName`, `title`, `message` | User is tagged in a post. |
| `APPLIED_TO_JOB` | `senderName`, `title`, `message` | User applies for a job. |
| `ANSWERED_QUESTION` | `senderName`, `title`, `message` | User answers a question. |
| `REPLIED_ON_COMMENT` | `senderName`, `title`, `message` | User replies to a comment. |
| `REACTED_ON_COMMENT` | `senderName`, `title`, `message` | User reacts to a comment. |
| `REACTED_ON_RESPONSE` | `senderName`, `title`, `message` | User reacts to a response. |
| `REACTED_ON_REEL_COMMENT` | `senderName`, `title`, `message` | User reacts to a reel comment. |
| `SHARED_REEL` | `senderName`, `title`, `message` | User shares a reel. |
| `FOLLOWED_PROFILE` | `senderName`, `title`, `message` | User follows a profile. |
| `NOT_INTERESTED_REEL` | `title`, `message` | User marks a reel as not interested. |
| `EXPERIENCE_VERIFICATION` | `senderName`, `companyName`, `title`, `message` | User claims experience, triggers verification. |
| `PROFILE_UPDATED` | `title`, `message` | User's profile is updated. |
| `NEW_USER` | `title`, `message` | New user joins the platform. |
| `ADMIN_BLOCKED_USER` | `title`, `message` | Admin blocks a user's account. |
| `ADMIN_UNBLOCKED_USER` | `title`, `message` | Admin unblocks a user's account. |
| `SUPPORT_TICKET_REPLY` | `title`, `message` | Admin replies to a support ticket. |
| `ADMIN_BULK_NOTIFICATION` | `title`, `message` | General bulk notification from admin. |
| `ADMIN_SYSTEM_ANNOUNCEMENT` | `title`, `message` | System-wide announcement from admin. |
| `ADMIN_URGENT_BROADCAST` | `title`, `message` | Urgent system-wide broadcast from admin. |

## 🎯 Common Field Patterns

### Order-Related Events
```javascript
data: {
  orderId: "ORD-12345",           // Required for most ride lifecycle events
  // ... other order-specific data
}
```

## 📱 Template Keys Reference

**In-App Templates:** `public/in-app-notifications.json`
**Push Templates:** `public/notification-templates.json`

Template key format: `snake_case` (e.g., `ride_order_created`)

## ⚠️ Important Reminders

1. **Always validate** event structure before sending.
2. **Handle errors gracefully** - don't crash on notification failures.
3. **Use user IDs** for sender and receivers; the service will fetch the details.
4. **MANDATORY `type` field**: Always include a `type` array specifying delivery channels (e.g., `["push_notification", "notification"]`).
5. **Include all required fields** - check documentation for each event type.
6. **Test thoroughly** - use the provided test scripts.
7. **Monitor failures** - track notification success rates.

## 📞 Support

- **Event Documentation**: `NOTIFICATION_SERVICE_DOCS.md`
- **Publishing Guide**: `EVENT_PUBLISHING_GUIDE.md`
- **Test Events**: `scripts/test-ride-service-notifications.js`
- **Notification Service Logs**: Check for processing errors.

---
**Last Updated**: November 11, 2025