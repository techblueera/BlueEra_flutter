package ai.bluecs.np

import android.content.Context
import android.view.LayoutInflater
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class ListTileNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val adView = LayoutInflater.from(context).inflate(R.layout.list_tile_native_ad, null) as NativeAdView

        // Headline
        adView.headlineView = adView.findViewById<TextView>(R.id.ad_headline).apply {
            text = nativeAd.headline
        }

        // Icon
        adView.iconView = adView.findViewById<ImageView>(R.id.ad_icon).apply {
            setImageDrawable(nativeAd.icon?.drawable)
        }

        // Body
        adView.bodyView = adView.findViewById<TextView>(R.id.ad_body).apply {
            text = nativeAd.body
        }

        // Media (banner/video)
        adView.mediaView = adView.findViewById<MediaView>(R.id.ad_media).apply {
            setMediaContent(nativeAd.mediaContent)
        }

        // Call to action button
        adView.callToActionView = adView.findViewById<Button>(R.id.ad_call_to_action).apply {
            text = nativeAd.callToAction
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}
