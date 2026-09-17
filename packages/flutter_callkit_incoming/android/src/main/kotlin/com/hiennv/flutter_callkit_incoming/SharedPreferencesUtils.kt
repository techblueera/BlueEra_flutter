package com.hiennv.flutter_callkit_incoming

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.fasterxml.jackson.core.type.TypeReference


private const val CALLKIT_PREFERENCES_FILE_NAME = "flutter_callkit_incoming"
private const val ACTIVE_CALLS_KEY = "ACTIVE_CALLS"
private const val NO_ACTIVE_CALLS_JSON = "[]"
private var prefs: SharedPreferences? = null
private var editor: SharedPreferences.Editor? = null

/**
 * The stored ACTIVE_CALLS json, never null.
 *
 * [getString] returns null whenever the plugin has no Context, and it does not
 * always have one: FlutterCallkitIncomingPlugin clears its reference in
 * onDetachedFromActivity, while the method channel stays live and can still be
 * called — `activeCalls` from a screen's initState is enough to hit that gap.
 * Jackson then refuses the null with `IllegalArgumentException: argument
 * "content" is null`, which the plugin's catch-all hands to Dart as
 * `PlatformException(error, argument "content" is null, , null)`.
 *
 * Having no context to read through means we cannot see any calls, which for
 * every caller here means the same thing as there being none.
 */
private fun getActiveCallsJson(context: Context?): String {
    val json = getString(context, ACTIVE_CALLS_KEY, NO_ACTIVE_CALLS_JSON)
    return if (json.isNullOrBlank()) NO_ACTIVE_CALLS_JSON else json
}

private fun initInstance(context: Context) {
    prefs = context.getSharedPreferences(CALLKIT_PREFERENCES_FILE_NAME, Context.MODE_PRIVATE)
    editor = prefs?.edit()
}


fun addCall(context: Context?, data: Data, isAccepted: Boolean = false) {
    val json = getActiveCallsJson(context)
    val arrayData: ArrayList<Data> = Utils.getGsonInstance()
        .readValue(json, object : TypeReference<ArrayList<Data>>() {})
    val currentData = arrayData.find { it == data }
    if(currentData != null) {
        currentData.isAccepted = isAccepted
    }else {
        data.isAccepted = isAccepted
        arrayData.add(data)
    }
    putString(context, ACTIVE_CALLS_KEY, Utils.getGsonInstance().writeValueAsString(arrayData))
}

fun removeCall(context: Context?, data: Data) {
    val json = getActiveCallsJson(context)
    Log.d("JSON", json)
    val arrayData: ArrayList<Data> = Utils.getGsonInstance()
        .readValue(json, object : TypeReference<ArrayList<Data>>() {})
    arrayData.remove(data)
    putString(context, ACTIVE_CALLS_KEY, Utils.getGsonInstance().writeValueAsString(arrayData))
}

fun removeAllCalls(context: Context?) {
    putString(context, ACTIVE_CALLS_KEY, NO_ACTIVE_CALLS_JSON)
    remove(context, ACTIVE_CALLS_KEY)
}

fun getDataActiveCalls(context: Context?): ArrayList<Data> {
    val json = getActiveCallsJson(context)
    return Utils.getGsonInstance()
        .readValue(json, object : TypeReference<ArrayList<Data>>() {})
}

fun getDataActiveCallsForFlutter(context: Context?): ArrayList<Map<String, Any?>> {
    val json = getActiveCallsJson(context)
    return Utils.getGsonInstance().readValue(json, object : TypeReference<ArrayList<Map<String, Any?>>>() {})
}

fun putString(context: Context?, key: String, value: String?) {
    if (context == null) return
    initInstance(context)
    editor?.putString(key, value)
    editor?.commit()
}

fun getString(context: Context?, key: String, defaultValue: String = ""): String? {
    if (context == null) return null
    initInstance(context)
    return prefs?.getString(key, defaultValue)
}

fun remove(context: Context?, key: String) {
    if (context == null) return
    initInstance(context)
    editor?.remove(key)
    editor?.commit()
}
