class ChatUser {
  late String id;
  late String name;
  late String email;
  late String image;
  late String createdAt;
  late bool isOnline;
  late String about;
  late String lastActive;
  late String pushToken;
  late List groups;

  ChatUser(
      {required this.id,
      required this.name,
      required this.createdAt,
      required this.isOnline,
      required this.about,
      required this.email,
      required this.lastActive,
      required this.image,
      required this.pushToken,
      required this.groups});

  // FromJson - from json data to dart object
  ChatUser.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? '';
    name = json['name'] ?? '';
    createdAt = json['created_at'] ?? '';
    isOnline = json['is_online'] ?? '';
    about = json['about'] ?? '';
    email = json['email'] ?? '';
    lastActive = json['last_active'];
    image = json['image'];
    pushToken = json['push_token'];
    groups = json['groups'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['is_online'] = isOnline;
    data['created_at'] = createdAt;
    data['about'] = about;
    data['email'] = email;
    data['last_active'] = lastActive;
    data['image'] = image;
    data['push_token'] = pushToken;
    data['groups'] = groups;
    return data;
  }
}
