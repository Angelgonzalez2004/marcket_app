
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/screens/chat/chat_list_screen.dart';
import 'package:marcket_app/screens/chat/chat_screen.dart';
import 'package:marcket_app/screens/public_seller_profile_screen.dart';
import 'package:marcket_app/screens/seller/publication_details_screen.dart';
import 'package:marcket_app/screens/welcome_screen.dart';
import 'package:marcket_app/screens/login_screen.dart';
import 'package:marcket_app/screens/register_screen.dart';
import 'package:marcket_app/screens/home_screen.dart';
import 'package:marcket_app/screens/recover_password_screen.dart';
import 'package:marcket_app/screens/buyer/buyer_dashboard_screen.dart';
import 'package:marcket_app/screens/seller/seller_dashboard_screen.dart';
import 'package:marcket_app/screens/seller/add_edit_product_screen.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:marcket_app/utils/theme.dart';
import 'firebase_options.dart';
import 'package:marcket_app/screens/admin/admin_dashboard_screen.dart';
import 'package:marcket_app/screens/seller/create_edit_publication_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manos del Mar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final userType = args is String ? args : 'Buyer';
          return HomeScreen(userType: userType);
        },
        '/recover_password': (context) => const RecoverPasswordScreen(),
        '/buyer_dashboard': (context) => const BuyerDashboardScreen(),
        '/seller_dashboard': (context) => const SellerDashboardScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/add_edit_product': (context) {
          final product = ModalRoute.of(context)!.settings.arguments as Product?;
          return AddEditProductScreen(product: product);
        },
        '/create_edit_publication': (context) {
          final publication = ModalRoute.of(context)!.settings.arguments as Publication?;
          return CreateEditPublicationScreen(publication: publication);
        },
        '/publication_details': (context) {
          final publication = ModalRoute.of(context)!.settings.arguments as Publication;
          return PublicationDetailsScreen(publication: publication);
        },
        '/chat_list': (context) => const ChatListScreen(),
        '/chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
          if (args != null) {
            return ChatScreen(
              chatRoomId: args['chatRoomId']!,
              otherUserName: args['otherUserName']!,
            );
          }
          // Return a fallback widget or throw an error if args are null
          return const Scaffold(body: Center(child: Text("Error: Chat room details not provided.")));
        },
        '/public_seller_profile': (context) {
          final sellerId = ModalRoute.of(context)!.settings.arguments as String?;
          if (sellerId != null) {
            return PublicSellerProfileScreen(sellerId: sellerId);
          }
          return const Scaffold(body: Center(child: Text("Error: Seller ID not provided.")));
        },
      },
      localizationsDelegates: const [ // New
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [ // New
        Locale('es', 'ES'), // Spanish
      ],
    );
  }
}
