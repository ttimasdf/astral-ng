package pw.rabit.enmesh

import android.content.SharedPreferences

fun SharedPreferences.widgetString(key: String, default: String = ""): String =
    getString(key, default) ?: default
