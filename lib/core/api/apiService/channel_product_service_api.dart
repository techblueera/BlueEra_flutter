/// All `channel-product-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin ChannelProductServiceApi {
  final String products = 'channel-product-service/products';
  String channelProducts(String channelId) =>
      "channel-product-service/products/channel/$channelId";
  String product(String productId) =>
      "channel-product-service/products/$productId";
}
