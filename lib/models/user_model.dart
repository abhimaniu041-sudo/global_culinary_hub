class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String preferredLanguage;
  final List<String> favoriteRecipeIds;
  final List<String> recentSearches;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.preferredLanguage = 'en',
    this.favoriteRecipeIds = const [],
    this.recentSearches = const [],
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      favoriteRecipeIds:
          List<String>.from(json['favorite_recipe_ids'] as List? ?? []),
      recentSearches:
          List<String>.from(json['recent_searches'] as List? ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'preferred_language': preferredLanguage,
      'favorite_recipe_ids': favoriteRecipeIds,
      'recent_searches': recentSearches,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt.toIso8601String(),
    };
  }
}
