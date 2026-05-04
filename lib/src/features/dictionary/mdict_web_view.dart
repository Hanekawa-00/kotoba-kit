import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MdictWebView extends StatefulWidget {
  const MdictWebView({
    super.key,
    required this.html,
    required this.sourceDictionary,
    this.expand = false,
    required this.onSearch,
  });

  final String html;
  final String sourceDictionary;
  final bool expand;
  final ValueChanged<String> onSearch;

  @override
  State<MdictWebView> createState() => _MdictWebViewState();
}

class _MdictWebViewState extends State<MdictWebView> {
  @override
  Widget build(BuildContext context) {
    final height = _readerHeight(context);

    final webView = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: InAppWebView(
        key: ValueKey(widget.html),
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(
            () => VerticalDragGestureRecognizer(),
          ),
        },
        initialData: InAppWebViewInitialData(
          data: _buildMdictDocument(context, widget.html),
          baseUrl: WebUri('https://kotoba-kit.local/'),
          encoding: 'utf8',
          mimeType: 'text/html',
        ),
        initialSettings: InAppWebViewSettings(
          transparentBackground: true,
          javaScriptEnabled: true,
          supportZoom: false,
          useShouldOverrideUrlLoading: true,
          verticalScrollBarEnabled: true,
          horizontalScrollBarEnabled: false,
          disableHorizontalScroll: true,
          disallowOverScroll: false,
        ),
        onWebViewCreated: (controller) {
          controller.addJavaScriptHandler(
            handlerName: 'lunaSearchWord',
            callback: (arguments) {
              final word = arguments.isEmpty ? null : arguments.first;
              if (word is String && word.trim().isNotEmpty) {
                widget.onSearch(word.trim());
              }
            },
          );
          controller.addJavaScriptHandler(
            handlerName: 'lunaResize',
            callback: (_) {},
          );
        },
        onReceivedError: (controller, request, error) {
          debugPrint(
            'MDict WebView ${widget.sourceDictionary} load error: '
            '${error.type} ${error.description}',
          );
        },
        onConsoleMessage: (controller, consoleMessage) {
          debugPrint(
            'MDict WebView ${widget.sourceDictionary}: '
            '${consoleMessage.message}',
          );
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final linkedWord = _lookupWordFromUrl(
            navigationAction.request.url?.toString(),
          );
          if (linkedWord != null) {
            widget.onSearch(linkedWord);
          }
          return NavigationActionPolicy.CANCEL;
        },
      ),
    );

    if (widget.expand) {
      return SizedBox.expand(
        key: const ValueKey('mdict-reader-viewport'),
        child: webView,
      );
    }

    return SizedBox(
      key: const ValueKey('mdict-reader-viewport'),
      height: height,
      child: webView,
    );
  }

  double _readerHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < 760) {
      return (size.height * 0.58).clamp(320.0, 560.0);
    }

    return (size.height * 0.68).clamp(420.0, 780.0);
  }
}

String? _lookupWordFromUrl(String? url) {
  if (url == null) {
    return null;
  }

  final decoded = Uri.decodeFull(url).trim();
  if (decoded.isEmpty || decoded.startsWith('#')) {
    return null;
  }

  for (final scheme in ['entry://', 'mdict://', 'bword://']) {
    if (decoded.startsWith(scheme)) {
      return decoded.substring(scheme.length).replaceFirst(RegExp(r'^/+'), '');
    }
  }

  final weblioMatch = RegExp(
    r'^https?://www\.weblio\.jp/content/(.+)$',
  ).firstMatch(decoded);
  if (weblioMatch != null) {
    return Uri.decodeComponent(weblioMatch.group(1)!);
  }

  final jishoMatch = RegExp(
    r'^https?://jisho\.org/(?:search|word)/(.+)$',
  ).firstMatch(decoded);
  if (jishoMatch != null) {
    final word = Uri.decodeComponent(jishoMatch.group(1)!);
    return word.split('/').first;
  }

  if (decoded.startsWith('http://') ||
      decoded.startsWith('https://') ||
      decoded.startsWith('data:') ||
      decoded.startsWith('javascript:') ||
      decoded.startsWith('mailto:')) {
    return null;
  }

  return decoded.replaceFirst(RegExp(r'^/+'), '');
}

String _buildMdictDocument(BuildContext context, String value) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final textStyle = theme.textTheme.bodyMedium;
  final body = _prepareMdictHtml(value);
  final foreground = _cssColor(scheme.onSurface);
  final muted = _cssColor(scheme.onSurfaceVariant);
  final primary = _cssColor(scheme.primary);
  final surface = _cssColor(scheme.surfaceContainerHighest);
  final outline = _cssColor(scheme.outlineVariant);
  final fontSize = textStyle?.fontSize ?? 14;
  final fontFamily = _cssString(
    textStyle?.fontFamily ?? 'system-ui, "Yu Gothic UI", "Meiryo", sans-serif',
  );

  return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    :root {
      --primary: $primary;
      --on-surface: $foreground;
      --on-surface-variant: $muted;
      --surface-container: $surface;
      --outline-variant: $outline;
    }
    html, body {
      margin: 0;
      padding: 0;
      background: transparent;
      color: $foreground;
      font-family: $fontFamily;
      font-size: ${fontSize}px;
      line-height: 1.62;
      letter-spacing: 0;
      overflow-wrap: anywhere;
      word-break: normal;
    }
    body {
      box-sizing: border-box;
      width: 100%;
      overflow-x: hidden;
      overflow-y: auto;
      -webkit-overflow-scrolling: touch;
    }
    #luna_dict_internal_view {
      background: transparent;
      padding-right: 2px;
    }
    h1, h2, h3, h4 {
      margin: 0 0 14px;
      color: $foreground;
      line-height: 1.25;
      font-weight: 700;
    }
    h3 {
      font-size: 1.28rem;
    }
    p, div, section {
      max-width: 100%;
    }
    p {
      margin: 0 0 10px;
    }
    a {
      color: $primary;
      text-decoration: underline;
      cursor: pointer;
    }
    k, .mdict-key {
      color: $primary;
    }
    v, .mdict-sense-number {
      color: $primary;
      font-weight: 700;
      padding-right: 0.25em;
    }
    .hinshi {
      color: $muted;
      font-weight: 600;
    }
    .description {
      display: block;
    }
    img, video, audio {
      max-width: 100%;
      height: auto;
    }
    table {
      max-width: 100%;
      border-collapse: collapse;
      background: color-mix(in srgb, $surface 32%, transparent);
    }
    td, th {
      padding: 6px 8px;
      border: 1px solid color-mix(in srgb, $muted 28%, transparent);
      vertical-align: top;
    }
    br {
      line-height: 1.62;
    }
    .element-hover {
      outline: 2px dashed #ffd700 !important;
      outline-offset: 2px !important;
    }
    .hightlight {
      background-color: yellow;
      outline: 2px solid #ffd700 !important;
      outline-offset: 2px !important;
    }
    .hightlight2 {
      background-color: yellow;
    }
  </style>
  <script>
    var lastmusicplayer = false;

    function luna_post_resize() {
      const body = document.body;
      const html = document.documentElement;
      const height = Math.ceil(Math.max(
        body ? body.scrollHeight : 0,
        body ? body.offsetHeight : 0,
        html ? html.clientHeight : 0,
        html ? html.scrollHeight : 0,
        html ? html.offsetHeight : 0
      ));
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('lunaResize', height);
      }
    }

    function safe_mdict_search_word(word) {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('lunaSearchWord', word);
      }
    }

    function mdict_play_sound(ext, b64) {
      const music = new Audio();
      music.src = 'data:' + ext + ';base64,' + b64;
      if (lastmusicplayer !== false) {
        lastmusicplayer.pause();
      }
      lastmusicplayer = music;
      music.play();
    }

    function replacelongvarsrcs(varval, varname) {
      const type = varval[0];
      const elements = document.querySelectorAll('[' + type + '="' + varname + '"]');
      for (let i = 0; i < elements.length; i++) {
        elements[i][type] = 'data:' + varval[1] + ';base64,' + varval[2];
      }
    }

    function clear_hightlight() {
      for (const klass of ['hightlight', 'hightlight2', 'element-hover']) {
        while (true) {
          const elements = document.getElementsByClassName(klass);
          if (elements.length === 0) break;
          elements[0].classList.remove(klass);
        }
      }
    }

    document.addEventListener('click', function(e) {
      const target = e.target.closest('a');
      if (!target) return;
      const href = target.getAttribute('href') || '';
      if (href.startsWith('entry://')) {
        e.preventDefault();
        e.stopPropagation();
        safe_mdict_search_word(decodeURIComponent(href.substring(8)));
      }
    }, true);

    window.addEventListener('load', function() {
      luna_post_resize();
      setTimeout(luna_post_resize, 80);
      setTimeout(luna_post_resize, 320);
    });

    if (window.ResizeObserver) {
      const observer = new ResizeObserver(luna_post_resize);
      document.addEventListener('DOMContentLoaded', function() {
        observer.observe(document.body);
      });
    }
  </script>
</head>
<body>
<div id="luna_dict_internal_view">
$body
</div>
</body>
</html>
''';
}

String _prepareMdictHtml(String value) {
  if (RegExp(r'<[A-Za-z][^>]*>').hasMatch(value)) {
    return value;
  }

  return value
      .split('\n')
      .map((line) => const HtmlEscape().convert(line.trimRight()))
      .join('<br>');
}

String _cssColor(Color color) {
  final alpha = color.a;
  final red = (color.r * 255).round();
  final green = (color.g * 255).round();
  final blue = (color.b * 255).round();

  if (alpha >= 1) {
    return 'rgb($red, $green, $blue)';
  }

  return 'rgba($red, $green, $blue, ${alpha.toStringAsFixed(3)})';
}

String _cssString(String value) {
  if (value.contains(',')) {
    return value;
  }

  return '"${value.replaceAll('"', r'\"')}"';
}
