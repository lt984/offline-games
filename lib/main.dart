import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/save_store.dart';
import 'games/game_catalog.dart';
import 'screens/hub_screen.dart';
import 'state/profile_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final store = await SaveStore.open(starterGameIds);
  runApp(PocketArcadeApp(controller: ProfileController(store)));
}

class PocketArcadeApp extends StatelessWidget {
  const PocketArcadeApp({super.key, required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<ProfileController>(
        builder: (context, profile, _) => MaterialApp(
          title: 'Pocket Arcade',
          debugShowCheckedModeBanner: false,
          theme: profile.skin.toThemeData(),
          themeAnimationDuration: const Duration(milliseconds: 350),
          home: const HubScreen(),
        ),
      ),
    );
  }
}
