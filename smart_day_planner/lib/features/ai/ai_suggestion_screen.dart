import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart'; // ✅ Tema için eklendi
import '../../config.dart';
import '../../data/models/task.dart';
import '../../services/ai_service.dart';
import '../../services/notification_service.dart';
import '../stats/weekly_stats_screen.dart';
import '../tasks/task_list_screen.dart';

final aiServiceProvider = Provider((ref) => AiService(baseUrl: AppConfig.aiBaseUrl));
final aiTopicProvider = StateProvider<String>((ref) => '');

final aiPlanProvider = FutureProvider<AiPlan>((ref) async {
  final repo = ref.read(taskRepoProvider);
  final day = ref.read(selectedDayProvider);
  final tasks = await repo.getTasksForDay(day);
  final topic = ref.watch(aiTopicProvider);
  final ai = ref.read(aiServiceProvider);
  return ai.generatePlan(tasks, topic: topic);
});

class AiSuggestionScreen extends ConsumerStatefulWidget {
  const AiSuggestionScreen({super.key});

  @override
  ConsumerState<AiSuggestionScreen> createState() => _AiSuggestionScreenState();
}

class _AiSuggestionScreenState extends ConsumerState<AiSuggestionScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(aiPlanProvider);
    final themeColor = ref.watch(themeColorProvider); // ✅ Dinamik Renk
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark; // ✅ Dinamik Tema

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('AI Gün Planı', style: TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: isDark ? Colors.grey[900] : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ne üzerine bir plan istersin?', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : themeColor)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Örn: Yazılım, Spor, Sınav...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          fillColor: isDark ? Colors.black : const Color(0xFFF5F7FA),
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(aiTopicProvider.notifier).state = _controller.text;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.auto_awesome),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: planAsync.when(
              data: (plan) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [themeColor, themeColor.withOpacity(0.8)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(plan.notes, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                    ),
                    const SizedBox(height: 24),
                    ...plan.blocks.map((b) => _AiBlockCard(block: b, themeColor: themeColor, isDark: isDark)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiBlockCard extends ConsumerWidget {
  final AiPlanBlock block;
  final Color themeColor;
  final bool isDark;
  const _AiBlockCard({required this.block, required this.themeColor, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [if(!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
        ),
        title: Text('${block.start} - ${block.end}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : themeColor)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(block.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 4),
            Text(block.reason, style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_task, color: Color(0xFF4CAF50), size: 28),
          onPressed: () async {
            final repo = ref.read(taskRepoProvider);
            final day = ref.read(selectedDayProvider);
            final timeParts = block.start.split(':');
            final hour = int.tryParse(timeParts[0]) ?? 9;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            final taskDate = DateTime(day.year, day.month, day.day, hour, minute);

            final newTask = Task(
              title: block.title,
              description: block.reason,
              date: taskDate,
              priority: 2,
              category: 'AI Önerisi',
              isCompleted: false,
              createdAt: DateTime.now(),
            );

            final newId = await repo.insertTask(newTask);
            await NotificationService.instance.scheduleTaskNotification(id: newId, title: newTask.title, body: 'AI planladığın görev vakti!', when: newTask.date);
            
            ref.invalidate(tasksForDayProvider);
            ref.invalidate(weeklyStatsProvider); 

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${block.title}" plana eklendi! ✅'), 
                  backgroundColor: themeColor,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
