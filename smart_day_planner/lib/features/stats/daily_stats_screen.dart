import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/stats_repository.dart';
import '../tasks/task_list_screen.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) => StatsRepository());

String dayKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final da = d.day.toString().padLeft(2, '0');
  return '$y-$m-$da'; // YYYY-MM-DD
}

final dailyStatsProvider = FutureProvider<Map<String, Object?>?>((ref) async {
  final day = ref.watch(selectedDayProvider);
  final repo = ref.read(taskRepoProvider);
  final statsRepo = ref.read(statsRepositoryProvider);

  final rows = await repo.getTaskRowsForDay(day);
  final key = dayKey(day);

  await statsRepo.upsertDailyStats(key, rows);
  return statsRepo.getDailyStats(key);
});

class DailyStatsScreen extends ConsumerWidget {
  const DailyStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dailyStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Günlük İstatistik')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyStatsProvider);
          await ref.read(dailyStatsProvider.future);
        },
        child: statsAsync.when(
          data: (stats) {
            if (stats == null) {
              return ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(child: Text('İstatistik bulunamadı.')),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Toplam Görev'),
                    trailing: Text('${stats['total_tasks']}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Tamamlanan'),
                    trailing: Text('${stats['completed_tasks']}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Öncelik Dağılımı'),
                    subtitle: Text(
                      'Yüksek: ${stats['high_count']} • Orta: ${stats['medium_count']} • Düşük: ${stats['low_count']}',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('En Yoğun Kategori'),
                    trailing: Text('${stats['top_category'] ?? '-'}'),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Yenilemek için aşağı çekebilirsin.', textAlign: TextAlign.center),
              ],
            );
          },
          loading: () => ListView(
            children: const [
              SizedBox(height: 220),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 220),
              Center(child: Text('Hata: $e')),
            ],
          ),
        ),
      ),
    );
  }
}
