class Groups {
  late String groupName;
  late String admin;
  late List members;
  late String groupId;
  late String recentMessage;
  late String recentMessageTime;
  late String recentMessageSender;

  Groups({
    required this.groupName,
    required this.admin,
    required this.members,
    required this.groupId,
    required this.recentMessage,
    required this.recentMessageTime,
    required this.recentMessageSender
  });

  // FromJson - from json data to dart object
  Groups.fromJson(Map<String, dynamic> json) {
    groupName = json['groupName'] ?? '';
    admin = json['admin'] ?? '';
    members = json['members'] ?? '';
    groupId = json['groupId'] ?? '';
    recentMessage = json['recentMessage'] ?? '';
    recentMessageTime = json['recentMessageTime'] ?? '';
    recentMessageSender = json['recentMessageSender'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['groupName'] = groupName;
    data['admin'] = admin;
    data['members'] = members;
    data['groupId'] = groupId;
    data['recentMessage'] = recentMessage;
    data['messageTime'] = recentMessageTime;
    data['recentMessageSender'] = recentMessageSender;
    return data;
  }
}
