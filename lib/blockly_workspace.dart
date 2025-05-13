// ignore_for_file: unused_field, unused_import, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io' show Platform;

class BlocklyWorkspace extends StatefulWidget {
  final Function(String) onCodeGenerated;
  final List<String> availableBlocks;

  const BlocklyWorkspace({
    Key? key,
    required this.onCodeGenerated,
    required this.availableBlocks,
  }) : super(key: key);

  @override
  State<BlocklyWorkspace> createState() => _BlocklyWorkspaceState();
}

class _BlocklyWorkspaceState extends State<BlocklyWorkspace> {
  InAppWebViewController? _controller;
  bool isWebViewReady = false;
  final GlobalKey webViewKey = GlobalKey();
  static const int _debounceDelay = 300; // ms

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return _buildUnsupportedPlatformWidget();
    }

    return InAppWebView(
      key: webViewKey,
      initialSettings: _getWebViewSettings(),
      onWebViewCreated: _handleWebViewCreated,
      onLoadStop: _handleLoadStop,
      onConsoleMessage: _handleConsoleMessage,
      onLoadError: _handleLoadError,
      onReceivedError: _handleReceivedError,
    );
  }

  Widget _buildUnsupportedPlatformWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Blockly Editor is not supported on this platform.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please use the Android or iOS version of the app for the full coding experience.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orange[900]),
            ),
          ],
        ),
      ),
    );
  }

  InAppWebViewSettings _getWebViewSettings() {
    return InAppWebViewSettings(
      javaScriptEnabled: true,
      useHybridComposition: true,
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      allowFileAccess: true,
      transparentBackground: true,
      disableHorizontalScroll: true,
      disableVerticalScroll: true,
      supportZoom: false,
      useWideViewPort: false,
    );
  }

  void _handleWebViewCreated(InAppWebViewController controller) {
    _controller = controller;
    _loadBlocklyHtml(controller);
  }

  void _loadBlocklyHtml(InAppWebViewController controller) {
    controller.loadData(
      data: _getBlocklyHtml(),
      mimeType: 'text/html',
      encoding: 'utf-8',
    );
  }

  String _getBlocklyHtml() {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <title>Blockly</title>
        <script src="https://unpkg.com/blockly/blockly.min.js"></script>
        <script src="https://unpkg.com/blockly/javascript_compressed.js"></script>
        <script src="https://unpkg.com/blockly/blocks_compressed.js"></script>
        <script src="https://unpkg.com/blockly/msg/en.js"></script>
        <style>
          html, body {
            height: 100%;
            margin: 0;
            padding: 0;
            overflow: hidden;
            background-color: transparent;
          }
          #blocklyDiv {
            height: 100%;
            width: 100%;
            position: absolute;
            top: 0;
            left: 0;
          }
        </style>
      </head>
      <body>
        <div id="blocklyDiv"></div>
        <script>
          ${_getBlocklyJavaScript()}
        </script>
      </body>
      </html>
    ''';
  }

  String _getBlocklyJavaScript() {
    return '''
      // Initialize when the document is fully loaded
      window.addEventListener('load', function() {
        try {
          // Define block definitions
          const blockDefinitions = {
            'move_forward': {
              init: function() {
                this.appendDummyInput().appendField("Move Forward");
                this.setPreviousStatement(true, null);
                this.setNextStatement(true, null);
                this.setColour(210);
              }
            },
            'move_backward': {
              init: function() {
                this.appendDummyInput().appendField("Move Backward");
                this.setPreviousStatement(true, null);
                this.setNextStatement(true, null);
                this.setColour(210);
              }
            },
            'turn_left': {
              init: function() {
                this.appendDummyInput().appendField("Turn Left");
                this.setPreviousStatement(true, null);
                this.setNextStatement(true, null);
                this.setColour(210);
              }
            },
            'turn_right': {
              init: function() {
                this.appendDummyInput().appendField("Turn Right");
                this.setPreviousStatement(true, null);
                this.setNextStatement(true, null);
                this.setColour(210);
              }
            },
            'wait': {
              init: function() {
                this.appendValueInput("DURATION")
                    .setCheck("Number")
                    .appendField("Wait");
                this.appendDummyInput().appendField("seconds");
                this.setPreviousStatement(true, null);
                this.setNextStatement(true, null);
                this.setColour(120);
              }
            },
            'repeat': {
              init: function() {
                this.appendValueInput("TIMES")
                    .setCheck("Number")
                    .appendField("Repeat");
                this.appendDummyInput().appendField("times");
                this.appendStatementInput("DO").appendField("do");
                this.setPreviousStatement(true, null);
                this.setNextStatement(true, null);
                this.setColour(120);
              }
            },
            'if_then': {
              init: function() {
                this.appendValueInput("CONDITION")
                    .setCheck("Boolean")
                    .appendField("if");
                this.appendStatementInput("DO").appendField("then");
                this.setPreviousStatement(true, null);
                this.setNextStatement(true, null);
                this.setColour(120);
              }
            },
            'distance_sensor': {
              init: function() {
                this.appendDummyInput().appendField("Distance Sensor");
                this.setOutput(true, "Number");
                this.setColour(160);
              }
            },
            'auto_mode': {
              init: function() {
                this.appendDummyInput().appendField("Auto Mode");
                this.setPreviousStatement(true, null);
                this.setNextStatement(true, null);
                this.setColour(290);
              }
            }
          };

          // Register block definitions
          Object.entries(blockDefinitions).forEach(([type, definition]) => {
            if (!Blockly.Blocks[type]) {
              Blockly.Blocks[type] = definition;
            }
          });

          // Initialize JavaScript generator
          if (!Blockly.JavaScript) {
            Blockly.JavaScript = new Blockly.Generator('JavaScript');
          }

          Blockly.JavaScript.ORDER_ATOMIC = 0;
          Blockly.JavaScript.ORDER_NONE = 99;

          // Define JavaScript generators
          const generators = {
            'move_forward': (block) => 'sendCommand("F1000");\\n',
            'move_backward': (block) => 'sendCommand("B1000");\\n',
            'turn_left': (block) => 'sendCommand("L90");\\n',
            'turn_right': (block) => 'sendCommand("R90");\\n',
            'wait': (block) => {
              const duration = Blockly.JavaScript.valueToCode(block, 'DURATION', Blockly.JavaScript.ORDER_ATOMIC) || '0';
              return 'wait(' + duration + ');\\n';
            },
            'repeat': (block) => {
              const times = Blockly.JavaScript.valueToCode(block, 'TIMES', Blockly.JavaScript.ORDER_ATOMIC) || '0';
              const branch = Blockly.JavaScript.statementToCode(block, 'DO');
              return 'for (let i = 0; i < ' + times + '; i++) {\\n' + branch + '}\\n';
            },
            'if_then': (block) => {
              const condition = Blockly.JavaScript.valueToCode(block, 'CONDITION', Blockly.JavaScript.ORDER_ATOMIC) || 'false';
              const branch = Blockly.JavaScript.statementToCode(block, 'DO');
              return 'if (' + condition + ') {\\n' + branch + '}\\n';
            },
            'distance_sensor': (block) => ['getDistance()', Blockly.JavaScript.ORDER_ATOMIC],
            'auto_mode': (block) => 'sendCommand("A");\\n'
          };

          // Register generators
          Object.entries(generators).forEach(([type, generator]) => {
            Blockly.JavaScript[type] = generator;
          });

          // Create toolbox
          const toolbox = {
            kind: 'categoryToolbox',
            contents: [
              {
                kind: 'category',
                name: 'Movement',
                colour: 210,
                contents: [
                  { kind: 'block', type: 'move_forward' },
                  { kind: 'block', type: 'move_backward' },
                  { kind: 'block', type: 'turn_left' },
                  { kind: 'block', type: 'turn_right' }
                ]
              },
              {
                kind: 'category',
                name: 'Control',
                colour: 120,
                contents: [
                  { kind: 'block', type: 'wait' },
                  { kind: 'block', type: 'repeat' },
                  { kind: 'block', type: 'if_then' }
                ]
              },
              {
                kind: 'category',
                name: 'Sensors',
                colour: 160,
                contents: [
                  { kind: 'block', type: 'distance_sensor' }
                ]
              },
              {
                kind: 'category',
                name: 'Modes',
                colour: 290,
                contents: [
                  { kind: 'block', type: 'auto_mode' }
                ]
              }
            ]
          };

          // Initialize workspace
          const workspace = Blockly.inject('blocklyDiv', {
            toolbox: toolbox,
            scrollbars: true,
            trashcan: true,
            zoom: {
              controls: true,
              wheel: true,
              startScale: 1.0,
              maxScale: 3,
              minScale: 0.3,
              scaleSpeed: 1.2
            },
            grid: {
              spacing: 20,
              length: 3,
              colour: '#ccc',
              snap: true
            }
          });

          // Setup change listener with debouncing
          let debounceTimer;
          workspace.addChangeListener(function(event) {
            if (event.type == Blockly.Events.BLOCK_CHANGE ||
                event.type == Blockly.Events.BLOCK_CREATE ||
                event.type == Blockly.Events.BLOCK_DELETE ||
                event.type == Blockly.Events.BLOCK_MOVE) {
              clearTimeout(debounceTimer);
              debounceTimer = setTimeout(function() {
                try {
                  const code = Blockly.JavaScript.workspaceToCode(workspace);
                  window.flutter_inappwebview.callHandler('onCodeGenerated', code);
                } catch (e) {
                  console.error('Error generating code:', e);
                  window.flutter_inappwebview.callHandler('onError', e.toString());
                }
              }, $_debounceDelay);
            }
          });

          // Handle window resize
          window.addEventListener('resize', function() {
            if (workspace) {
              Blockly.svgResize(workspace);
            }
          });

          // Notify Flutter that Blockly is ready
          window.flutter_inappwebview.callHandler('blocklyReady');
        } catch (error) {
          console.error('Error initializing Blockly:', error);
          window.flutter_inappwebview.callHandler('onError', error.toString());
        }
      });
    ''';
  }

  Future<void> _handleLoadStop(
      InAppWebViewController controller, Uri? url) async {
    if (!isWebViewReady) {
      isWebViewReady = true;
      _setupJavaScriptHandlers(controller);
    }
  }

  void _setupJavaScriptHandlers(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'onCodeGenerated',
      callback: (List<dynamic> args) {
        if (args.isNotEmpty) {
          widget.onCodeGenerated(args[0].toString());
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onError',
      callback: (List<dynamic> args) {
        if (args.isNotEmpty) {
          _showErrorSnackBar(args[0].toString());
        }
      },
    );
  }

  void _handleConsoleMessage(
      InAppWebViewController controller, ConsoleMessage consoleMessage) {
    debugPrint('WebView console: ${consoleMessage.message}');
  }

  void _handleLoadError(
      InAppWebViewController controller, Uri? url, int code, String message) {
    _showErrorSnackBar('Error loading Blockly: $message');
  }

  void _handleReceivedError(InAppWebViewController controller,
      WebResourceRequest request, WebResourceError error) {
    _showErrorSnackBar('Resource error: ${error.description}');
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }
}
