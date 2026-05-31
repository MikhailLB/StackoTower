import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../infra/msg_hub.dart';
import '../infra/net_probe.dart';
import '../infra/app_client.dart';
import '../infra/data_store.dart';
import 'offline_screen.dart';

class WebViewer extends StatefulWidget {
  final String destination;
  final DataStore store;
  final MsgHub hub;
  final NetProbe probe;
  final VoidCallback? onFirstPaint;
  final bool coldStartPush;

  const WebViewer({
    super.key,
    required this.destination,
    required this.store,
    required this.hub,
    required this.probe,
    this.onFirstPaint,
    this.coldStartPush = false,
  });

  @override
  State<WebViewer> createState() => _WebViewerState();
}

class _WebViewerState extends State<WebViewer>
    with WidgetsBindingObserver {
  late final WebViewController _wv;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _offlineRouted = false;
  String? _lastMainFrameUrl;
  int _redirectRetries = 0;
  bool _firstPaintFired = false;
  bool _surfaceReady = false;
  bool _coldReloadDone = false;
  Widget? _fullscreenOverlay;
  void Function()? _hideOverlay;

  void _applyImmersive() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  Future<void> _nudgeOrientationLayout() async {
    if (!Platform.isIOS) return;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _prepareColdStartSurface() async {
    _applyImmersive();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _nudgeOrientationLayout();
    await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _recalcViewport({bool reload = false}) async {
    if (!mounted) return;
    setState(() {});
    _wv.runJavaScript(
      'window.dispatchEvent(new Event("resize"));'
      'if(window.visualViewport)'
      '  window.visualViewport.dispatchEvent(new Event("resize"));',
    );
    _injectSafeArea();
    if (reload) {
      try { await _wv.reload(); } catch (_) {}
    }
  }

  void _scheduleImmersiveSettle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyImmersive();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() {});
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() {});
      });
    });
  }

  void _startLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyImmersive();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        _wv.loadRequest(Uri.parse(widget.destination));
      });
    });
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyImmersive();
      _drainStash();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    _applyImmersive();

    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (Platform.isAndroid) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _wv = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(appClient.userAgent)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(_buildDelegate());

    _configurePlatform();

    if (widget.coldStartPush) {
      _prepareColdStartSurface().then((_) {
        if (!mounted) return;
        setState(() => _surfaceReady = true);
        _wv.loadRequest(Uri.parse(widget.destination));
      });
    } else {
      _surfaceReady = true;
      _scheduleImmersiveSettle();
      _startLoad();
    }

    widget.hub.onPushUrl = (url) {
      if (!mounted) return;
      try {
        final uri = Uri.parse(url);
        if (uri.hasScheme) _wv.loadRequest(uri);
      } catch (_) {}
    };

    _connSub = widget.probe.onChange.listen((statuses) {
      if (statuses.every((s) => s == ConnectivityResult.none)) {
        _maybeRouteOffline();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _drainStash());
  }

  Future<void> _drainStash() async {
    final url = await widget.store.consumeOneShotUrl();
    if (url != null && url.isNotEmpty && mounted) {
      try {
        final uri = Uri.parse(url);
        if (uri.hasScheme) _wv.loadRequest(uri);
      } catch (_) {}
    }
  }

  NavigationDelegate _buildDelegate() {
    return NavigationDelegate(
      onPageStarted: (_) {},
      onPageFinished: (_) {
        _redirectRetries = 0;
        _injectSafeArea();
        _injectKeyboardFix();
        _injectAntiZoom();
        _injectMediaAutoplay();
        Future.delayed(const Duration(milliseconds: 800), () {
          final needsReload = widget.coldStartPush && !_coldReloadDone;
          if (needsReload) _coldReloadDone = true;
          _recalcViewport(reload: needsReload);
        });
        if (!_firstPaintFired) {
          _firstPaintFired = true;
          Future.delayed(const Duration(milliseconds: 600), () {
            try { widget.onFirstPaint?.call(); } catch (_) {}
          });
        }
      },
      onWebResourceError: (err) {
        if (err.isForMainFrame != true) return;
        final desc = err.description.toLowerCase();
        final loop = desc.contains('too_many_redirects') ||
            desc.contains('too many redirects') ||
            err.errorCode == -1007 || err.errorCode == -9;
        if (loop && _lastMainFrameUrl != null && _redirectRetries < 3) {
          _redirectRetries++;
          _wv.loadRequest(Uri.parse(_lastMainFrameUrl!));
          return;
        }
        _maybeRouteOffline();
      },
      onHttpError: (_) {},
      onNavigationRequest: (req) {
        final uri = Uri.tryParse(req.url);
        if (uri == null) return NavigationDecision.prevent;
        final s = uri.scheme;
        if (s == 'http' || s == 'https' || s == 'about' ||
            s == 'data' || s == 'blob') {
          if (req.isMainFrame) _lastMainFrameUrl = req.url;
          return NavigationDecision.navigate;
        }
        _launchExternal(uri);
        return NavigationDecision.prevent;
      },
    );
  }

  void _configurePlatform() {
    if (Platform.isIOS && _wv.platform is WebKitWebViewController) {
      (_wv.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }
    if (Platform.isAndroid && _wv.platform is AndroidWebViewController) {
      final android = _wv.platform as AndroidWebViewController;
      android.setMediaPlaybackRequiresUserGesture(false);
      android.setOnShowFileSelector(_pickFiles);
      android.setCustomWidgetCallbacks(
        onShowCustomWidget: (w, hide) {
          _hideOverlay = hide;
          if (mounted) setState(() => _fullscreenOverlay = w);
        },
        onHideCustomWidget: () {
          _hideOverlay = null;
          if (mounted) setState(() => _fullscreenOverlay = null);
        },
      );
      final cookies = AndroidWebViewCookieManager(
        AndroidWebViewCookieManagerCreationParams
            .fromPlatformWebViewCookieManagerCreationParams(
          const PlatformWebViewCookieManagerCreationParams(),
        ),
      );
      cookies.setAcceptThirdPartyCookies(android, true);
    }
  }

  Future<List<String>> _pickFiles(FileSelectorParams p) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: p.mode == FileSelectorMode.openMultiple,
        type: FileType.any,
      );
      if (result == null) return const [];
      return result.files
          .where((f) => f.path != null)
          .map((f) => Uri.file(f.path!).toString())
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _maybeRouteOffline() async {
    if (_offlineRouted) return;
    final ok = await widget.probe.isOnline();
    if (ok || !mounted) return;
    _offlineRouted = true;
    final current = await _wv.currentUrl() ?? widget.destination;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => OfflineScreen(
        probe: widget.probe,
        retryBuilder: (_) => WebViewer(
          destination: current,
          store: widget.store,
          hub: widget.hub,
          probe: widget.probe,
        ),
      ),
    ));
  }

  void _launchExternal(Uri uri) async {
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
  }

  void _injectSafeArea() {
    _wv.runJavaScript(r'''
(function(w,d){
  if(w.__sk_edge)return; w.__sk_edge=1;
  var TAG='sk-edge-style';
  var decl=':root{--sat:0px!important;--sar:0px!important;--sab:0px!important;--sal:0px!important;'
    +'--safe-area-inset-top:0px!important;--safe-area-inset-right:0px!important;'
    +'--safe-area-inset-bottom:0px!important;--safe-area-inset-left:0px!important;}'
    +'html,body{margin-top:0!important;padding-top:0!important;padding-left:0!important;padding-right:0!important;}'
    +'[id=__nuxt],[id=__layout],[id=app],[id=root],[class~=gameview-mobile-header]{padding-top:0!important;}';
  function softKeyboard(){return w.visualViewport&&w.visualViewport.height<w.innerHeight*0.75;}
  function fixMeta(){
    var m=d.querySelector('meta[name=viewport]'); if(!m)return;
    var c=m.getAttribute('content')||'';
    if(!/viewport-fit/i.test(c)){
      m.setAttribute('content',(c.replace(/\s*,?\s*viewport-fit\s*=\s*\w+/ig,'').trim())+', viewport-fit=contain');
    }
  }
  function run(){
    if(softKeyboard())return;
    var head=d.head||d.documentElement; if(!head)return;
    fixMeta();
    var node=d.getElementById(TAG);
    if(!node){node=d.createElement('style');node.id=TAG;}
    if(node.textContent!==decl)node.textContent=decl;
    if(head.lastElementChild!==node)head.appendChild(node);
  }
  run();
  var H=w.history;
  ['pushState','replaceState'].forEach(function(fn){
    var orig=H[fn];
    H[fn]=function(){var r=orig.apply(this,arguments);setTimeout(run,140);setTimeout(run,620);return r;};
  });
  w.addEventListener('popstate',function(){setTimeout(run,140);});
  setInterval(run,2600);
})(window,document);
''');
  }

  void _injectKeyboardFix() {
    _wv.runJavaScript(r'''
(function(w,d){
  if(w.__sk_kbd)return; w.__sk_kbd=1;
  function editable(el){return !!el&&(el.tagName=='INPUT'||el.tagName=='TEXTAREA'||el.isContentEditable);}
  function reveal(){
    var el=d.activeElement; if(!editable(el))return;
    var vv=w.visualViewport;
    if(vv){
      var box=el.getBoundingClientRect();
      if(box.bottom>vv.offsetTop+vv.height-20||box.top<vv.offsetTop)el.scrollIntoView({block:'center'});
    }else{el.scrollIntoView({block:'center'});}
  }
  d.addEventListener('focusin',function(e){if(editable(e.target))setTimeout(reveal,330);});
  if(w.visualViewport){
    var last=w.visualViewport.height;
    w.visualViewport.addEventListener('resize',function(){
      var now=w.visualViewport.height; if(now<last)setTimeout(reveal,110); last=now;
    });
  }
})(window,document);
''');
  }

  void _injectAntiZoom() {
    if (!Platform.isIOS) return;
    _wv.runJavaScript(r'''
(function(w,d){
  if(w.__sk_zoom)return; w.__sk_zoom=1;
  var s=d.createElement('style'); s.setAttribute('data-sk','z');
  s.textContent='input,select,textarea,[contenteditable=true]{font-size:16px!important;}';
  (d.head||d.documentElement).appendChild(s);
})(window,document);
''');
  }

  void _injectMediaAutoplay() {
    _wv.runJavaScript(r'''
(function(w,d){
  if(w.__sk_media)return; w.__sk_media=1;
  function arm(v){
    try{
      v.muted=true; v.defaultMuted=true; v.autoplay=true; v.playsInline=true;
      v.setAttribute('playsinline',''); v.setAttribute('webkit-playsinline','');
      var pr=v.play&&v.play(); if(pr&&pr.catch)pr.catch(function(){});
    }catch(e){}
  }
  function scan(scope){
    try{var vids=(scope||d).querySelectorAll('video'); for(var i=0;i<vids.length;i++)arm(vids[i]);}catch(e){}
  }
  scan(d);
  d.addEventListener('touchend',function(){scan(d);},{passive:true});
  var obs=new MutationObserver(function(list){
    for(var i=0;i<list.length;i++){
      var added=list[i].addedNodes||[];
      for(var j=0;j<added.length;j++){
        var n=added[j]; if(!n||n.nodeType!=1)continue;
        if(n.tagName=='VIDEO')arm(n); scan(n);
      }
    }
  });
  obs.observe(d.documentElement,{childList:true,subtree:true});
  setInterval(function(){scan(d);},1600);
})(window,document);
''');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    widget.hub.onPushUrl = null;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).viewPadding;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _fullscreenOverlay != null) _hideOverlay?.call();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_surfaceReady)
              Padding(
                padding: EdgeInsets.only(
                  top: safe.top,
                  bottom: safe.bottom,
                  left: safe.left,
                  right: safe.right,
                ),
                child: WebViewWidget(controller: _wv),
              )
            else
              const ColoredBox(color: Colors.black),
            if (_fullscreenOverlay != null)
              Positioned.fill(child: _fullscreenOverlay!),
          ],
        ),
      ),
    );
  }
}
