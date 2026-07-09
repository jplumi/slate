class Task {
  final String id;
  String title;
  bool isCompleted;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isDeleted;
  bool isDirty; // true if changed locally since last successful sync

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.isDirty = true,
  }) : updatedAt = updatedAt ?? createdAt;

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isDirty,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
      isDirty: isDirty ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDeleted': isDeleted,
        'isDirty': isDirty,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.parse(json['createdAt'] as String),
        isDeleted: json['isDeleted'] as bool? ?? false,
        isDirty: json['isDirty'] as bool? ?? false,
      );
}
