package com.plugin.vpn_service_plugin

import android.util.Log
import java.util.ArrayDeque
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

enum class NativeLogLevel(val priority: Int, val wireName: String, val token: String) {
    TRACE(Log.VERBOSE, "trace", "TRC"),
    DEBUG(Log.DEBUG, "debug", "DBG"),
    INFO(Log.INFO, "info", "INF"),
    WARNING(Log.WARN, "warning", "WRN"),
    ERROR(Log.ERROR, "error", "ERR"),
    FATAL(Log.ASSERT, "fatal", "FTL"),
}

object NativeLogger {
    private const val TAG = "Astral"
    private const val MODULE = "astral.vpn.android"
    private const val MAX_VALUE_LENGTH = 1024
    private const val MAX_PENDING_EVENTS = 256
    private val minimumPriority = AtomicInteger(NativeLogLevel.INFO.priority)
    private val sourceSequence = AtomicLong(0)
    private val callbackLock = Any()
    private val pendingEvents = ArrayDeque<Map<String, Any?>>()
    private var eventCallback: ((Map<String, Any?>) -> Unit)? = null
    private var droppedPendingEvents = 0

    fun attachEventCallback(callback: (Map<String, Any?>) -> Unit) {
        val buffered = synchronized(callbackLock) {
            eventCallback = callback
            buildList {
                if (droppedPendingEvents > 0) {
                    add(pendingSuppressionEvent(droppedPendingEvents))
                    droppedPendingEvents = 0
                }
                while (pendingEvents.isNotEmpty()) add(pendingEvents.removeFirst())
            }
        }
        buffered.forEach { deliver(callback, it) }
    }

    fun detachEventCallback() {
        synchronized(callbackLock) {
            eventCallback = null
        }
    }

    fun configure(minimumLevel: String) {
        val level = NativeLogLevel.entries.firstOrNull {
            it.wireName.equals(minimumLevel, ignoreCase = true)
        } ?: NativeLogLevel.INFO
        minimumPriority.set(level.priority)
        info(
            "vpn.logging.configured",
            "Native VPN logging configured",
            mapOf("minimum_level" to level.wireName),
        )
    }

    fun debug(eventCode: String, message: String, fields: Map<String, Any?> = emptyMap()) =
        emit(NativeLogLevel.DEBUG, eventCode, message, fields)

    fun info(eventCode: String, message: String, fields: Map<String, Any?> = emptyMap()) =
        emit(NativeLogLevel.INFO, eventCode, message, fields)

    fun warning(
        eventCode: String,
        message: String,
        fields: Map<String, Any?> = emptyMap(),
        error: Throwable? = null,
    ) = emit(NativeLogLevel.WARNING, eventCode, message, fields, error)

    fun error(
        eventCode: String,
        message: String,
        fields: Map<String, Any?> = emptyMap(),
        error: Throwable? = null,
    ) = emit(NativeLogLevel.ERROR, eventCode, message, fields, error)

    private fun emit(
        level: NativeLogLevel,
        eventCode: String,
        message: String,
        fields: Map<String, Any?>,
        error: Throwable? = null,
    ) {
        if (level.priority < minimumPriority.get() && level.priority < Log.ERROR) return
        val safeFields = sanitize(fields)
        val fieldText = safeFields.entries
            .sortedBy { it.key }
            .joinToString(" ") { "${it.key}=${it.value}" }
        val suffix = if (fieldText.isEmpty()) "" else " | $fieldText"
        val body = "${level.token} vpn.android        ${eventCode.padEnd(24)} $message$suffix"
        if (error == null) {
            Log.println(level.priority, TAG, body)
        } else {
            Log.println(level.priority, TAG, "$body\n${Log.getStackTraceString(error)}")
        }

        val event = mutableMapOf<String, Any?>(
            "timestampMillis" to System.currentTimeMillis(),
            "sourceSequence" to sourceSequence.getAndIncrement(),
            "level" to level.wireName,
            "module" to MODULE,
            "eventCode" to eventCode.take(128),
            "message" to message.take(4096),
            "fields" to safeFields,
            "consoleAlreadyReported" to true,
        )
        if (error != null) {
            event["errorType"] = error.javaClass.simpleName
            event["errorMessage"] = error.message?.take(4096) ?: error.toString().take(4096)
            event["stackTrace"] = Log.getStackTraceString(error).take(32768)
        }
        forward(event)
    }

    private fun forward(event: Map<String, Any?>) {
        val callback = synchronized(callbackLock) {
            val current = eventCallback
            if (current == null) bufferLocked(event)
            current
        } ?: return
        deliver(callback, event)
    }

    private fun deliver(
        callback: (Map<String, Any?>) -> Unit,
        event: Map<String, Any?>,
    ) {
        try {
            callback(event)
        } catch (callbackError: Exception) {
            synchronized(callbackLock) {
                if (eventCallback === callback) eventCallback = null
                bufferLocked(event)
            }
            Log.w(TAG, "Native diagnostic forwarding failed", callbackError)
        }
    }

    private fun bufferLocked(event: Map<String, Any?>) {
        if (pendingEvents.size >= MAX_PENDING_EVENTS) {
            pendingEvents.removeFirst()
            droppedPendingEvents++
        }
        pendingEvents.addLast(event)
    }

    private fun pendingSuppressionEvent(count: Int): Map<String, Any?> = mapOf(
        "timestampMillis" to System.currentTimeMillis(),
        "sourceSequence" to sourceSequence.getAndIncrement(),
        "level" to NativeLogLevel.WARNING.wireName,
        "module" to MODULE,
        "eventCode" to "logging.records.suppressed",
        "message" to "Android diagnostic bridge suppressed records",
        "fields" to mapOf("reason" to "pre_attach_overflow", "count" to count),
        "consoleAlreadyReported" to false,
    )

    private fun sanitize(fields: Map<String, Any?>): Map<String, Any?> = fields.mapValues {
        (key, value) ->
        if (isSensitive(key)) {
            "<redacted>"
        } else {
            when (value) {
                null, is Boolean, is Number -> value
                else -> value.toString().take(MAX_VALUE_LENGTH)
            }
        }
    }

    private fun isSensitive(key: String): Boolean {
        val normalized = key.lowercase().replace('-', '_')
        return listOf(
            "password",
            "token",
            "authorization",
            "cookie",
            "private_key",
            "secret",
            "credential",
        ).any(normalized::contains)
    }
}
