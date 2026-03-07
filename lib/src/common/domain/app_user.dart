class AppUser {
  final int userId;
  final String email;
  final String password;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final String? title;
  final String? company;
  final String? phoneNumber;  
  final String? photoUrl;

  AppUser({
    required this.userId,
    required this.email,
    required this.password,
    required this.displayName,
    this.firstName,
    this.lastName,
    this.title,
    this.company,
    this.phoneNumber,
    this.photoUrl,
  });


  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['userId'],
      email: json['email'],
      password: json['password'],
      displayName: json['displayName'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      title: json['title'],
      company: json['company'],
      phoneNumber: json['phoneNumber'],
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'password': password,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'title': title,
      'company': company,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['userId'],
      email: map['email'],
      password: map['password'],
      displayName: map['displayName'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      title: map['title'],
      company: map['company'],
      phoneNumber: map['phoneNumber'],
      photoUrl: map['photoUrl'],
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'password': password,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'title': title,
      'company': company,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
    };
  }
}