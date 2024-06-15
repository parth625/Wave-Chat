import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_notification_channel/flutter_notification_channel.dart';
import 'package:flutter_notification_channel/notification_importance.dart';
import 'package:wave_chat/api/apis.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //To enter full screen in splash screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color.fromRGBO(89, 213, 224, 1.0),
  ));

  //for setting orientation to only portrait
  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((value) async {
    await _initializeFirebase(); // Wait for Firebase initialization
    runApp(const WaveChat());
  });
}

//Global Media Query object to access Screen Size
late Size mq;

class WaveChat extends StatelessWidget {
  const WaveChat({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wave Chat',
      theme: ThemeData(
          //Universal Theme for AppBar
          primaryColor: const Color.fromRGBO(89, 213, 224, 1.0),
          appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Color.fromRGBO(
                    89, 213, 224, 1.0), // Set your desired color here
              ),
              titleTextStyle: TextStyle(
                  fontSize: 21,
                  color: Colors.black,
                  fontWeight: FontWeight.w500),
              elevation: 0,
              centerTitle: true,
              backgroundColor: Color.fromRGBO(89, 213, 224, 1.0))),
      home: const SplashScreen(),
    );
  }
}

//For initializing firebase with project
Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    // Now that Firebase is initialized, call getSelfInfo()
    await APIs.getSelfInfo();
  } catch (e) {
    log("GetSelfInfo: $e");
  }

  //For creating a notification channel
  var result = await FlutterNotificationChannel().registerNotificationChannel(
    description: 'For Showing Message Notification',
    id: 'chats',
    importance: NotificationImportance.IMPORTANCE_HIGH,
    name: 'Chats',
  );
  log('Notification channel result: $result');
}
