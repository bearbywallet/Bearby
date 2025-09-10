package com.zilpaymobile;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class FlutterHidPlugin implements FlutterPlugin, MethodCallHandler {
    private MethodChannel channel;
    private EventChannel eventChannel;
    private Context context;
    private UsbManager usbManager;
    private final HashMap<String, HIDDevice> hidDevices = new HashMap<>();

    private static final String METHOD_CHANNEL_NAME = "com.ledger.flutter_hid/methods";
    private static final String EVENT_CHANNEL_NAME = "com.ledger.flutter_hid/events";
    private static final String ACTION_USB_PERMISSION = "com.yourcompany.your_flutter_project.USB_PERMISSION";

    private BroadcastReceiver usbReceiver;
    private BroadcastReceiver usbPermissionReceiver;
    private Result pendingOpenResult;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        usbManager = (UsbManager) context.getSystemService(Context.USB_SERVICE);
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), METHOD_CHANNEL_NAME);
        channel.setMethodCallHandler(this);

        eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), EVENT_CHANNEL_NAME);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                registerDeviceConnectionReceiver(events);
            }

            @Override
            public void onCancel(Object arguments) {
                unregisterDeviceConnectionReceiver();
            }
        });
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "listDevices":
                getDeviceList(result);
                break;
            case "openDevice":
                openDevice(call, result);
                break;
            case "exchange":
                exchange(call, result);
                break;
            case "closeDevice":
                closeDevice(call, result);
                break;
            default:
                result.notImplemented();
        }
    }

    private void getDeviceList(Result result) {
        HashMap<String, UsbDevice> usbDevices = usbManager.getDeviceList();
        List<Map<String, Object>> deviceList = new ArrayList<>();
        for (UsbDevice device : usbDevices.values()) {
            deviceList.add(buildMapFromDevice(device));
        }
        result.success(deviceList);
    }

    private void openDevice(MethodCall call, Result result) {
        try {
            Map<String, Integer> deviceMap = (Map<String, Integer>) call.arguments;
            int vendorId = deviceMap.get("vendorId");
            int productId = deviceMap.get("productId");

            UsbDevice deviceToOpen = null;
            for (UsbDevice device : usbManager.getDeviceList().values()) {
                if (device.getVendorId() == vendorId && device.getProductId() == productId) {
                    deviceToOpen = device;
                    break;
                }
            }

            if (deviceToOpen == null) {
                result.error("DeviceNotFound", "Could not find specified device", null);
                return;
            }

            if (usbManager.hasPermission(deviceToOpen)) {
                String id = createHIDDevice(deviceToOpen);
                result.success(id);
            } else {
                pendingOpenResult = result;
                registerPermissionReceiver();
                int flags = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ? PendingIntent.FLAG_IMMUTABLE : 0;
                PendingIntent permIntent = PendingIntent.getBroadcast(context, 0, new Intent(ACTION_USB_PERMISSION), flags);
                usbManager.requestPermission(deviceToOpen, permIntent);
            }
        } catch (Exception e) {
            result.error("OpenDeviceError", e.getMessage(), null);
        }
    }

    private void exchange(MethodCall call, Result result) {
        try {
            String deviceId = call.argument("deviceId");
            String apduHex = call.argument("apdu");
            HIDDevice hid = hidDevices.get(deviceId);
            if (hid == null) {
                throw new Exception(String.format("No device opened for the id '%s'", deviceId));
            }
            hid.exchange(hexToBin(apduHex), result);
        } catch (Exception e) {
            result.error("ExchangeError", e.getMessage(), null);
        }
    }

    private void closeDevice(MethodCall call, Result result) {
        try {
            String deviceId = call.argument("deviceId");
            HIDDevice hid = hidDevices.get(deviceId);
            if (hid == null) {
                throw new Exception(String.format("No device opened for the id '%s'", deviceId));
            }
            hid.close();
            hidDevices.remove(deviceId);
            result.success(null);
        } catch (Exception e) {
            result.error("CloseDeviceError", e.getMessage(), null);
        }
    }

    private void registerPermissionReceiver() {
        if (usbPermissionReceiver != null) return;
        usbPermissionReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if (ACTION_USB_PERMISSION.equals(intent.getAction()) && pendingOpenResult != null) {
                    UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        if (device != null) {
                            try {
                                String id = createHIDDevice(device);
                                pendingOpenResult.success(id);
                            } catch (Exception e) {
                                pendingOpenResult.error("DeviceCreationError", e.getMessage(), null);
                            }
                        }
                    } else {
                        pendingOpenResult.error("PermissionDenied", "Permission denied by user for device", null);
                    }
                    pendingOpenResult = null;
                    unregisterPermissionReceiver();
                }
            }
        };
        // **MODIFIED LINE**
        ContextCompat.registerReceiver(context, usbPermissionReceiver, new IntentFilter(ACTION_USB_PERMISSION), ContextCompat.RECEIVER_NOT_EXPORTED);
    }

    private void unregisterPermissionReceiver() {
        if (usbPermissionReceiver != null) {
            context.unregisterReceiver(usbPermissionReceiver);
            usbPermissionReceiver = null;
        }
    }

    private void registerDeviceConnectionReceiver(final EventChannel.EventSink events) {
        if (usbReceiver != null) return;

        usbReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                if (device != null) {
                    Map<String, Object> eventMap = new HashMap<>();
                    eventMap.put("descriptor", buildMapFromDevice(device));
                    if (UsbManager.ACTION_USB_DEVICE_ATTACHED.equals(action)) {
                        eventMap.put("type", "add");
                        events.success(eventMap);
                    } else if (UsbManager.ACTION_USB_DEVICE_DETACHED.equals(action)) {
                        eventMap.put("type", "remove");
                        events.success(eventMap);
                    }
                }
            }
        };

        // **MODIFIED LINES**
        IntentFilter filter = new IntentFilter();
        filter.addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED);
        filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED);
        ContextCompat.registerReceiver(context, usbReceiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED);
    }

    private void unregisterDeviceConnectionReceiver() {
        if (usbReceiver != null) {
            context.unregisterReceiver(usbReceiver);
            usbReceiver = null;
        }
    }

    private String createHIDDevice(UsbDevice device) {
        HIDDevice hid = new HIDDevice(usbManager, device);
        String id = UUID.randomUUID().toString();
        hidDevices.put(id, hid);
        return id;
    }

    private Map<String, Object> buildMapFromDevice(UsbDevice device) {
        Map<String, Object> map = new HashMap<>();
        map.put("name", device.getDeviceName());
        map.put("deviceId", device.getDeviceId());
        map.put("productId", device.getProductId());
        map.put("vendorId", device.getVendorId());
        return map;
    }

    private byte[] hexToBin(String src) {
        ByteArrayOutputStream result = new ByteArrayOutputStream();
        int i = 0;
        while (i < src.length()) {
            try {
                result.write(Integer.parseInt(src.substring(i, i + 2), 16));
                i += 2;
            } catch (Exception e) {
                return null;
            }
        }
        return result.toByteArray();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        eventChannel.setStreamHandler(null);
        unregisterDeviceConnectionReceiver();
        unregisterPermissionReceiver();
        for (HIDDevice hid : hidDevices.values()) {
            hid.close();
        }
        hidDevices.clear();
    }
}