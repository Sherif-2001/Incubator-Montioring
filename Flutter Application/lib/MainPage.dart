import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_app/communication.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import './SelectBondedDevicePage.dart';
import './ChatPage.dart';
import 'main.dart';

  var isPlayed = true;

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name;
      });
    });

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  void SettingsDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => SimpleDialog(
              titleTextStyle: TextStyle(
                  color: Colors.white, fontSize: 40, fontFamily: "Baby"),
              title: Center(
                child: Text('Settings'),
              ),
              backgroundColor: Colors.black54,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              children: [
                Divider(color: Colors.white, thickness: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Music',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontFamily: 'Baby')),
                    IconButton(
                        onPressed: () => {
                              Navigator.pop(context),
                              isPlayed
                                  ? {
                                      mainAudioPlayer.setVolume(0),
                                      isPlayed = false
                                    }
                                  : {
                                      mainAudioPlayer.setVolume(1),
                                      isPlayed = true
                                    },
                            },
                        icon: Icon(
                          isPlayed ? Icons.headset : Icons.headset_off,
                          color: Colors.white,
                          size: 30,
                        ))
                  ],
                )
              ],
            ));
  }

  // This code is just a example if you need to change page and you need to communicate to the raspberry again
  void init() async {
    Communication com = Communication();
    await com.connectBl(_address);
    com.sendMessage("Hello");
    setState(() {});
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () {
                  SettingsDialog(context);
                },
                icon: Icon(Icons.settings))
          ],
          title: Text(
            'INCUBATOR SYSTEM',
            style: TextStyle(fontSize: 30, fontFamily: 'Baby'),
          ),
          centerTitle: true,
          backgroundColor: Colors.pink[400],
        ),
        body: Container(
          color: Colors.white,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image(image: AssetImage("assets/icon.png")),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              textStyle: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Baby'),
                              primary: Colors.pink[400],
                              padding: EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                          onPressed: () async {
                            if (await FlutterBluetoothSerial
                                    .instance.isEnabled !=
                                false) {
                              final BluetoothDevice selectedDevice =
                                  await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) {
                                    return SelectBondedDevicePage(
                                        checkAvailability: false);
                                  },
                                ),
                              );

                              if (selectedDevice != null) {
                                print('Connect -> selected ' +
                                    selectedDevice.address);
                                _startChat(context, selectedDevice);
                              } else {
                                print('Connect -> no device selected');
                              }
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('Bluetooth is off',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 30, fontFamily: 'Baby')),
                                duration: Duration(seconds: 3),
                                behavior: SnackBarBehavior.fixed,
                                backgroundColor: Colors.grey[600],
                                // shape: StadiumBorder(),
                              ));
                            }
                          },
                          child: Text('Connect to Arduino')),
                      SizedBox(),
                      ElevatedButton(
                        onPressed: () {
                          SystemNavigator.pop();
                        },
                        child: Text('Exit'),
                        style: ElevatedButton.styleFrom(
                            textStyle: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Baby'),
                            primary: Colors.pink[400],
                            padding: EdgeInsets.symmetric(
                                vertical: 20, horizontal: 40),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20))),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server);
        },
      ),
    );
  }
}
