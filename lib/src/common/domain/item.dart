class Item {
  final int itemId;
  final String itemType;
  final String itemTitle;
  final String itemDescription;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isDone;

  Item({
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
    required this.itemDescription,
    required this.createdAt,
    required this.isDone, this.photoUrl,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemId: json['itemId'],
      itemType: json['itemType'],
      itemTitle: json['itemTitle'],
      itemDescription: json['itemDescription'],
      photoUrl: json['photoUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      isDone: json['isDone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'itemTitle': itemTitle,
      'itemDescription': itemDescription,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'isDone': isDone,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      itemId: map['itemId'],
      itemType: map['itemType'],
      itemTitle: map['itemTitle'],
      itemDescription: map['itemDescription'],
      photoUrl: map['photoUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      isDone: map['isDone'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'itemTitle': itemTitle,
      'itemDescription': itemDescription,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'isDone': isDone == true ? 1 : 0,
    };
  }
}
