import 'package:flutter/material.dart';
import 'MainPage.dart';
import 'package:audioplayers/audioplayers.dart';

AudioCache mainAudioCache = AudioCache();
AudioCache musicAudioCache = AudioCache();
AudioPlayer mainAudioPlayer = AudioPlayer();

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    musicAudioCache = AudioCache(fixedPlayer: mainAudioPlayer);
    mainAudioCache.play('giggling.mp3');
    musicAudioCache.loop("music.mp3");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }
}
