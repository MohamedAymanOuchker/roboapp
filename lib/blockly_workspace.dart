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

    return WillPopScope(
      onWillPop: () async {
        if (_controller != null) {
          await _controller!.clearCache();
          await _controller!.clearHistory();
        }
        return true;
      },
      child: InAppWebView(
        key: webViewKey,
        initialSettings: _getWebViewSettings(),
        onWebViewCreated: _handleWebViewCreated,
        onLoadStop: _handleLoadStop,
        onConsoleMessage: _handleConsoleMessage,
        onLoadError: _handleLoadError,
        onReceivedError: _handleReceivedError,
        gestureRecognizers: const {},
      ),
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
      cacheEnabled: false,
      clearCache: true,
      hardwareAcceleration: true,
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
      historyUrl: null,
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
          // Initialize when the document is fully loaded
          window.addEventListener('load', function() {
            try {
              // Clear any existing registrations
              if (window.Blockly) {
                // Clear existing block definitions
                Object.keys(Blockly.Blocks).forEach(key => {
                  if (key.startsWith('move_') || key === 'wait' || key === 'repeat' || 
                      key === 'if_then' || key === 'distance_sensor' || key === 'auto_mode') {
                    delete Blockly.Blocks[key];
                  }
                });

                // Clear existing generators
                if (Blockly.JavaScript) {
                  Object.keys(Blockly.JavaScript).forEach(key => {
                    if (key.startsWith('move_') || key === 'wait' || key === 'repeat' || 
                        key === 'if_then' || key === 'distance_sensor' || key === 'auto_mode') {
                      delete Blockly.JavaScript[key];
                    }
                  });
                }

                // Clear any existing extensions
                if (Blockly.Extensions && Blockly.Extensions.ALL_) {
                  Object.keys(Blockly.Extensions.ALL_).forEach(key => {
                    if (key === 'contextMenu_variableDynamicSetterGetter') {
                      delete Blockly.Extensions.ALL_[key];
                    }
                  });
                }
              }

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
                Blockly.Blocks[type] = definition;
              });

              // Initialize JavaScript generator
              if (!Blockly.JavaScript) {
                Blockly.JavaScript = new Blockly.Generator('JavaScript');
              }

              Blockly.JavaScript.ORDER_ATOMIC = 0;
              Blockly.JavaScript.ORDER_NONE = 99;

              // Define JavaScript generators directly
              Blockly.JavaScript['move_forward'] = function(block) {
                return 'sendCommand("F1000");\\n';
              };

              Blockly.JavaScript['move_backward'] = function(block) {
                return 'sendCommand("B1000");\\n';
              };

              Blockly.JavaScript['turn_left'] = function(block) {
                return 'sendCommand("L90");\\n';
              };

              Blockly.JavaScript['turn_right'] = function(block) {
                return 'sendCommand("R90");\\n';
              };

              Blockly.JavaScript['wait'] = function(block) {
                var duration = Blockly.JavaScript.valueToCode(block, 'DURATION', Blockly.JavaScript.ORDER_ATOMIC) || '0';
                return 'wait(' + duration + ');\\n';
              };

              Blockly.JavaScript['repeat'] = function(block) {
                var times = Blockly.JavaScript.valueToCode(block, 'TIMES', Blockly.JavaScript.ORDER_ATOMIC) || '0';
                var branch = Blockly.JavaScript.statementToCode(block, 'DO');
                return 'for (let i = 0; i < ' + times + '; i++) {\\n' + branch + '}\\n';
              };

              Blockly.JavaScript['if_then'] = function(block) {
                var condition = Blockly.JavaScript.valueToCode(block, 'CONDITION', Blockly.JavaScript.ORDER_ATOMIC) || 'false';
                var branch = Blockly.JavaScript.statementToCode(block, 'DO');
                return 'if (' + condition + ') {\\n' + branch + '}\\n';
              };

              Blockly.JavaScript['distance_sensor'] = function(block) {
                return ['getDistance()', Blockly.JavaScript.ORDER_ATOMIC];
              };

              Blockly.JavaScript['auto_mode'] = function(block) {
                return 'sendCommand("A");\\n';
              };

              // Create toolbox based on available blocks
              const availableBlocks = ${widget.availableBlocks};
              const toolbox = {
                kind: 'categoryToolbox',
                contents: [
                  {
                    kind: 'category',
                    name: 'Movement',
                    colour: 210,
                    contents: availableBlocks.filter(block => 
                      block.startsWith('move_') || block === 'turn_left' || block === 'turn_right'
                    ).map(block => ({ kind: 'block', type: block }))
                  },
                  {
                    kind: 'category',
                    name: 'Control',
                    colour: 120,
                    contents: availableBlocks.filter(block => 
                      block === 'wait' || block === 'repeat' || block === 'if_then'
                    ).map(block => ({ kind: 'block', type: block }))
                  },
                  {
                    kind: 'category',
                    name: 'Sensors',
                    colour: 160,
                    contents: availableBlocks.filter(block => 
                      block === 'distance_sensor'
                    ).map(block => ({ kind: 'block', type: block }))
                  },
                  {
                    kind: 'category',
                    name: 'Modes',
                    colour: 290,
                    contents: availableBlocks.filter(block => 
                      block === 'auto_mode'
                    ).map(block => ({ kind: 'block', type: block }))
                  }
                ].filter(category => category.contents.length > 0)
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
                      console.log('Generating code for block type:', event.blockId ? workspace.getBlockById(event.blockId).type : 'unknown');
                      const code = Blockly.JavaScript.workspaceToCode(workspace);
                      console.log('Generated code:', code);
                      window.flutter_inappwebview.callHandler('onCodeGenerated', code);
                    } catch (e) {
                      console.error('Error generating code:', e);
                      console.error('Stack trace:', e.stack);
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
        </script>
      </body>
      </html>
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
    if (_controller != null) {
      _controller!.clearCache();
      _controller!.clearHistory();
    }
    _controller = null;
    super.dispose();
  }
}
