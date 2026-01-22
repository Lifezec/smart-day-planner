import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app.dart'; // ✅ Tema için eklendi
import '../../data/repositories/stats_repository.dart';
import '../tasks/task_list_screen.dart';
import 'daily_stats_screen.dart';

class WeeklyStatsData {
  final List<Map<String, Object?>> dailyRows;
  final Map<String, int> categoryDistribution;
  WeeklyStatsData({required this.dailyRows, required this.categoryDistribution});
}

final weeklyStatsProvider = FutureProvider<WeeklyStatsData>((ref) async {
  final selectedDay = ref.watch(selectedDayProvider);
  final statsRepo = ref.read(statsRepositoryProvider);
  final taskRepo = ref.read(taskRepoProvider);

  final d0 = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
  final start = d0.subtract(Duration(days: d0.weekday - 1));
  
  final Map<String, int> totalCategoryCounts = {};
  
  for (int i = 0; i < 7; i++) {
    final cur = start.add(Duration(days: i));
    final rows = await taskRepo.getTaskRowsForDay(cur);
    for (final row in rows) {
      final cat = (row['category'] as String?) ?? 'Genel';
      totalCategoryCounts[cat] = (totalCategoryCounts[cat] ?? 0) + 1;
    }
    await statsRepo.upsertDailyStats(dayKey(cur), rows);
  }
  final dailyRows = await statsRepo.getStatsRange(start, start.add(const Duration(days: 7)));
  return WeeklyStatsData(dailyRows: dailyRows, categoryDistribution: totalCategoryCounts);
});

class WeeklyStatsScreen extends ConsumerWidget {
  const WeeklyStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weeklyStatsProvider);
    final themeColor = ref.watch(themeColorProvider); // ✅ Dinamik Renk
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark; // ✅ Dinamik Tema

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('İstatistikler', style: TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: async.when(
        data: (statsData) {
          final rows = statsData.dailyRows;
          final categoryDistribution = statsData.categoryDistribution;

          if (rows.isEmpty && categoryDistribution.isEmpty) {
            return Center(child: Text('Görüntülenecek veri yok.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)));
          }

          final sorted = List<Map<String, Object?>>.from(rows);
          sorted.sort((a, b) => (a['day'] as String).compareTo(b['day'] as String));

          int totalTasks = 0;
          int totalDone = 0;
          for (var r in sorted) {
            totalTasks += (r['total_tasks'] as int?) ?? 0;
            totalDone += (r['completed_tasks'] as int?) ?? 0;
          }
          final weeklyEfficiency = totalTasks == 0 ? 0 : (totalDone * 100 ~/ totalTasks);

          final List<Map<String, dynamic>> categoryList = [];
          if (categoryDistribution.isNotEmpty) {
            final int totalInAllCats = categoryDistribution.values.fold(0, (sum, val) => sum + val);
            categoryDistribution.forEach((name, count) {
              categoryList.add({
                'name': name,
                'percent': (count * 100 ~/ totalInAllCats).toString() + '%',
                'color': _getCategoryColor(name),
              });
            });
            categoryList.sort((a, b) => b['percent'].compareTo(a['percent']));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : themeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow('Tamamlanan Görevler', totalDone.toString(), 'Bu Hafta'),
                      const Divider(color: Colors.white24, height: 30),
                      _buildStatRow('Verimlilik Oranı', '%$weeklyEfficiency', ''),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text('Haftalık Görev İlerlemesi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : themeColor)),
                const SizedBox(height: 20),
                Container(
                  height: 180,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: sorted.map((r) {
                      final total = (r['total_tasks'] as int?) ?? 0;
                      final done = (r['completed_tasks'] as int?) ?? 0;
                      final double heightFactor = total == 0 ? 0.1 : (done / total).clamp(0.1, 1.0);
                      final dayName = DateFormat('E', 'tr_TR').format(DateTime.parse(r['day'] as String));

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(done.toString(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                          const SizedBox(height: 4),
                          Container(
                            width: 35,
                            height: 120 * heightFactor,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(dayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 30),
                Text('Görev Dağılımı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : themeColor)),
                const SizedBox(height: 16),
                ...categoryList.map((c) => _buildCategoryRow(c['name'], c['percent'], c['color'], isDark)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'çalışma': return Colors.blue;
      case 'kişisel': return Colors.green;
      case 'genel': return Colors.orange;
      case 'spor': return Colors.redAccent;
      case 'ai önerisi': return Colors.amber;
      default: return Colors.blueGrey;
    }
  }

  Widget _buildStatRow(String label, String value, String subLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (label.isNotEmpty) Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(subLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryRow(String label, String percent, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white, 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
          const Spacer(),
          Text(percent, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        ],
      ),
    );
  }
}
