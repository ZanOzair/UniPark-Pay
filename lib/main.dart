import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'database/db_manager.dart';
import 'database/gist_config.dart';
import 'auth/auth_manager.dart';
import 'auth/auth_provider.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/app/app_page.dart';

Future<void> main() async {
  try {
    await dotenv.load(fileName: ".env");
    
    // App config retrieved from Gist
    final appConf = await GistConfig.fetchConfig();
    
    // Initialize database with config
    // Only when app started for the first time
    DatabaseManager.init(
      host: appConf['host'],
      port: appConf['port'],
      userName: appConf['username'],
      password: appConf['password'],
      databaseName: appConf['database'],
    );
    
    runApp(
      ChangeNotifierProvider.value(
        value: AuthManager().authProvider,
        child: const MyApp(),
      ),
    );
  } catch (e) {
    // Show error in debug console
    debugPrint('Configuration Error: $e');
    debugPrint('Please check your .env file configuration');
    
    // Show error message
    final errorMessage = 'Configuration Error\nPlease check your .env file';
    
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(errorMessage),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return MaterialApp(
      title: 'UniParkPay',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: authProvider.isLoggedIn
          ? AppPage(title: 'UniParkPay')
          : LoginPage(),
      routes: {
        '/register': (context) => RegisterPage(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}