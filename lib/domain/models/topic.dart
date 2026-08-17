/// Topic model matching the backend topic VO.
class Topic {
  final int id;
  final String name;
  final String? description;
  final int participantsCount;
  final DateTime? createdAt;

  const Topic({
    required this.id,
    required this.name,
    this.description,
    this.participantsCount = 0,
    this.createdAt,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? json['title'] ?? json['topicName'] ?? '')
          as String? ??
          '',
      description: json['description'] as String?,
      participantsCount:
          (json['participantsCount'] ??
                  json['participants'] ??
                  json['followerCount'] ??
                  0)
              as int? ??
          0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'participantsCount': participantsCount,
        'createdAt': createdAt?.toIso8601String(),
      };
}
