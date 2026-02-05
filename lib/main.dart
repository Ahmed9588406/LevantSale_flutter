import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'onboarding/onboarding_screen.dart';
import 'sign_in/sign_in_screen.dart';
import 'home/home_screen.dart';
import 'services/session_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notifications/notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: 'assets/.env');

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  // Initialize notifications and register background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationsService.initialize();

  // Check for existing session
  bool hasSession = false;
  if (onboardingComplete) {
    hasSession = await SessionService.hasValidSession();
  }

  runApp(MyApp(showOnboarding: !onboardingComplete, hasSession: hasSession));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  final bool hasSession;

  const MyApp({
    super.key,
    required this.showOnboarding,
    this.hasSession = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leventsale',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1DAF52)),
        textTheme: GoogleFonts.rubikTextTheme(Theme.of(context).textTheme),
        fontFamily: GoogleFonts.rubik().fontFamily,
      ),
      home: showOnboarding
          ? const OnboardingScreen()
          : hasSession
          ? const SplashAutoLoginScreen()
          : const SignInScreen(),
    );
  }
}

/// Splash screen that handles auto-login
class SplashAutoLoginScreen extends StatefulWidget {
  const SplashAutoLoginScreen({super.key});

  @override
  State<SplashAutoLoginScreen> createState() => _SplashAutoLoginScreenState();
}

class _SplashAutoLoginScreenState extends State<SplashAutoLoginScreen> {
  @override
  void initState() {
    super.initState();
    _attemptAutoLogin();
  }

  Future<void> _attemptAutoLogin() async {
    try {
      final result = await SessionService.tryAutoLogin();

      if (!mounted) return;

      if (result['success'] == true) {
        // Auto-login successful, navigate to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Auto-login failed, navigate to sign in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      }
    } catch (e) {
      // On error, navigate to sign in
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1DAF52),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.store, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Leventsale',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2B2A),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Color(0xFF1DAF52)),
            const SizedBox(height: 16),
            const Text(
              'جارٍ تسجيل الدخول...',
              style: TextStyle(fontSize: 16, color: Color(0xFFB0B0B0)),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
