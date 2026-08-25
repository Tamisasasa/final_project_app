import 'package:final_project_vaccine/feature/projects/AddPet_Info.dart';
import 'package:final_project_vaccine/feature/projects/Homepage.dart';
import 'package:final_project_vaccine/feature/projects/ListPet.dart';
import 'package:final_project_vaccine/feature/projects/Login.dart';
import 'package:final_project_vaccine/feature/projects/Register.dart';
import 'package:final_project_vaccine/feature/projects/ViewProfile.dart';  
import 'package:final_project_vaccine/feature/projects/EditProfile.dart'; 
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pet Appointment',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Login(), 
    );
  }
}