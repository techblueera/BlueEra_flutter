package ai.bluecs.app

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

/**
 * Builds the custom [NativeAdView] for the grocery store list from the
 * `grocery_native_ad.xml` layout. Registered in [MainActivity] under the
 * factory id "groceryAdFactory", referenced from Dart via
 * `NativeAdWidget.factoryId`.
 */
class GroceryNativeAdFactory(private val layoutInflater: LayoutInflater) :
    GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView =
            layoutInflater.inflate(R.layout.grocery_native_ad, null) as NativeAdView

        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val advertiserView = adView.findViewById<TextView>(R.id.ad_advertiser)
        val iconView = adView.findViewById<ImageView>(R.id.ad_icon)
        val ctaView = adView.findViewById<Button>(R.id.ad_call_to_action)
        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)

        // Headline is the only guaranteed asset.
        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        nativeAd.body.let {
            if (it == null) {
                bodyView.visibility = View.GONE
            } else {
                bodyView.visibility = View.VISIBLE
                bodyView.text = it
            }
        }
        adView.bodyView = bodyView

        nativeAd.advertiser.let {
            if (it == null) {
                advertiserView.visibility = View.GONE
            } else {
                advertiserView.visibility = View.VISIBLE
                advertiserView.text = it
            }
        }
        adView.advertiserView = advertiserView

        nativeAd.icon.let {
            if (it == null) {
                iconView.visibility = View.GONE
            } else {
                iconView.visibility = View.VISIBLE
                iconView.setImageDrawable(it.drawable)
            }
        }
        adView.iconView = iconView

        nativeAd.callToAction.let {
            if (it == null) {
                ctaView.visibility = View.INVISIBLE
            } else {
                ctaView.visibility = View.VISIBLE
                ctaView.text = it
            }
        }
        adView.callToActionView = ctaView

        adView.mediaView = mediaView

        // Bind the ad to the view; the SDK wires clicks/impressions.
        adView.setNativeAd(nativeAd)
        return adView
    }
}
