import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
import WebKit
#if canImport(UIKit)
import UIKit
#endif

public enum AnalyticsFactory {
    public static func makeConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        #if os(iOS)
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        installAudioUnlockScriptIfNeeded(into: configuration)
        activatePlaybackAudioSessionIfNeeded()
        #endif
        if #available(iOS 14.0, macOS 11.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                configuration.defaultWebpagePreferences.preferredContentMode = .desktop
            }
            #endif
        } else {
            configuration.preferences.javaScriptEnabled = true
        }
        return configuration
    }

    public static func prewarm(url: URL, timeout: TimeInterval = 8) {
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration())
        webView.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: timeout))
    }

    #if canImport(AVFoundation) && os(iOS)
    private static func installAudioUnlockScriptIfNeeded(into configuration: WKWebViewConfiguration) {
        let script = WKUserScript(
            source: audioUnlockScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        configuration.userContentController.addUserScript(script)
    }

    public static func activatePlaybackAudioSessionIfNeeded() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true, options: [])
        } catch {
            #if DEBUG
            print("AnalyticsFactory audio session activation failed: \(error)")
            #endif
        }
    }

    private static let audioUnlockScript = """
    (function () {
      if (window.__analyticsAudioUnlockInstalled) {
        return;
      }
      window.__analyticsAudioUnlockInstalled = true;

      var unlocked = false;
      var keepAliveAudio = null;

      function ensureKeepAliveAudio() {
        if (keepAliveAudio) {
          return keepAliveAudio;
        }

        try {
          var audio = document.createElement("audio");
          audio.setAttribute("playsinline", "true");
          audio.setAttribute("webkit-playsinline", "true");
          audio.preload = "auto";
          audio.loop = true;
          audio.volume = 0.0001;
          audio.src = "data:audio/mp3;base64,//uQxAAAAAAAAAAAAAAAAAAAAAAASW5mbwAAAA8AAAAFAAAGhgBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVU=";
          audio.style.display = "none";
          document.documentElement.appendChild(audio);
          keepAliveAudio = audio;
        } catch (error) {}

        return keepAliveAudio;
      }

      function ensureMediaChannelOpen() {
        try {
          var audio = ensureKeepAliveAudio();
          if (!audio) {
            return;
          }

          var playPromise = audio.play();
          if (playPromise && playPromise.catch) {
            playPromise.catch(function () {});
          }
        } catch (error) {}
      }

      function unlockAudio() {
        if (unlocked) {
          return;
        }
        unlocked = true;

        try {
          var AudioContextRef = window.AudioContext || window.webkitAudioContext;
          if (AudioContextRef) {
            var context = window.__analyticsAudioContext;
            if (!context) {
              context = new AudioContextRef();
              window.__analyticsAudioContext = context;
            }

            if (context.state === "suspended" && context.resume) {
              context.resume().catch(function () {});
            }

            var buffer = context.createBuffer(1, 1, 22050);
            var source = context.createBufferSource();
            source.buffer = buffer;
            source.connect(context.destination);
            if (source.start) {
              source.start(0);
            } else if (source.noteOn) {
              source.noteOn(0);
            }
          }
        } catch (error) {}

        try {
          var audio = document.createElement("audio");
          audio.setAttribute("playsinline", "true");
          audio.volume = 0.0001;
          audio.src = "data:audio/mp3;base64,//uQxAAAAAAAAAAAAAAAAAAAAAAASW5mbwAAAA8AAAAFAAAGhgBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVU=";
          var playPromise = audio.play();
          if (playPromise && playPromise.then) {
            playPromise.then(function () {
              audio.pause();
              audio.remove();
            }).catch(function () {
              audio.remove();
            });
          }
        } catch (error) {}

        ensureMediaChannelOpen();

        window.removeEventListener("touchstart", unlockAudio, true);
        window.removeEventListener("touchend", unlockAudio, true);
        window.removeEventListener("pointerdown", unlockAudio, true);
        window.removeEventListener("mousedown", unlockAudio, true);
        window.removeEventListener("click", unlockAudio, true);
      }

      document.addEventListener("visibilitychange", function () {
        if (!document.hidden) {
          ensureMediaChannelOpen();

          try {
            var context = window.__analyticsAudioContext;
            if (context && context.state === "suspended" && context.resume) {
              context.resume().catch(function () {});
            }
          } catch (error) {}
        }
      }, true);

      window.addEventListener("touchstart", unlockAudio, true);
      window.addEventListener("touchend", unlockAudio, true);
      window.addEventListener("pointerdown", unlockAudio, true);
      window.addEventListener("mousedown", unlockAudio, true);
      window.addEventListener("click", unlockAudio, true);
    })();
    """
    #endif
}
