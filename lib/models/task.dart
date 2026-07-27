class Task {
  final String id;
  String title;
  bool isCompleted;
  final DateTime date;
  DateTime updatedAt;
  bool isDeleted;
  bool isDirty;
  int sortOrder;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.date,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.isDirty = true,
    this.sortOrder = 0,
  }) : updatedAt = updatedAt ?? date;

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? date,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isDirty,
    int? sortOrder,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isDirty: isDirty ?? this.isDirty,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      isCompleted: (map['isCompleted'] as int) == 1,
      date: DateTime.parse(map['date'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isDeleted: (map['isDeleted'] as int) == 1,
      isDirty: (map['isDirty'] as int) == 1,
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted ? 1 : 0,
        'date': date.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDeleted': isDeleted ? 1 : 0,
        'isDirty': isDirty ? 1 : 0,
        'sortOrder': sortOrder,
      };

  factory Task.fromJson(Map<String, dynamic> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String,
        isCompleted: (map['isCompleted'] as bool),
        date: DateTime.parse(map['date'] as String),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
        sortOrder: map['sortOrder'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted ? true : false,
        'date': date.toIso8601String(),
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'isDeleted': isDeleted ? true : false,
        'isDirty': isDirty ? true : false,
        'sortOrder': sortOrder,
      };
}
