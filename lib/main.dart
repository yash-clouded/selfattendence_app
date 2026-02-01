import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/attendance_model.dart';
import 'screens/home_screen.dart';
import 'screens/add_subject_screen.dart';
import 'screens/subject_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AttendanceProvider(),
      child: MaterialApp(
        title: 'Attendance App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          primaryColor: const Color(0xFF0A84FF), // iOS Blue
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF0A84FF),
            surface: Color(0xFF1C1C1E),
            onSurface: Colors.white,
            secondary: Color(0xFF32D74B), // iOS Green
            error: Color(0xFFFF453A), // iOS Red
          ),
          cardColor: const Color(0xFF1C1C1E),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/add': (context) => const AddSubjectScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/details') {
            final args = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => SubjectDetailsScreen(subjectId: args),
            );
          }
          return null;
        },
      ),
    );
  }
}
