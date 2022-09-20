import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:beacons_plugin/beacons_plugin.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_blue/flutter_blue.dart';
// import 'package:flutter_blue/gen/flutterblue.pb.dart' as proto;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

enum DeviceBtType { LE, CLASSIC, DUAL, UNKNOWN }

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  BluetoothConnection? connection;
  final String _tag = "Beacons Plugin";
  String _beaconResult = 'Not Scanned Yet.';
  int _nrMessagesReceived = 0;
  var isRunning = false;
  final List<String> _results = [];
  final List<String> _resultsItem = [];
  bool _isInForeground = true;
  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  final ScrollController _scrollController = ScrollController();

  final StreamController<String> beaconEventsController =
      StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isInForeground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    beaconEventsController.close();
    WidgetsBinding.instance.removeObserver(this);
    connection?.dispose();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (Platform.isAndroid) {
      await BeaconsPlugin.setDisclosureDialogMessage(
          title: "Background Locations",
          message:
              "[This app] collects location data to enable [feature], [feature], & [feature] even when the app is closed or not in use");
    }

    if (Platform.isAndroid) {
      BeaconsPlugin.channel.setMethodCallHandler((call) async {
        print("Method: ${call.method}");
        if (call.method == 'scannerReady') {
          await BeaconsPlugin.startMonitoring();
          setState(() {
            isRunning = true;
          });
        }
      });
    }

    BeaconsPlugin.listenToBeacons(beaconEventsController);

    await BeaconsPlugin.addRegion(
        "BeaconType1", "909c3cf9-fc5c-4841-b695-380958a51a5a");
    await BeaconsPlugin.addRegion(
        "BeaconType2", "6a84c716-0f2a-1ce9-f210-6a63bd873dd9");

    BeaconsPlugin.addBeaconLayoutForAndroid(
        "m:2-3=beac,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25");
    BeaconsPlugin.addBeaconLayoutForAndroid(
        "m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24");

    BeaconsPlugin.setForegroundScanPeriodForAndroid(
        foregroundScanPeriod: 2200, foregroundBetweenScanPeriod: 10);

    BeaconsPlugin.setBackgroundScanPeriodForAndroid(
        backgroundScanPeriod: 2200, backgroundBetweenScanPeriod: 10);

    beaconEventsController.stream.listen(
        (data) {
          if (data.isNotEmpty && isRunning) {
            var items = json.decode(data);
            String getUuid = items["uuid"];
            String sliceGetUuid = getUuid.substring(0, 13).replaceAll('-', '');
            String resultant = '';
            for (int i = 0; i < sliceGetUuid.length; i++) {
              if (i % 2 == 0 && i != 0) {
                resultant += ':${sliceGetUuid[i]}';
              } else {
                resultant += sliceGetUuid[i];
              }
            }
            if (!_results.contains(resultant)) {
              setState(() {
                _beaconResult = data;
                _results.add(resultant);
                _nrMessagesReceived++;
              });

              if (!_isInForeground) {
                print("Beacons DataReceived1: " + data);
              }

              print("Beacons DataReceived: " + data);
            }
          }
        },
        onDone: () {},
        onError: (error) {
          print("Error: $error");
        });

    //Send 'true' to run in background
    await BeaconsPlugin.runInBackground(true);

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Monitoring Beacons'),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                  child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Total Results: $_nrMessagesReceived',
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF22369C),
                          fontWeight: FontWeight.bold,
                        )),
              )),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (isRunning) {
                      await BeaconsPlugin.stopMonitoring();
                    } else {
                      initPlatformState();
                      await BeaconsPlugin.startMonitoring();
                    }
                    setState(() {
                      isRunning = !isRunning;
                    });
                  },
                  child: Text(isRunning ? 'Stop Scanning' : 'Start Scanning',
                      style: TextStyle(fontSize: 20)),
                ),
              ),
              Visibility(
                visible: _results.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _nrMessagesReceived = 0;
                        _results.clear();
                      });
                    },
                    child:
                        Text("Clear Results", style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              Expanded(child: _buildResultsList())
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Scrollbar(
      thumbVisibility: true,
      controller: _scrollController,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: ScrollPhysics(),
        controller: _scrollController,
        itemCount: _results.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          height: 1,
          color: Colors.black,
        ),
        itemBuilder: (context, index) {
          print(context);
          final item = ListTile(
              title: Text(
                "Device ${index + 1}\n${_results[index]}",
                textAlign: TextAlign.justify,
                style: Theme.of(context).textTheme.headline4?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF1A1B26),
                      fontWeight: FontWeight.normal,
                    ),
              ),
              onTap: () {
                _beaconPushed(_results[index]);
              });
          return item;
        },
      ),
    );
  }

  // BluetoothDevice createBluetoothDevice(
  //     String deviceName, String deviceIdentifier, DeviceBtType deviceType) {
  //   proto.BluetoothDevice p = proto.BluetoothDevice.create();
  //   p.name = deviceName;
  //   p.remoteId = deviceIdentifier;
  //
  //   if (deviceType == DeviceBtType.LE) {
  //     p.type = proto.BluetoothDevice_Type.LE;
  //   } else if (deviceType == DeviceBtType.CLASSIC) {
  //     p.type = proto.BluetoothDevice_Type.CLASSIC;
  //   } else if (deviceType == DeviceBtType.DUAL) {
  //     p.type = proto.BluetoothDevice_Type.DUAL;
  //   } else {
  //     p.type = proto.BluetoothDevice_Type.UNKNOWN;
  //   }
  //   return BluetoothDevice.fromProto(p);
  // }

  _beaconPushed(String result) async{
    // BluetoothDevice myDevice =
    //     createBluetoothDevice("raspberrypi", "B8:27:EB:2C:E4:7D", DeviceBtType.LE);
    // print('myDevice' + myDevice.toString());
    // await myDevice.connect();
    // print('myDevice here');
    // List<BluetoothService> services = await myDevice.discoverServices();
    // services.forEach((service) {
    //   print(service);
    // });
    print('result' + result);
    BluetoothConnection.toAddress(result.toUpperCase()).then((_connection) {
      connection = _connection;
      print('connected to the device');
      connection!.output.add(ascii.encode("HI"));
      connection!.input!.listen((data) {
        // String s = String.fromCharCodes(data);
        // print('x:' + s);
        // Allocate buffer for parsed data
        int backspacesCounter = 0;
        data.forEach((byte) {
          if (byte == 8 || byte == 127) {
            backspacesCounter++;
          }
        });
        Uint8List buffer = Uint8List(data.length - backspacesCounter);
        int bufferIndex = buffer.length;

        // Apply backspace control character
        backspacesCounter = 0;
        for (int i = data.length - 1; i >= 0; i--) {
          if (data[i] == 8 || data[i] == 127) {
            backspacesCounter++;
          } else {
            if (backspacesCounter > 0) {
              backspacesCounter--;
            } else {
              buffer[--bufferIndex] = data[i];
            }
          }
        }

        // Create message if there is new line character
        String dataString = String.fromCharCodes(buffer);
        int index = buffer.indexOf(13);
        if (~index != 0) {
          setState(() {
            // messages.add(
            //   _Message(
            //     1,
            //     backspacesCounter > 0
            //         ? _messageBuffer.substring(
            //         0, _messageBuffer.length - backspacesCounter)
            //         : _messageBuffer + dataString.substring(0, index),
            //   ),
            // );

            _messageBuffer = dataString.substring(index);
          });
        } else {
          _messageBuffer = (backspacesCounter > 0
              ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
              : _messageBuffer + dataString);
        }
        print('x:' + _messageBuffer);
      });
    });
  }
}
