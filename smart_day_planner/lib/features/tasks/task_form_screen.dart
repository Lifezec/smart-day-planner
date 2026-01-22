import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../data/models/task.dart';
import '../../data/repositories/category_repository.dart';
import '../../services/notification_service.dart';
import 'task_list_screen.dart';

final categoryRepoProvider = Provider((ref) => CategoryRepository());
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(categoryRepoProvider);
  return repo.getCategories();
});

class TaskFormScreen extends ConsumerStatefulWidget {
  final Task? existing;
  final DateTime? initialDate;
  const TaskFormScreen({super.key, this.existing, this.initialDate});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;

  late int _priority;
  late String _category;
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _priority = e?.priority ?? 2;
    _category = e?.category ?? 'Genel';
    final now = DateTime.now();
    _date = e?.date ?? widget.initialDate ?? DateTime(now.year, now.month, now.day);
    _time = TimeOfDay(hour: _date.hour, minute: _date.minute);
  }

  Future<void> _addCategoryDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yeni Kategori'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Örn: Spor, İş, Ders'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ekle')),
        ],
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref.read(categoryRepoProvider).addCategory(ctrl.text.trim());
      ref.invalidate(categoriesProvider);
      setState(() => _category = ctrl.text.trim());
    }
  }

  Widget _buildPriorityButton(int val, String label, Color themeColor) {
    bool isSelected = _priority == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? themeColor : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);
    final themeColor = ref.watch(themeColorProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Görev Ekle' : 'Görevi Düzenle', style: const TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (widget.existing!.id != null) {
                  await ref.read(taskRepoProvider).deleteTask(widget.existing!.id!);
                  if (mounted) Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Görev Adı', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _title,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Örn: Alışveriş Yap',
                  fillColor: isDark ? Colors.grey[900] : Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Lütfen başlık girin' : null,
              ),
              const SizedBox(height: 20),
              Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 8),
              catsAsync.when(
                data: (cats) {
                  final list = cats.isEmpty ? ['Genel'] : cats;
                  if (!list.contains(_category)) _category = list.first;
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _category,
                          dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            fillColor: isDark ? Colors.grey[900] : Colors.white,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          items: list.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _category = v ?? 'Genel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _addCategoryDialog,
                        icon: Icon(Icons.add_box, color: themeColor, size: 32),
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Hata: $e'),
              ),
              const SizedBox(height: 20),
              Text('Tarih ve Saat', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 8),
              ListTile(
                tileColor: isDark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(Icons.calendar_today, color: themeColor),
                title: Text('${_date.day}.${_date.month}.${_date.year}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 20),
              Text('Öncelik', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPriorityButton(1, 'Düşük', themeColor),
                  const SizedBox(width: 10),
                  _buildPriorityButton(2, 'Orta', themeColor),
                  const SizedBox(width: 10),
                  _buildPriorityButton(3, 'Yüksek', themeColor),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final task = Task(
                          id: widget.existing?.id,
                          title: _title.text,
                          description: _desc.text,
                          date: DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute),
                          priority: _priority,
                          category: _category,
                          isCompleted: widget.existing?.isCompleted ?? false,
                          createdAt: DateTime.now(),
                        );
                        if (widget.existing == null) {
                          final id = await ref.read(taskRepoProvider).insertTask(task);
                          await NotificationService.instance.scheduleTaskNotification(id: id, title: task.title, body: 'Görev vakti!', when: task.date);
                        } else {
                          await ref.read(taskRepoProvider).updateTask(task);
                        }
                        if (mounted) Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
