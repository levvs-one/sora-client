# Sora's Linux WebView patch

Source: [webview_all_linux 1.4.4](https://pub.dev/packages/webview_all_linux/versions/1.4.4), MIT, [Abandoft](https://github.com/abandoft/webview_all). The upstream license is preserved in `LICENSE`.

The Dart and native sources are unchanged except for `linux/src/webview/linux_webview.cc`: WebKit's `web-process-terminated` signal now reports a main-frame `webContentProcessTerminated` error, and destruction disconnects callbacks before releasing their owner. This allows Sora to release a crashed browser and show its existing retry action, including after a completed page load. Upstream 1.4.4 and its current main branch do not forward this signal.

Remove this override when an upstream release provides equivalent process-termination handling. Sora's native crash/retry and repeated-open checks run in a hidden X11 session; app tests cover native ownership and error delivery.
