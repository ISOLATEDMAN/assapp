import 'dart:convert';

class TranscriptModel {
  final String sessionId;
  final String content;
  final DateTime savedAt;

  TranscriptModel({
    required this.sessionId,
    required this.content,
    required this.savedAt,
  });

  // A factory constructor for creating a new TranscriptModel instance from a map.
  factory TranscriptModel.fromJson(Map<String, dynamic> json) {
    return TranscriptModel(
      sessionId: json['sessionId'] as String,
      content: json['content'] as String,
      // The 'savedAt' is a string in ISO 8601 format, so we parse it into a DateTime object.
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  // A method for converting a TranscriptModel instance into a map.
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'content': content,
      'savedAt': savedAt.toIso8601String(),
    };
  }
}