class Task {
  final int? id;
  final String title;
  final String? description;
  final DateTime date;
  final int priority; // 1 low, 2 medium, 3 high
  final String category;
  final bool isCompleted;
  final DateTime createdAt;

  const Task({
    this.id,
    required this.title,
    this.description,
    required this.date,
    required this.priority,
    required this.category,
    required this.isCompleted,
    required this.createdAt,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? date,
    int? priority,
    String? category,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'priority': priority,
    'category': category,
    'is_completed': isCompleted ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  static Task fromMap(Map<String, Object?> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      priority: map['priority'] as int,
      category: (map['category'] as String?) ?? 'Genel',
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
