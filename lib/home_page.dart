// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import 'dart:io' show Platform;
// import 'package:flutter/services.dart';
// import 'package:beacons_plugin/beacons_plugin.dart';
// import 'DiscoveryPage.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class MyHomePage extends StatefulWidget {
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//   new FlutterLocalNotificationsPlugin();
//   final StreamController<String> beaconEventsController =
//       StreamController<String>.broadcast();
//   String _beaconResult = 'Not Scanned Yet.';
//   int _nrMessagesReceived = 0;
//   var isRunning = false;
//   List<String> _results = [];
//   bool _isInForeground = true;
//   String _tag = "Beacons Plugin";
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     BeaconsPlugin.listenToBeacons(beaconEventsController);
//     beaconEventsController.stream.listen(
//         (data) {
//           print("Hello");
//           if (data.isNotEmpty) {
//             setState(() {
//               _beaconResult = data;
//             });
//             print("Beacons DataReceived: " + data);
//           }
//         },
//         onDone: () {},
//         onError: (error) {
//           print("Error: $error");
//         });
//   }
//
//   Future<void> initPlatformState() async {
//     if (Platform.isAndroid) {
//       //Prominent disclosure
//       await BeaconsPlugin.setDisclosureDialogMessage(
//           title: "Background Locations",
//           message:
//           "[This app] collects location data to enable [feature], [feature], & [feature] even when the app is closed or not in use");
//
//       //Only in case, you want the dialog to be shown again. By Default, dialog will never be shown if permissions are granted.
//       //await BeaconsPlugin.clearDisclosureDialogShowFlag(false);
//     }
//
//     if (Platform.isAndroid) {
//       BeaconsPlugin.channel.setMethodCallHandler((call) async {
//         print("Method: ${call.method}");
//         if (call.method == 'scannerReady') {
//           _showNotification("Beacons monitoring started..");
//           await BeaconsPlugin.startMonitoring();
//           setState(() {
//             isRunning = true;
//           });
//         } else if (call.method == 'isPermissionDialogShown') {
//           _showNotification(
//               "Prominent disclosure message is shown to the user!");
//         }
//       });
//     } else if (Platform.isIOS) {
//       _showNotification("Beacons monitoring started..");
//       await BeaconsPlugin.startMonitoring();
//       setState(() {
//         isRunning = true;
//       });
//     }
//
//     BeaconsPlugin.listenToBeacons(beaconEventsController);
//
//     await BeaconsPlugin.addRegion(
//         "BeaconType1", "909c3cf9-fc5c-4841-b695-380958a51a5a");
//     await BeaconsPlugin.addRegion(
//         "BeaconType2", "6a84c716-0f2a-1ce9-f210-6a63bd873dd9");
//
//     BeaconsPlugin.addBeaconLayoutForAndroid(
//         "m:2-3=beac,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25");
//     BeaconsPlugin.addBeaconLayoutForAndroid(
//         "m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24");
//
//     BeaconsPlugin.setForegroundScanPeriodForAndroid(
//         foregroundScanPeriod: 2200, foregroundBetweenScanPeriod: 10);
//
//     BeaconsPlugin.setBackgroundScanPeriodForAndroid(
//         backgroundScanPeriod: 2200, backgroundBetweenScanPeriod: 10);
//
//     beaconEventsController.stream.listen(
//             (data) {
//           if (data.isNotEmpty && isRunning) {
//             setState(() {
//               _beaconResult = data;
//               _results.add(_beaconResult);
//               _nrMessagesReceived++;
//             });
//
//             if (!_isInForeground) {
//               _showNotification("Beacons DataReceived: " + data);
//             }
//
//             print("Beacons DataReceived: " + data);
//           }
//         },
//         onDone: () {},
//         onError: (error) {
//           print("Error: $error");
//         });
//
//     //Send 'true' to run in background
//     await BeaconsPlugin.runInBackground(true);
//
//     if (!mounted) return;
//   }
//
//   void _showNotification(String subtitle) {
//     var rng = new Random();
//     Future.delayed(Duration(seconds: 5)).then((result) async {
//       var androidPlatformChannelSpecifics = AndroidNotificationDetails(
//           'your channel id', 'your channel name',
//           importance: Importance.high,
//           priority: Priority.high,
//           ticker: 'ticker');
//       var iOSPlatformChannelSpecifics = IOSNotificationDetails();
//       var platformChannelSpecifics = NotificationDetails(
//           android: androidPlatformChannelSpecifics,
//           iOS: iOSPlatformChannelSpecifics);
//       await flutterLocalNotificationsPlugin.show(
//           rng.nextInt(100000), _tag, subtitle, platformChannelSpecifics,
//           payload: 'item x');
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Text("Hi");
//   }
// }
//
// // class _MyHomePageState extends State<MyHomePage> {
// //   BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
// //   String _address = "...";
// //   String _name = "...";
// //   Timer? _discoverableTimeoutTimer;
// //   int _discoverableTimeoutSecondsLeft = 0;
// //   @override
// //   void initState() {
// //     super.initState();
//
// //     // Get current state
// //     FlutterBluetoothSerial.instance.state.then((state) {
// //       setState(() {
// //         _bluetoothState = state;
// //       });
// //     });
//
// //     Future.doWhile(() async {
// //       // Wait if adapter not enabled
// //       if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
// //         return false;
// //       }
// //       await Future.delayed(const Duration(milliseconds: 0xDD));
// //       return true;
// //     }).then((_) {
// //       // Update the address field
// //       FlutterBluetoothSerial.instance.address.then((address) {
// //         setState(() {
// //           _address = address!;
// //         });
// //       });
// //     });
//
// //     FlutterBluetoothSerial.instance.name.then((name) {
// //       setState(() {
// //         _name = name!;
// //       });
// //     });
//
// //     // Listen for futher state changes
// //     FlutterBluetoothSerial.instance
// //         .onStateChanged()
// //         .listen((BluetoothState state) {
// //       setState(() {
// //         _bluetoothState = state;
// //       });
// //     });
// //   }
//
// //   @override
// //   void dispose() {
// //     FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
// //     super.dispose();
// //   }
//
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Flutter Bluetooth Serial'),
// //       ),
// //       body: Container(
// //         child: ListView(
// //           children: <Widget>[
// //             Divider(),
// //             ListTile(title: const Text('General')),
// //             SwitchListTile(
// //               title: const Text('Enable Bluetooth'),
// //               value: _bluetoothState.isEnabled,
// //               onChanged: (bool value) {
// //                 // Do the request and update with the true value then
// //                 future() async {
// //                   // async lambda seems to not working
// //                   if (value)
// //                     await FlutterBluetoothSerial.instance.requestEnable();
// //                   else
// //                     await FlutterBluetoothSerial.instance.requestDisable();
// //                 }
//
// //                 future().then((_) {
// //                   setState(() {});
// //                 });
// //               },
// //             ),
// //             ListTile(
// //               title: const Text('Bluetooth status'),
// //               subtitle: Text(_bluetoothState.toString()),
// //               trailing: ElevatedButton(
// //                 child: const Text('Settings'),
// //                 onPressed: () {
// //                   FlutterBluetoothSerial.instance.openSettings();
// //                 },
// //               ),
// //             ),
// //             ListTile(
// //               title: const Text('Local adapter address'),
// //               subtitle: Text(_address),
// //             ),
// //             ListTile(
// //               title: const Text('Local adapter name'),
// //               subtitle: Text(_name),
// //               onLongPress: null,
// //             ),
// //             Divider(),
// //             ListTile(
// //               title: ElevatedButton(
// //                   child: const Text('Explore discovered devices'),
// //                   onPressed: () async {
// //                     final BluetoothDevice? selectedDevice =
// //                         await Navigator.of(context).push(
// //                       MaterialPageRoute(
// //                         builder: (context) {
// //                           return DiscoveryPage();
// //                         },
// //                       ),
// //                     );
//
// //                     if (selectedDevice != null) {
// //                       print('Discovery -> selected ' + selectedDevice.address);
// //                     } else {
// //                       print('Discovery -> no device selected');
// //                     }
// //                   }),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
