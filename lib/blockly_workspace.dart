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

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid && !Platform.isIOS) {
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

    return InAppWebView(
      key: webViewKey,
      initialSettings: InAppWebViewSettings(
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
      ),
      onWebViewCreated: (InAppWebViewController controller) {
        _controller = controller;
        controller.loadData(
          data: '''
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
              <title>Blockly</title>
              <script src="https://unpkg.com/blockly/blockly.min.js"></script>
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
              <xml id="toolbox" style="display: none">
                <category name="Movement" colour="210">
                  <block type="move_forward"></block>
                  <block type="move_backward"></block>
                  <block type="turn_left"></block>
                  <block type="turn_right"></block>
                </category>
                <category name="Control" colour="120">
                  <block type="wait"></block>
                  <block type="repeat"></block>
                  <block type="if_then"></block>
                </category>
                <category name="Sensors" colour="160">
                  <block type="distance_sensor"></block>
                </category>
                <category name="Gripper" colour="230">
                  <block type="gripper_open"></block>
                  <block type="gripper_close"></block>
                </category>
                <category name="Auto" colour="290">
                  <block type="auto_mode"></block>
                </category>
              </xml>
            </body>
            </html>
          ''',
          mimeType: 'text/html',
          encoding: 'utf-8',
          baseUrl: WebUri('about:blank'),
        );
      },
      onLoadStop: (InAppWebViewController controller, Uri? url) async {
        if (!isWebViewReady) {
          isWebViewReady = true;
          await controller.evaluateJavascript(source: '''
            try {
              // Define custom blocks
              Blockly.Blocks['move_forward'] = {
                init: function() {
                  this.appendDummyInput()
                      .appendField("Move Forward");
                  this.setPreviousStatement(true, null);
                  this.setNextStatement(true, null);
                  this.setColour(210);
                }
              };

              Blockly.Blocks['move_backward'] = {
                init: function() {
                  this.appendDummyInput()
                      .appendField("Move Backward");
                  this.setPreviousStatement(true, null);
                  this.setNextStatement(true, null);
                  this.setColour(210);
                }
              };

              Blockly.Blocks['turn_left'] = {
                init: function() {
                  this.appendDummyInput()
                      .appendField("Turn Left");
                  this.setPreviousStatement(true, null);
                  this.setNextStatement(true, null);
                  this.setColour(210);
                }
              };

              Blockly.Blocks['turn_right'] = {
                init: function() {
                  this.appendDummyInput()
                      .appendField("Turn Right");
                  this.setPreviousStatement(true, null);
                  this.setNextStatement(true, null);
                  this.setColour(210);
                }
              };

              Blockly.Blocks['wait'] = {
                init: function() {
                  this.appendValueInput("DURATION")
                      .setCheck("Number")
                      .appendField("Wait");
                  this.appendDummyInput()
                      .appendField("seconds");
                  this.setPreviousStatement(true, null);
                  this.setNextStatement(true, null);
                  this.setColour(120);
                }
              };

              Blockly.Blocks['repeat'] = {
                init: function() {
                  this.appendValueInput("TIMES")
                      .setCheck("Number")
                      .appendField("Repeat");
                  this.appendDummyInput()
                      .appendField("times");
                  this.appendStatementInput("DO")
                      .appendField("do");
                  this.setPreviousStatement(true, null);
                  this.setNextStatement(true, null);
                  this.setColour(120);
                }
              };

              Blockly.Blocks['if_then'] = {
                init: function() {
                  this.appendValueInput("CONDITION")
                      .setCheck("Boolean")
                      .appendField("if");
                  this.appendStatementInput("DO")
                      .appendField("then");
                  this.setPreviousStatement(true, null);
                  this.setNextStatement(true, null);
                  this.setColour(120);
                }
              };

              Blockly.Blocks['distance_sensor'] = {
                init: function() {
                  this.appendDummyInput()
                      .appendField("Distance Sensor");
                  this.setOutput(true, "Number");
                  this.setColour(160);
                }
              };

              Blockly.Blocks['gripper_open'] = {
                init: function() {
                  this.appendDummyInput()
                      .appendField("Open Gripper");
                  this.setPreviousStatement(true, null);
                  this.setNextStatement(true, null);
                  this.setColour(230);
                }
              };

              Blockly.Blocks['gripper_close'] = {
                init: function() {
                  this.appendDummyInput()
                      .appendField("Close Gripper");
                  this.setPreviousStatement(true, null);
                  this.setNextStatement(true, null);
                  this.setColour(230);
                }
              };

              Blockly.Blocks['auto_mode'] = {
                init: function() {
                  this.appendDummyInput()
                      .appendField("Auto Mode");
                  this.setPreviousStatement(true, null);
                  this.setNextStatement(true, null);
                  this.setColour(290);
                }
              };

              // Define JavaScript generators for custom blocks
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

              Blockly.JavaScript['gripper_open'] = function(block) {
                return 'sendCommand("O");\\n';
              };

              Blockly.JavaScript['gripper_close'] = function(block) {
                return 'sendCommand("C");\\n';
              };

              Blockly.JavaScript['auto_mode'] = function(block) {
                return 'sendCommand("A");\\n';
              };

              // Initialize Blockly workspace with optimized settings
              var workspace = Blockly.inject('blocklyDiv', {
                toolbox: document.getElementById('toolbox'),
                scrollbars: true,
                trashcan: true,
                zoom: {
                  controls: true,
                  wheel: true,
                  startScale: 1.0,
                  maxScale: 3,
                  minScale: 0.3,
                  scaleSpeed: 1.2,
                  pinch: true
                },
                move: {
                  scrollbars: {
                    horizontal: true,
                    vertical: true
                  },
                  drag: true,
                  wheel: true
                },
                grid: {
                  spacing: 20,
                  length: 3,
                  colour: '#ccc',
                  snap: true
                }
              });
              
              // Add available blocks
              ${widget.availableBlocks.map((block) => '''
                try {
                  workspace.newBlock('$block');
                } catch (e) {
                  console.error('Error adding block $block:', e);
                }
              ''').join('\n')}
              
              // Optimize event handling
              var debounceTimer;
              workspace.addChangeListener(function(event) {
                if (event.type == Blockly.Events.BLOCK_CHANGE ||
                    event.type == Blockly.Events.BLOCK_CREATE ||
                    event.type == Blockly.Events.BLOCK_DELETE ||
                    event.type == Blockly.Events.BLOCK_MOVE) {
                  clearTimeout(debounceTimer);
                  debounceTimer = setTimeout(function() {
                    try {
                      var code = Blockly.JavaScript.workspaceToCode(workspace);
                      window.flutter_inappwebview.callHandler('onCodeGenerated', code);
                    } catch (e) {
                      console.error('Error generating code:', e);
                      window.flutter_inappwebview.callHandler('onError', e.toString());
                    }
                  }, 300);
                }
              });

              // Handle workspace resize
              window.addEventListener('resize', function() {
                Blockly.svgResize(workspace);
              });
            } catch (e) {
              console.error('Error initializing Blockly:', e);
              window.flutter_inappwebview.callHandler('onError', e.toString());
            }
          ''');

          // Add handlers
          controller.addJavaScriptHandler(
            handlerName: 'onCodeGenerated',
            callback: (args) {
              if (args.isNotEmpty) {
                widget.onCodeGenerated(args[0].toString());
              }
            },
          );

          controller.addJavaScriptHandler(
            handlerName: 'onError',
            callback: (args) {
              if (args.isNotEmpty) {
                debugPrint('Blockly error: ${args[0]}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${args[0]}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          );
        }
      },
      onConsoleMessage:
          (InAppWebViewController controller, ConsoleMessage consoleMessage) {
        debugPrint('WebView console: ${consoleMessage.message}');
      },
      onLoadError: (InAppWebViewController controller, Uri? url, int code,
          String message) {
        debugPrint('WebView error: $message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WebView error: $message'),
            backgroundColor: Colors.red,
          ),
        );
      },
      onReceivedError: (InAppWebViewController controller,
          WebResourceRequest request, WebResourceError error) {
        debugPrint('WebView resource error: ${error.description}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resource error: ${error.description}'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }
}
