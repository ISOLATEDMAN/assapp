import 'package:assapp/models/Patient/PatientTranscriptModel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TranscriptsPage extends StatelessWidget {
  final String patientName;
  final List<TranscriptModel> transcripts;

  const TranscriptsPage({
    super.key,
    required this.patientName,
    required this.transcripts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$patientName's Transcripts"),
      ),
      body: transcripts.isEmpty
          // --- Show a message if there are no transcripts ---
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No transcripts found for this patient.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          // --- Otherwise, show the list of transcripts ---
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: transcripts.length,
              itemBuilder: (context, index) {
                // Display the most recent transcript first
                final transcript = transcripts.reversed.toList()[index];
                final formattedDate =
                    DateFormat.yMMMd().add_jm().format(transcript.savedAt);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: ListTile(
                    leading: const Icon(Icons.article_outlined, color: Colors.blueGrey),
                    title: Text(
                      transcript.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('Saved on: $formattedDate'),
                    onTap: () {
                      // Show the full transcript in a dialog when tapped
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Transcript from $formattedDate'),
                          content: SingleChildScrollView(
                            child: Text(transcript.content),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}