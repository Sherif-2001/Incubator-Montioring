import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:audioplayers/audioplayers.dart';
import 'MainPage.dart';
import 'main.dart';

AudioCache audioCache = AudioCache();
AudioPlayer audioPlayer = AudioPlayer();
var theicon;
var theColor;

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  BluetoothConnection connection;

  List<_Message> messages = List<_Message>();
  String _messageBuffer = '';

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();
    audioCache = AudioCache(fixedPlayer: audioPlayer);

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
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

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List list = messages.map((_message) {
      return Container(
        child: Text(
            (text) {
              return text;
            }(_message.text.trim()),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: theColor, fontSize: 30, fontWeight: FontWeight.bold)),
        width: MediaQuery.of(context).size.width,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () {
                  SettingsDialog(context);
                },
                icon: Icon(Icons.settings))
          ],
          backgroundColor: Colors.pink[400],
          title: (isConnecting
              ? Text(
                  'Please Wait....',
                  style: TextStyle(fontFamily: 'Baby', fontSize: 25),
                )
              : isConnected
                  ? Text('Incubator Parameters',
                      style: TextStyle(fontFamily: 'Baby', fontSize: 25))
                  : Text('Disconnected',
                      style: TextStyle(fontFamily: 'Baby', fontSize: 25)))),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          list.isNotEmpty ? list.first : Container(),
          SizedBox(height: 50),
          Icon(theicon, size: 150, color: theColor)
        ],
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
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
        messages.clear();
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
        if (messages[0].text.contains('open')) {
          messages[0].text.contains("bed") ? messages[0].text = "" : null;
          audioCache.play("door.mp3");
          theicon = Icons.door_back_door_outlined;
          theColor = Colors.black;
        } else if (messages[0].text.contains('Check baby')) {
          messages[0].text.contains("bed") ? messages[0].text = "" : null;
          audioCache.play("temp.mp3");
          theicon = Icons.thermostat;
          theColor = Colors.red;
        } else if (messages[0].text.contains('Light')) {
          messages[0].text.contains("bed") ? messages[0].text = "" : null;
          audioCache.play("light.mp3");
          theicon = Icons.light;
          theColor = Colors.yellow[700];
        } else if (messages[0].text.contains('empty')) {
          messages[0].text.contains("bed") ? messages[0].text = "" : null;
          audioCache.play("position.mp3");
          theicon = Icons.face_rounded;
          theColor = Colors.lightBlue;
        } else {
          audioPlayer.stop();
          theicon = Icons.bedroom_baby;
          theColor = Colors.pink;
        }
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }
}
