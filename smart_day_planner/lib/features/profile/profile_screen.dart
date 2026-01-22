import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart'; // ✅ Tema provider'ları için şart
import '../../data/db/app_database.dart';
import '../auth/login_screen.dart';
import '../tasks/task_list_screen.dart';
import '../stats/weekly_stats_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<Map<String, dynamic>> _getUserStats(String fullName) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query('users', where: 'full_name = ?', whereArgs: [fullName]);
    return results.isNotEmpty ? results.first : {};
  }

  Future<void> _resetStats(String fullName, WidgetRef ref) async {
    final db = await AppDatabase.instance.database;
    await db.execute(
      'UPDATE users SET points = 0, completed_count = 0 WHERE full_name = ?',
      [fullName],
    );
    await db.delete('tasks'); 
    await db.delete('daily_stats');
    
    ref.invalidate(tasksForDayProvider);
    ref.invalidate(weeklyStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullName = ref.watch(currentUserFullNameProvider);
    final themeColor = ref.watch(themeColorProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: themeMode == ThemeMode.dark ? Colors.black : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Profilim', style: TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Verileri Sıfırla',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Tüm Verileri Sıfırla'),
                  content: const Text('Puanlarınız ve tüm görevleriniz silinecek. Emin misiniz?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Evet, Sıfırla', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await _resetStats(fullName, ref);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüm veriler sıfırlandı! ✅')));
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserStats(fullName),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final stats = snapshot.data!;
          final points = stats['points'] ?? 0;
          final completed = stats['completed_count'] ?? 0;
          final level = (points ~/ 100) + 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(radius: 50, backgroundColor: themeColor, child: const Icon(Icons.person, size: 60, color: Colors.white)),
                const SizedBox(height: 15),
                Text(fullName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: themeColor)),
                Text('Seviye $level Planlayıcı', style: TextStyle(color: themeMode == ThemeMode.dark ? Colors.white70 : Colors.grey, fontSize: 16)),
                const SizedBox(height: 30),
                Row(
                  children: [
                    _buildStatCard('Toplam Puan', points.toString(), Icons.stars, Colors.amber, themeMode == ThemeMode.dark),
                    const SizedBox(width: 15),
                    _buildStatCard('Tamamlanan', completed.toString(), Icons.check_circle, Colors.green, themeMode == ThemeMode.dark),
                  ],
                ),
                const SizedBox(height: 30),
                const Align(alignment: Alignment.centerLeft, child: Text('Görünüm Modu', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: Text(themeMode == ThemeMode.dark ? 'Koyu Tema Açık' : 'Açık Tema Aktif'),
                  secondary: Icon(themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (v) {
                    ref.read(themeModeProvider.notifier).state = v ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
                const SizedBox(height: 30),
                const Align(alignment: Alignment.centerLeft, child: Text('Uygulama Renk Teması', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _colorPicker(ref, Colors.indigo, 'İndigo'),
                    _colorPicker(ref, Colors.teal, 'Zümrüt'),
                    _colorPicker(ref, Colors.deepOrange, 'Amber'),
                    _colorPicker(ref, Colors.pink, 'Gül'),
                  ],
                ),
                const SizedBox(height: 30),
                const Align(alignment: Alignment.centerLeft, child: Text('Başarı Rozetlerin', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    if (completed >= 1) _buildBadge('Çaylak', Icons.baby_changing_station, Colors.brown),
                    if (completed >= 5) _buildBadge('Odaklanmış', Icons.bolt, Colors.blue),
                    if (points >= 500) _buildBadge('Üstat', Icons.workspace_premium, Colors.amber),
                    if (level >= 5) _buildBadge('Efsane', Icons.auto_awesome, Colors.purple),
                  ],
                ),
                const SizedBox(height: 40),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Çıkış Yap'),
                  onTap: () {
                    ref.read(authProvider.notifier).state = false;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _colorPicker(WidgetRef ref, Color color, String label) {
    final current = ref.watch(themeColorProvider);
    return GestureDetector(
      onTap: () => ref.read(themeColorProvider.notifier).state = color,
      child: Column(
        children: [
          CircleAvatar(backgroundColor: color, radius: 20, child: current == color ? const Icon(Icons.check, color: Colors.white) : null),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }

  Widget _buildStatCard(String label, String val, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
