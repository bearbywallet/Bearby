package com.zilpaymobile;

import android.hardware.usb.UsbConstants;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbEndpoint;
import android.hardware.usb.UsbInterface;
import android.hardware.usb.UsbManager;
import android.hardware.usb.UsbRequest;
import android.os.Handler;
import android.os.Looper;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.MethodChannel;

public class HIDDevice {

    private final UsbDeviceConnection connection;
    private final UsbInterface dongleInterface;
    private final UsbEndpoint in;
    private final UsbEndpoint out;
    private final byte[] transferBuffer;
    private final ExecutorService executor;
    private final Handler mainThreadHandler = new Handler(Looper.getMainLooper());


    private static final int HID_BUFFER_SIZE = 64;
    private static final int LEDGER_DEFAULT_CHANNEL = 1;

    public HIDDevice(UsbManager manager, UsbDevice device) throws SecurityException {
        dongleInterface = device.getInterface(0);
        UsbEndpoint endpointIn = null;
        UsbEndpoint endpointOut = null;
        for (int i = 0; i < dongleInterface.getEndpointCount(); i++) {
            UsbEndpoint tmpEndpoint = dongleInterface.getEndpoint(i);
            if (tmpEndpoint.getDirection() == UsbConstants.USB_DIR_IN) {
                endpointIn = tmpEndpoint;
            } else {
                endpointOut = tmpEndpoint;
            }
        }
        in = endpointIn;
        out = endpointOut;
        connection = manager.openDevice(device);
        connection.claimInterface(dongleInterface, true);
        transferBuffer = new byte[HID_BUFFER_SIZE];
        executor = Executors.newSingleThreadExecutor();
    }

    public void exchange(final byte[] commandSource, final MethodChannel.Result result) {
        Runnable exchangeRunnable = () -> {
            try {
                ByteArrayOutputStream response = new ByteArrayOutputStream();
                byte[] responseData;
                int offset = 0;
                byte[] command = LedgerHelper.wrapCommandAPDU(LEDGER_DEFAULT_CHANNEL, commandSource, HID_BUFFER_SIZE);

                UsbRequest requestOut = new UsbRequest();
                if (!requestOut.initialize(connection, out)) {
                    throw new Exception("I/O error on requestOut initialize");
                }
                while (offset != command.length) {
                    int blockSize = Math.min(command.length - offset, HID_BUFFER_SIZE);
                    System.arraycopy(command, offset, transferBuffer, 0, blockSize);
                    if (!requestOut.queue(ByteBuffer.wrap(transferBuffer), HID_BUFFER_SIZE)) {
                        requestOut.close();
                        throw new Exception("I/O error on requestOut queue");
                    }
                    connection.requestWait();
                    offset += blockSize;
                }
                requestOut.close();

                ByteBuffer responseBuffer = ByteBuffer.allocate(HID_BUFFER_SIZE);
                UsbRequest requestIn = new UsbRequest();
                if (!requestIn.initialize(connection, in)) {
                    throw new Exception("I/O error on requestIn initialize");
                }

                while ((responseData = LedgerHelper.unwrapResponseAPDU(LEDGER_DEFAULT_CHANNEL, response.toByteArray(), HID_BUFFER_SIZE)) == null) {
                    responseBuffer.clear();
                    if (!requestIn.queue(responseBuffer, HID_BUFFER_SIZE)) {
                        requestIn.close();
                        throw new Exception("I/O error on requestIn queue");
                    }
                    connection.requestWait();
                    responseBuffer.rewind();
                    responseBuffer.get(transferBuffer, 0, HID_BUFFER_SIZE);
                    response.write(transferBuffer, 0, HID_BUFFER_SIZE);
                }
                requestIn.close();
                final String hexResponse = toHex(responseData);
                mainThreadHandler.post(() -> result.success(hexResponse));

            } catch (Exception e) {
                mainThreadHandler.post(() -> result.error("ExchangeError", e.getMessage(), null));
            }
        };
        this.executor.submit(exchangeRunnable);
    }

    public void close() {
        if (connection != null) {
            connection.releaseInterface(dongleInterface);
            connection.close();
        }
        if (executor != null && !executor.isShutdown()) {
            executor.shutdown();
        }
    }

    public static String toHex(byte[] buffer) {
        StringBuilder result = new StringBuilder();
        for (byte b : buffer) {
            result.append(String.format("%02x", b));
        }
        return result.toString();
    }
}