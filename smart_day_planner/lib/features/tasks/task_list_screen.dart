import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';

import '../../app.dart';
import '../../data/db/app_database.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../services/notification_service.dart';
import '../ai/ai_suggestion_screen.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../stats/weekly_stats_screen.dart';
import 'task_form_screen.dart';

// POMODORO STATE MANAGEMENT
class PomodoroState {
  final int seconds;
  final bool isRunning;
  final int initialMinutes;
  PomodoroState({required this.seconds, required this.isRunning, required this.initialMinutes});

  PomodoroState copyWith({int? seconds, bool? isRunning, int? initialMinutes}) {
    return PomodoroState(
      seconds: seconds ?? this.seconds,
      isRunning: isRunning ?? this.isRunning,
      initialMinutes: initialMinutes ?? this.initialMinutes,
    );
  }
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  Timer? _timer;
  PomodoroNotifier() : super(PomodoroState(seconds: 25 * 60, isRunning: false, initialMinutes: 25));

  void setDuration(int minutes) {
    _timer?.cancel();
    state = PomodoroState(seconds: minutes * 60, isRunning: false, initialMinutes: minutes);
  }

  void toggle() {
    if (state.isRunning) {
      _timer?.cancel();
      state = state.copyWith(isRunning: false);
    } else {
      state = state.copyWith(isRunning: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.seconds > 0) {
          state = state.copyWith(seconds: state.seconds - 1);
        } else {
          timer.cancel();
          state = state.copyWith(isRunning: false);
        }
      });
    }
  }

  void reset() {
    _timer?.cancel();
    state = PomodoroState(seconds: state.initialMinutes * 60, isRunning: false, initialMinutes: state.initialMinutes);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pomodoroProvider = StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) => PomodoroNotifier());

final taskRepoProvider = Provider<TaskRepository>((ref) => TaskRepository());
final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

final tasksForDayProvider = FutureProvider<List<Task>>((ref) async {
  final repo = ref.watch(taskRepoProvider);
  final day = ref.watch(selectedDayProvider);
  return await repo.getTasksForDay(day);
});

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _invalidateAll() {
    ref.invalidate(tasksForDayProvider);
    ref.invalidate(weeklyStatsProvider);
  }

  Future<void> _updateUserPoints(String fullName, int pointsToAdd, int completedAdd) async {
    final db = await AppDatabase.instance.database;
    await db.execute(
      'UPDATE users SET points = points + ?, completed_count = completed_count + ? WHERE full_name = ?',
      [pointsToAdd, completedAdd, fullName],
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(selectedDayProvider);
    final tasksAsync = ref.watch(tasksForDayProvider);
    final fullName = ref.watch(currentUserFullNameProvider);
    final pomo = ref.watch(pomodoroProvider);
    
    // ✅ TEMALARI DİNAMİK ALIYORUZ
    final themeColor = ref.watch(themeColorProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F7FA),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: themeColor,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: const Text('Akıllı Gün Planlayıcı', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [themeColor, themeColor.withOpacity(0.8)],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Merhaba, $fullName!', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(DateFormat('d MMMM yyyy EEEE', 'tr_TR').format(day), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                actions: [
                  Row(
                    children: [
                      if (pomo.isRunning)
                        Text(
                          '${(pomo.seconds ~/ 60).toString().padLeft(2, '0')}:${(pomo.seconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      IconButton(
                        icon: Icon(pomo.isRunning ? Icons.timer : Icons.timer_outlined, color: Colors.white),
                        onPressed: () => _showPomodoroDialog(context),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      tasksAsync.when(
                        data: (tasks) {
                          final total = tasks.length;
                          final done = tasks.where((t) => t.isCompleted).length;
                          final progress = total == 0 ? 0.0 : done / total;
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[900] : themeColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Günlük İlerleme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('$done / $total Tamamlandı', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                    Text('%${(progress * 100).toInt()}', style: const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progress, 
                                    backgroundColor: Colors.white12, 
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent), 
                                    minHeight: 10
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => TaskFormScreen(initialDate: day)));
                                if (created == true) _invalidateAll();
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Görev Ekle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, 
                                foregroundColor: Colors.white, 
                                padding: const EdgeInsets.symmetric(vertical: 16), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklyStatsScreen())),
                              icon: const Icon(Icons.bar_chart),
                              label: const Text('İstatistikler'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor, 
                                foregroundColor: Colors.white, 
                                padding: const EdgeInsets.symmetric(vertical: 16), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              tasksAsync.when(
                data: (tasks) => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final t = tasks[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.white, 
                            borderRadius: BorderRadius.circular(16), 
                            boxShadow: [if(!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: t.isCompleted,
                              activeColor: Colors.green,
                              onChanged: (v) async {
                                final newVal = v ?? false;
                                await ref.read(taskRepoProvider).updateTask(t.copyWith(isCompleted: newVal));
                                if (newVal) {
                                  _confettiController.play();
                                  await _updateUserPoints(fullName, 50, 1);
                                } else {
                                  await _updateUserPoints(fullName, -50, -1);
                                }
                                _invalidateAll();
                              },
                            ),
                            title: Text(
                              t.title, 
                              style: TextStyle(
                                decoration: t.isCompleted ? TextDecoration.lineThrough : null, 
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              )
                            ),
                            subtitle: Text(
                              '${DateFormat('HH:mm').format(t.date)} • ${t.category}',
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Görevi Sil'),
                                    content: const Text('Bu görev silinecek. Puanlarınız güncellenecektir.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (ok == true && t.id != null) {
                                  if (t.isCompleted) {
                                    await _updateUserPoints(fullName, -50, -1);
                                  }
                                  await ref.read(taskRepoProvider).deleteTask(t.id!);
                                  _invalidateAll();
                                }
                              },
                            ),
                            onTap: () async {
                              final updated = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => TaskFormScreen(existing: t)));
                              if (updated == true) _invalidateAll();
                            },
                          ),
                        );
                      },
                      childCount: tasks.length,
                    ),
                  ),
                ),
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Hata: $e'))),
              ),
            ],
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiSuggestionScreen())),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  void _showPomodoroDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const PomodoroTimerDialog());
  }
}

class PomodoroTimerDialog extends ConsumerWidget {
  const PomodoroTimerDialog({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomo = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final themeColor = ref.watch(themeColorProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Center(child: Text('Odaklanma Sayacı', style: TextStyle(fontWeight: FontWeight.bold))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 50, color: themeColor),
          const SizedBox(height: 15),
          Text('${(pomo.seconds ~/ 60).toString().padLeft(2, '0')}:${(pomo.seconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          if (!pomo.isRunning)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Süre (dk): '),
              SizedBox(width: 60, child: TextField(keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8)), onSubmitted: (val) {
                final mins = int.tryParse(val);
                if (mins != null && mins > 0) notifier.setDuration(mins);
              })),
            ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(onPressed: () => notifier.toggle(), style: ElevatedButton.styleFrom(backgroundColor: pomo.isRunning ? Colors.redAccent : Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(pomo.isRunning ? 'Durdur' : 'Başlat')),
            const SizedBox(width: 10),
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => notifier.reset()),
          ]),
        ],
      ),
    );
  }
}
