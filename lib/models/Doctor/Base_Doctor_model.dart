class BaseDoctorModel {
  String token;
  String userId;

  BaseDoctorModel({required this.token, required this.userId});

  factory BaseDoctorModel.fromJson(Map<String, dynamic> json) {
    return BaseDoctorModel(
      token: json['token'] as String,
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userId': userId,
    };
  }
}