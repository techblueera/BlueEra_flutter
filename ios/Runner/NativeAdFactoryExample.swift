import Foundation
import google_mobile_ads

class NativeAdFactoryExample: NSObject, FLTNativeAdFactory {
  func createNativeAd(_ nativeAd: GADNativeAd, customOptions: [AnyHashable : Any]? = nil) -> GADNativeAdView? {
    
    // Load the view from NativeAdView.xib
    guard let adView = Bundle.main.loadNibNamed("NativeAdView", owner: nil, options: nil)?.first as? GADNativeAdView else {
      return nil
    }
    
    // Headline (always present)
    (adView.headlineView as? UILabel)?.text = nativeAd.headline
    
    // Body
    (adView.bodyView as? UILabel)?.text = nativeAd.body
    adView.bodyView?.isHidden = nativeAd.body == nil
    
    // Call to Action
    if let button = adView.callToActionView as? UIButton {
      button.setTitle(nativeAd.callToAction, for: .normal)
    }
    adView.callToActionView?.isHidden = nativeAd.callToAction == nil
    
    // Icon
    (adView.iconView as? UIImageView)?.image = nativeAd.icon?.image
    adView.iconView?.isHidden = nativeAd.icon == nil
    
    // Store
    (adView.storeView as? UILabel)?.text = nativeAd.store
    adView.storeView?.isHidden = nativeAd.store == nil
    
    // Price
    (adView.priceView as? UILabel)?.text = nativeAd.price
    adView.priceView?.isHidden = nativeAd.price == nil
    
    // Advertiser
    (adView.advertiserView as? UILabel)?.text = nativeAd.advertiser
    adView.advertiserView?.isHidden = nativeAd.advertiser == nil
    
    // Disable user interaction for CTA (Google’s requirement)
    adView.callToActionView?.isUserInteractionEnabled = false
    
    // Bind ad
    adView.nativeAd = nativeAd
    
    return adView
  }
}

