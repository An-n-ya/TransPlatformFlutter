import '../../utils/image_url.dart';

/// User view object matching backend [UserVO].
class User {
  final int id;
  final String username;
  final String nickname;
  final String? avatar;
  final String? bio;
  final String? bioHeaderImg;
  final int status;
  final int? pinnedPostId;
  final int? followersCount;
  final int? followeesCount;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.username,
    required this.nickname,
    this.avatar,
    this.bio,
    this.bioHeaderImg,
    this.status = 1,
    this.pinnedPostId,
    this.followersCount,
    this.followeesCount,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: resolveImageUrl(json['avatar'] as String?),
      bio: json['bio'] as String?,
      bioHeaderImg: resolveImageUrl(json['bioHeaderImg'] as String?),
      status: json['status'] as int? ?? 1,
      pinnedPostId: json['pinnedPostId'] as int?,
      followersCount: json['followersCount'] as int?,
      followeesCount: json['followeesCount'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'nickname': nickname,
        'avatar': avatar,
        'bio': bio,
        'bioHeaderImg': bioHeaderImg,
        'status': status,
        'pinnedPostId': pinnedPostId,
        'followersCount': followersCount,
        'followeesCount': followeesCount,
        'createdAt': createdAt?.toIso8601String(),
      };
}
