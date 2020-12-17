window.ReactNativeWebView.postMessage(JSON.stringify({
  type: 0,
  payload: {
    origin: window.origin
  }
}));
