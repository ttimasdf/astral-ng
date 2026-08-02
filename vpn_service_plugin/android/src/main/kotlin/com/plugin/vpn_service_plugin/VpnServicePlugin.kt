package com.plugin.vpn_service_plugin

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel

// VPN服务插件类，实现Flutter插件、方法调用处理和Activity感知接口
class VpnServicePlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    // 方法通道，用于Flutter和原生代码通信
    private lateinit var channel : MethodChannel
    // 事件通道，用于向Flutter发送VPN状态变化事件
    private lateinit var eventChannel: EventChannel
    // Application context is also available to background Flutter engines.
    private lateinit var applicationContext: Context
    // Activity is only required while displaying the initial VPN consent UI.
    private var activity: Activity? = null
    // 事件接收器
    private var eventSink: EventChannel.EventSink? = null

    // 插件附加到Flutter引擎时调用
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "vpn_service")
        channel.setMethodCallHandler(this)
        
        // 初始化事件通道
        eventChannel = EventChannel(binding.binaryMessenger, "vpn_service_events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                // 设置VPN服务的回调函数
                TauriVpnService.triggerCallback = { event, data ->
                    eventSink?.success(mapOf("event" to event, "data" to data))
                }
                NativeLogger.eventCallback = { data ->
                    eventSink?.success(mapOf("event" to "diagnostic", "data" to data))
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                TauriVpnService.triggerCallback = { _, _ -> }
                NativeLogger.eventCallback = {}
            }
        })
    }

    // 处理来自Flutter的方法调用
    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            handleMethodCall(call, result)
        } catch (error: Exception) {
            NativeLogger.error(
                "vpn.plugin.call.failed",
                "VPN plugin method call failed",
                mapOf("method" to call.method),
                error,
            )
            result.error("vpn_native_error", error.message, null)
        }
    }

    private fun handleMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "configureLogging" -> {
                val level = call.argument<String>("minimumLevel") ?: "info"
                NativeLogger.configure(level)
                result.success(null)
            }
            // 准备VPN服务
            "prepareVpn" -> {
                val currentActivity = activity
                val intent = VpnService.prepare(currentActivity ?: applicationContext)
                if (intent != null && currentActivity != null) {
                    // 需要用户授权，启动授权界面
                    currentActivity.startActivityForResult(intent, 0x0f)
                    result.success(mapOf("errorMsg" to "again"))
                } else if (intent != null) {
                    // Background engines cannot display Android's VPN consent UI.
                    result.success(mapOf("errorMsg" to "need_activity"))
                } else {
                    // 已经获得授权
                    result.success(mapOf<String, Any>())
                }
            }
            // 启动VPN服务
            "startVpn" -> {
                val args = call.arguments<Map<String, Any>>()
                val serviceContext = activity ?: applicationContext
                val intent = VpnService.prepare(serviceContext)
                if (intent != null) {
                    // 需要先获取VPN权限
                    result.success(mapOf("errorMsg" to "need_prepare"))
                } else {
                    // 配置并启动VPN服务. Starting an existing service replaces
                    // its TUN without treating the refresh as a revocation.
                    val serviceIntent = Intent(serviceContext, TauriVpnService::class.java)
                    
                    // 处理IPv4地址
                    serviceIntent.putExtra("IPV4_ADDR", args?.get("ipv4Addr") as? String)
                    
                    // 处理路由列表 - 从List<Dynamic>转换为Array<String>
                    val routesList = args?.get("routes") as? List<*>
                    if (routesList != null) {
                        val routesArray = routesList.filterIsInstance<String>().toTypedArray()
                        serviceIntent.putExtra("ROUTES", routesArray)
                    }
                    
                    // 处理DNS
                    serviceIntent.putExtra("DNS", args?.get("dns") as? String)
                    
                    // 处理不允许的应用列表 - 从List<Dynamic>转换为Array<String>
                    val disallowedAppsList = args?.get("disallowedApplications") as? List<*>
                    if (disallowedAppsList != null) {
                        val disallowedAppsArray = disallowedAppsList.filterIsInstance<String>().toTypedArray()
                        serviceIntent.putExtra("DISALLOWED_APPLICATIONS", disallowedAppsArray)
                    }
                    
                    // 处理MTU
                    val mtu = args?.get("mtu")
                    if (mtu is Int) {
                        serviceIntent.putExtra("MTU", mtu)
                    }
                    serviceIntent.putExtra(
                        TauriVpnService.CONNECTION_ATTEMPT_ID,
                        args?.get("connectionAttemptId") as? String,
                    )

                    serviceContext.startService(serviceIntent)
                    result.success(mapOf<String, Any>())
                }
            }
            // 停止VPN服务
            "stopVpn" -> {
                val serviceContext = activity ?: applicationContext
                serviceContext.stopService(Intent(serviceContext, TauriVpnService::class.java))
                result.success(mapOf<String, Any>())
            }
            else -> result.notImplemented()
        }
    }

    // 插件从Flutter引擎分离时调用
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
        TauriVpnService.triggerCallback = { _, _ -> }
        NativeLogger.eventCallback = {}
    }

    // 插件附加到Activity时调用
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    // Activity生命周期相关回调
    override fun onDetachedFromActivity() {
        activity = null
    }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }
    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }
}
