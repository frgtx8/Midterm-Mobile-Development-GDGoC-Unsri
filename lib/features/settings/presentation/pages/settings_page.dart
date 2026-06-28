import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../cubit/theme_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Theme section
          Text('Tampilan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return Card(
                child: Column(
                  children: [
                    _buildThemeTile(
                      context,
                      icon: Icons.phone_android,
                      title: 'Ikuti Sistem',
                      subtitle: 'Mengikuti pengaturan perangkat',
                      isSelected: themeMode == ThemeMode.system,
                      onTap: () => context.read<ThemeCubit>().setTheme(ThemeMode.system),
                    ),
                    const Divider(height: 1),
                    _buildThemeTile(
                      context,
                      icon: Icons.light_mode,
                      title: 'Mode Terang',
                      subtitle: 'Tampilan terang',
                      isSelected: themeMode == ThemeMode.light,
                      onTap: () => context.read<ThemeCubit>().setTheme(ThemeMode.light),
                    ),
                    const Divider(height: 1),
                    _buildThemeTile(
                      context,
                      icon: Icons.dark_mode,
                      title: 'Mode Gelap',
                      subtitle: 'Tampilan gelap, hemat baterai',
                      isSelected: themeMode == ThemeMode.dark,
                      onTap: () => context.read<ThemeCubit>().setTheme(ThemeMode.dark),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // About section
          Text('Tentang', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  title: const Text('MyDompet', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Versi 1.0.0'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.code),
                  title: Text('Flutter 3.44.4'),
                  subtitle: Text('Dart 3.12.2'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.storage),
                  title: Text('Backend'),
                  subtitle: Text('Node.js + Express + SQLite'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : null),
      title: Text(title, style: TextStyle(
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected ? AppColors.primary : null,
      )),
      subtitle: Text(subtitle),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
      onTap: onTap,
    );
  }
}
