/*
 * Copyright (c) 2026 GoalFlow Contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'l10n/app_i18n.dart';
import 'services/app_state.dart';
import 'services/reminder_service.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: .env file not found, using default configurations.');
  }
  await ReminderService.instance.initialize();
  await initializeDateFormatting('zh', null);
  await initializeDateFormatting('en', null);
  final appState = AppState();
  await appState.initializeLocalState();
  await appState.restoreSession();
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const GoalFlowApp(),
    ),
  );
}

class GoalFlowApp extends StatelessWidget {
  const GoalFlowApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'GoalFlow',
        theme: buildTheme(),
        debugShowCheckedModeBanner: false,
        locale: context.watch<AppState>().locale,
        supportedLocales: const [
          Locale('zh'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MainShell(),
      );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _nav = 0;
  String? _lastMessage;
  bool _authPromptOpen = false;

  static const _screens = [
    HomeScreen(),
    GoalsScreen(),
    HabitsScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final globalMessage = appState.globalMessage;
    if (globalMessage != null && globalMessage != _lastMessage) {
      _lastMessage = globalMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('登录状态已过期，请重新登录',
                  'Your session has expired. Please sign in again.'),
            ),
          ),
        );
        context.read<AppState>().clearGlobalMessage();
        if (!_authPromptOpen && !appState.isLoggedIn) {
          _authPromptOpen = true;
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const LoginScreen()))
              .whenComplete(() => _authPromptOpen = false);
        }
      });
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: IndexedStack(index: _nav, children: _screens),
      bottomNavigationBar:
          _BottomNav(current: _nav, onTap: (i) => setState(() => _nav = i)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: context.tr('首页', 'Home')),
      (icon: Icons.track_changes_rounded, label: context.tr('目标', 'Goals')),
      (icon: Icons.self_improvement_rounded, label: context.tr('习惯', 'Habits')),
      (icon: Icons.calendar_month_rounded, label: context.tr('轨迹', 'Progress')),
      (icon: Icons.settings_rounded, label: context.tr('设置', 'Settings')),
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFFF0F0F0),
            const Color(0xFFF0F0F0).withValues(alpha: 0)
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 6, 16, MediaQuery.of(context).padding.bottom + 6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final active = i == current;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon,
                          size: 18,
                          color:
                              active ? Colors.white : const Color(0xFF8A8FA8)),
                      const SizedBox(height: 3),
                      Text(item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w400,
                            color:
                                active ? Colors.white : const Color(0xFF8A8FA8),
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
