class Task {
  final String id;
  String title;
  bool isCompleted;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isDeleted;
  bool isDirty;
  int sortOrder;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.isDirty = true,
    this.sortOrder = 0,
  }) : updatedAt = updatedAt ?? createdAt;

Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isDirty,
    int? sortOrder,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isDirty: isDirty ?? this.isDirty,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDeleted': isDeleted ? 1 : 0,
        'isDirty': isDirty ? 1 : 0,
        'sortOrder': sortOrder,
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String,
        isCompleted: (map['isCompleted'] as int) == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        isDeleted: (map['isDeleted'] as int) == 1,
        isDirty: (map['isDirty'] as int) == 1,
        sortOrder: map['sortOrder'] as int? ?? 0,
      );
}
