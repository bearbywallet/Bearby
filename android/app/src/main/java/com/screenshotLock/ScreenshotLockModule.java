package com.screenshotLock;

import android.app.Activity;
import android.view.WindowManager;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import static com.facebook.react.bridge.UiThreadUtil.runOnUiThread;

public class ScreenshotLockModule extends ReactContextBaseJavaModule {
	private static final String PREVENT_SCREENSHOT_ERROR_CODE = "PREVENT_SCREENSHOT_ERROR_CODE";
	private final ReactApplicationContext reactContext;

	public ScreenshotLockModule(ReactApplicationContext reactContext) {
		super(reactContext);
		this.reactContext = reactContext;
	}

	@Override
	public String getName() {
		return "ScreenshotLock";
	}

	@ReactMethod
	public void forbid(Promise promise) {
		runOnUiThread(new Runnable() {
			@Override
			public void run() {
				try {
					getCurrentActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_SECURE);
					promise.resolve("Done. Screenshot taking locked.");
				} catch(Exception e) {
					promise.reject(PREVENT_SCREENSHOT_ERROR_CODE, "Forbid screenshot taking failure.");
				}
			}
		});
	}

	@ReactMethod
	public void allow(Promise promise) {
		runOnUiThread(new Runnable() {
			@Override
			public void run() {
				try {
					getCurrentActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
					promise.resolve("Done. Screenshot taking unlocked.");
				} catch (Exception e) {
					promise.reject(PREVENT_SCREENSHOT_ERROR_CODE, "Allow screenshot taking failure.");
				}
			}
		});
	}

}
