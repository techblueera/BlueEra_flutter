/// All `contact-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// NOTE: this is separate from `chat-service/connections/*` (see
/// `ChatServiceApi`). Both exist on purpose — the chat-service sync powers the
/// Connect tab's connections + invite list, this one powers "Contacts on
/// BlueEra" and the "your contact joined" push notification.
///
/// The doubled `api` is correct (matches `food-service/api/orders/...`): the
/// first belongs to the gateway, the second to the service's own route mount.
mixin ContactServiceApi {
  final String contactsSync = 'contact-service/api/contacts/sync';

  /// GET = paginated phonebook, DELETE = withdraw consent (all or by phone).
  final String contactsList = 'contact-service/api/contacts';
  final String contactsOnBlueEra = 'contact-service/api/contacts/on-blueera';
  final String contactsSyncState = 'contact-service/api/contacts/sync-state';
  final String contactsRebuild = 'contact-service/api/contacts/rebuild';
}
