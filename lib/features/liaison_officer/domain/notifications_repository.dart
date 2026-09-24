/// In-app notification feed (`/app/notifications/mine*`).
///
/// Items are plain maps matching CAP [NotificationDto] fields:
/// `id`, `title`, `message`, `kind`, `link`, `isRead`, `createdAt`, `readAt`.
abstract class NotificationsRepository {
  /// Latest notifications for the caller (CAP returns up to ~50).
  Future<List<Map<String, dynamic>>> listMine();

  /// Mark a single notification as read.
  Future<void> markRead(String id);

  /// Mark every unread notification as read.
  Future<void> markAllRead();

  /// Unread count for badge UI (`data` may be `{ "count": n }` or a number).
  Future<int> unreadCount();
}
