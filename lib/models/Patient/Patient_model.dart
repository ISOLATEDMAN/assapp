// You'll need to import the TranscriptModel we just created.
// Assuming it's in the same directory for this example.
// import 'transcript_model.dart';

import 'package:assapp/models/Patient/PatientTranscriptModel.dart';

class PatientModel {
  final String id;
  final String name;
  final String userId;
  // ✅ ADDED: A list to hold the transcripts.
  final List<TranscriptModel> transcripts;

  PatientModel({
    required this.id,
    required this.name,
    required this.userId,
    // ✅ MODIFIED: The constructor now accepts the transcripts list.
    // It defaults to an empty list `const []` if not provided.
    // This handles the "initially will not be there" requirement perfectly.
    this.transcripts = const [],
  });

  // ✅ MODIFIED: The fromJson factory is updated to parse the list of transcripts.
  factory PatientModel.fromJson(Map<String, dynamic> json) {
    // Safely check for the 'transcripts' key. If it's null or not a list,
    // use an empty list as a fallback.
    var transcriptListFromJson = json['transcripts'] as List? ?? [];

    // Map each item in the JSON list to a TranscriptModel object.
    List<TranscriptModel> parsedTranscripts = transcriptListFromJson
        .map((transcriptJson) =>
            TranscriptModel.fromJson(transcriptJson as Map<String, dynamic>))
        .toList();

    return PatientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['userId'] as String,
      transcripts: parsedTranscripts, // Assign the newly parsed list.
    );
  }

  // ✅ MODIFIED: The toJson method now includes the transcripts.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      // Convert the list of TranscriptModel objects back into a list of JSON maps.
      'transcripts': transcripts.map((transcript) => transcript.toJson()).toList(),
    };
  }
}