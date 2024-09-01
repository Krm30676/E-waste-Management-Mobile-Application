import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart'as myAuth;
import 'screens/splash_screen.dart'; 
import 'screens/home_page.dart';
//import 'screens/profile_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => myAuth.AuthProvider(),
      child: MaterialApp(
        title: 'E-waste Management App',
        theme: ThemeData(
          primarySwatch: Colors.lightGreen,
          scaffoldBackgroundColor: Colors.white,
        ),
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}
