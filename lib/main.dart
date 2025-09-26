import 'package:assapp/blocs/AuthBloc/bloc/auths_bloc.dart';
import 'package:assapp/blocs/PatientBloc/bloc/patient_handling_bloc.dart';
import 'package:assapp/pages/auths/login.dart';
import 'package:assapp/services/StorageService/StorageService.dart';
import 'package:assapp/services/authService/AuthServie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Import the package

// 2. Make the main function async
Future<void> main() async {
  // 3. Ensure that Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // 4. Load the .env file before the app starts
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context)=>AuthsBloc(authService: AuthService(storageService: StorageService()))),
        BlocProvider(create: (context)=>PatientHandlingBloc())
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: LoginScreen(),
      ),
    );
  }
}