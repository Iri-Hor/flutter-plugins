import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:win32/win32.dart';

void main(List<String> args) {
  debugPrint('args: $args');
  if (runWebViewTitleBarWidget(args)) {
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _controller = TextEditingController(
    text: 'C:/Users/lheinze/Desktop/TestHTML/testHTML.html',
  );

  bool? _webviewAvailable;

  bool maximizedzChecked = false;

  late Webview webview;

  final executeJavaScriptController = TextEditingController(text: "saySomethingNice('Something Nice :)')");
  final webMessageControllerString = TextEditingController(text: "ImportantValue 5");
  final webMessageControllerJSON = TextEditingController(text: "{\"ImportantValue\": \"5\"}");

  bool hideMainWindow = false;

  @override
  void initState() {
    super.initState();
    WebviewWindow.isWebviewAvailable().then((value) {
      setState(() {
        _webviewAvailable = value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: [
            IconButton(
              onPressed: () async {
                final webview = await WebviewWindow.create(
                  configuration: CreateConfiguration(
                    windowHeight: 1280,
                    windowWidth: 720,
                    title: "ExampleTestWindow",
                    titleBarTopPadding: Platform.isMacOS ? 20 : 0,
                    userDataFolderWindows: await _getWebViewPath(),
                  ),
                );
                webview
                  ..registerJavaScriptMessageHandler("test", (name, body) {
                    debugPrint('on javaScipt message: $name $body');
                  })
                  ..setApplicationNameForUserAgent(" WebviewExample/1.0.0")
                  ..setPromptHandler((prompt, defaultText) {
                    if (prompt == "test") {
                      return "Hello World!";
                    } else if (prompt == "init") {
                      return "initial prompt";
                    }
                    return "";
                  })
                  ..addScriptToExecuteOnDocumentCreated("""
  const mixinContext = {
    platform: 'Desktop',
    conversation_id: 'conversationId',
    immersive: false,
    app_version: '1.0.0',
    appearance: 'dark',
  }
  window.MixinContext = {
    getContext: function() {
      return JSON.stringify(mixinContext)
    }
  }
""")
                  ..launch("http://localhost:3000/test.html");
              },
              icon: const Icon(Icons.bug_report),
            )
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextField(controller: _controller),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 200,
                      child: CheckboxListTile(
                        title: Text("hide main window"),
                        tristate: false,
                        value: hideMainWindow,
                        onChanged: (newValue) {
                          setState(() {
                            hideMainWindow = newValue!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading, //  <-- leading Checkbox
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _webviewAvailable != true ? null : _onTap,
                    child: const Text('Open'),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () async {
                      await WebviewWindow.clearAll(
                        userDataFolderWindows: await _getWebViewPath(),
                      );
                      debugPrint('clear complete');
                    },
                    child: const Text('Clear all'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _executeJavaScript,
                    child: const Text('execute JavaScript'),
                  ),
                  TextFormField(
                    controller: executeJavaScriptController,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Enter javascript command',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _postWebMessageAsString,
                    child: const Text('post webmessage as string'),
                  ),
                  TextFormField(
                    controller: webMessageControllerString,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Enter a webmessage as String',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _postWebMessageAsJson,
                    child: const Text('post webmessage as JSON'),
                  ),
                  TextFormField(
                    controller: webMessageControllerJSON,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Enter a webmessage as JSON',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _hideMainWindow,
                    child: const Text('Hide Main Window'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _showMainWindow,
                    child: const Text('Show Main Window'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _hideWebviewWindow,
                    child: const Text('Hide Webview Window'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _showWebviewWindow,
                    child: const Text('Show Webview Window'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Maximized'),
                      Checkbox(
                        tristate: false,
                        value: maximizedzChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            maximizedzChecked = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => _bringWebviewWindowToForeground(maximizedzChecked),
                    child: const Text('Bring webview windows to foreground'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _openDevTools,
                    child: const Text('Open Dev Tools'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _getPositionalParameters,
                    child: const Text('Get Position and Size of Webview Window'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _moveWebviewWindow,
                    child: const Text('RelocateWebview Window'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap() async {
    final hwnd = FindWindow(ffi.nullptr, 'webview_window_example'.toNativeUtf16());
    final rect = calloc<RECT>();
    GetWindowRect(hwnd, rect);
    debugPrint("[" + rect.ref.left.toString() + ", " + rect.ref.right.toString() + "] - [" + rect.ref.top.toString() + ", " + rect.ref.bottom.toString() + "]");
    webview = await WebviewWindow.create(
      configuration: CreateConfiguration(
        userDataFolderWindows: await _getWebViewPath(),
        titleBarTopPadding: Platform.isMacOS ? 20 : 0,
        title: "Pizza Hawai ist ein Vebrechen gegen die Menschlichkeit!",
        titleBarHeight: 0,
        usePluginDefaultBehaviour: false,
        windowWidth: rect.ref.right - rect.ref.left,
        windowHeight: rect.ref.bottom - rect.ref.top,
        windowPosX: rect.ref.left,
        windowPosY: rect.ref.top,
        openMaximized: false,
      ),
    );
    free(rect);
    await webview.blockNavigations(true);
    await webview.triggerUrlRequestEventOnDartTriggeredLaunch(false);
    webview
      ..setBrightness(Brightness.dark)
      ..setApplicationNameForUserAgent(" WebviewExample/1.0.0")
      ..addOnUrlRequestCallback((url) {
        debugPrint('url requested: $url');
        if (url == 'https://www.youtube.com/watch?v=hvYBFl5Tb1s&t=506s') {
          webview.launch('https://www.youtube.com/watch?v=hvYBFl5Tb1s&t=506s');
        }
      })
      ..addOnWebMessageReceivedCallback((msg) {
        if (msg == "ShowWindow") {
          debugPrint('Show Main Window');
          _showMainWindow();
        } else {
          debugPrint('received web message: $msg');
        }
      })
      ..onClose.whenComplete(() {
        debugPrint("on close");
      })
      ..launch(_controller.text);

    if (hideMainWindow) {
      final hwnd = FindWindow(ffi.nullptr, 'webview_window_example'.toNativeUtf16());
      //final hwnd = GetForegroundWindow();

      ShowWindow(hwnd, SW_HIDE);
    }

    await Future.delayed(const Duration(seconds: 2));
    for (final javaScript in _javaScriptToEval) {
      try {
        final ret = await webview.evaluateJavaScript(javaScript);
        debugPrint('evaluateJavaScript: $ret');
      } catch (e) {
        debugPrint('evaluateJavaScript error: $e \n $javaScript');
      }
    }
  }

  void _executeJavaScript() async {
    var cmd = executeJavaScriptController.text.toString();
    debugPrint('execute JavaScript at Website: $cmd');
    var ret = await webview.evaluateJavaScript(cmd);
    debugPrint('received Answer from Website: $ret');
  }

  void _postWebMessageAsString() async {
    var msg = webMessageControllerString.text.toString();
    debugPrint('send webmessage as String to Website: $msg');
    webview.postWebMessageAsString(msg);
  }

  void _postWebMessageAsJson() async {
    var msg = webMessageControllerJSON.text.toString();
    debugPrint('send webmessage as JSON to Website: $msg');
    webview.postWebMessageAsJson(msg);
  }

  void _hideMainWindow() async {
    //final hwnd = FindWindow(ffi.nullptr, TEXT('webview_window_example'));
    final hwnd = FindWindow(TEXT('FLUTTER_RUNNER_WIN32_WINDOW'), TEXT('webview_window_example'));
    //final hwnd = GetForegroundWindow();

    ShowWindow(hwnd, SW_HIDE);
  }

  void _hideWebviewWindow() async {
    webview.showWebviewWindow(false);
  }

  void _showWebviewWindow() async {
    webview.showWebviewWindow(true);
  }

  void _bringWebviewWindowToForeground(bool maximized) async {
    webview.bringToForeground(maximized: maximized);
  }

  void _showMainWindow() async {
    //final hwnd = FindWindow(ffi.nullptr, TEXT('webview_window_example'));
    final hwnd = FindWindow(TEXT('FLUTTER_RUNNER_WIN32_WINDOW'), TEXT('webview_window_example'));
    //final hwnd = GetForegroundWindow();

    ShowWindow(hwnd, SW_SHOW);
  }

  void _openDevTools() async {
    webview.openDevToolsWindow();
  }

  void _getPositionalParameters() async {
    final res = await webview.getPositionalParameters();
    if (res == null) {
      debugPrint('    Plugin: Null');
    } else {
      debugPrint('    x: ${res['left']}');
      debugPrint('    y: ${res['top']}');
      debugPrint('    width: ${res['width']}');
      debugPrint('    height: ${res['height']}');
      debugPrint('    maximized: ${res['maximized']}');
    }
  }

  void _moveWebviewWindow() async {
    await webview.moveWebviewWindow(100, 100, 400, 400);
  }
}

const _javaScriptToEval = [
  """
  function test() {
    return;
  }
  test();
  """,
  'eval({"name": "test", "user_agent": navigator.userAgent})',
  '1 + 1',
  'undefined',
  '1.0 + 1.0',
  '"test"',
];

Future<String> _getWebViewPath() async {
  final document = await getApplicationDocumentsDirectory();
  return p.join(
    document.path,
    'desktop_webview_window',
  );
}
