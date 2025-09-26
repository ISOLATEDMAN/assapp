import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:assapp/services/StorageService/StorageService.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class Patientpage extends StatefulWidget {
  final String patientName;
  final String patientId;

  const Patientpage({
    super.key,
    required this.patientName,
    required this.patientId,
  });

  @override
  State<Patientpage> createState() => _PatientpageState();
}

enum RecordingState { notStarted, recording, paused, sending, finalizing, finished }

// ✅ STEP 1: Add the `WidgetsBindingObserver` mixin to your State class.
class _PatientpageState extends State<Patientpage> with WidgetsBindingObserver {
  // --- Configuration ---
  final String _serverBaseUrl = 'https://e818ee4942b3.ngrok-free.app/v1';
  final storageService = StorageService();
  final Dio _dio = Dio();
  final AudioRecorder _audioRecorder = AudioRecorder();

  // --- State Variables ---
  String? _authToken;
  RecordingState _recordingState = RecordingState.notStarted;
  List<String> _transcripts = [];
  String? _finalTranscript;
  String? _sessionId;
  int _chunkCounter = 0;
  Timer? _chunkUploadTimer;
  String? _currentChunkPath;

  @override
  void initState() {
    super.initState();
    _initializeAuthToken();
    // ✅ STEP 2: Register your state class as an observer for lifecycle events.
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _initializeAuthToken() async {
    final token = await storageService.getToken();
    if (mounted) {
      setState(() => _authToken = token);
    }
  }

  @override
  void dispose() {
    _chunkUploadTimer?.cancel();
    _audioRecorder.dispose();
    // ✅ STEP 3: Unregister the observer to prevent memory leaks when the page is destroyed.
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ STEP 4: Implement the `didChangeAppLifecycleState` method.
  // This method is called whenever the app's state changes (e.g., goes to background).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    log('App Lifecycle State: $state');
    switch (state) {
      // The app is not visible. This can be due to a phone call, locking the screen, or switching apps.
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // We only want to auto-pause if a recording is actively in progress.
        if (_recordingState == RecordingState.recording) {
          _autoPauseRecording();
        }
        break;
      // The app is visible and running. No action needed when returning.
      case AppLifecycleState.resumed:
        break;
    }
  }
  
  // ✅ STEP 5: Create a dedicated function to handle auto-pausing.
  // This keeps the logic clean and separate from the user's manual pause action.
  Future<void> _autoPauseRecording() async {
    if (_recordingState != RecordingState.recording) return;

    log('App is backgrounded. Auto-pausing recording...');
    _chunkUploadTimer?.cancel();
    await _audioRecorder.pause();
    if (mounted) {
      setState(() => _recordingState = RecordingState.paused);
    }
  }

  // --- Core Recording Logic (No changes needed below this line) ---

  Future<void> _startRecording() async {
    if (!await _audioRecorder.hasPermission() || _authToken == null) {
      log('No permission or auth token is missing.');
      return;
    }

    setState(() => _recordingState = RecordingState.sending);

    try {
      final response = await _dio.post(
        '$_serverBaseUrl/upload-session',
        options: Options(headers: {'Authorization': 'Bearer $_authToken'}),
        data: {'patientId': widget.patientId},
      );
      _sessionId = response.data['id'];

      await _startNewChunkRecording();

      _chunkUploadTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _processAndUploadChunk(isLast: false);
      });

      setState(() {
        _recordingState = RecordingState.recording;
        _transcripts = [];
        _finalTranscript = null;
      });
    } catch (e) {
      log('Error starting recording session: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not start session')));
      _resetState();
    }
  }

  Future<void> _startNewChunkRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    _currentChunkPath = '${dir.path}/chunk_${_chunkCounter++}.wav';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
      path: _currentChunkPath!,
    );
  }

  Future<void> _processAndUploadChunk({required bool isLast}) async {
    final recordingPath = await _audioRecorder.stop();
    if (recordingPath == null) return;

    final chunkNumberToUpload = _chunkCounter - 1;

    final file = File(recordingPath);
    if (!await file.exists() || await file.length() == 0) {
        log('Chunk file is empty or does not exist for index: $chunkNumberToUpload');
        if (!isLast) await _startNewChunkRecording();
        return;
    }

    if (!isLast) {
      await _startNewChunkRecording();
    }
    
    await _uploadAudioChunk(file, chunkNumberToUpload, isLast: isLast);
  }

  Future<void> _togglePauseResume() async {
    if (_recordingState == RecordingState.recording) {
      _chunkUploadTimer?.cancel();
      await _audioRecorder.pause();
      setState(() => _recordingState = RecordingState.paused);
    } else if (_recordingState == RecordingState.paused) {
      _chunkUploadTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _processAndUploadChunk(isLast: false);
      });
      await _audioRecorder.resume();
      setState(() => _recordingState = RecordingState.recording);
    }
  }

  Future<void> _endRecording() async {
    setState(() => _recordingState = RecordingState.finalizing);
    _chunkUploadTimer?.cancel();
    await _processAndUploadChunk(isLast: true);
    if (mounted) {
      setState(() => _recordingState = RecordingState.finished);
    }
  }

  Future<void> _uploadAudioChunk(File audioFile, int chunkNumberForUpload, {required bool isLast}) async {
    if (_sessionId == null) return;
    
    try {
      final presignedUrlResponse = await _dio.post(
        '$_serverBaseUrl/get-presigned-url',
        options: Options(headers: {'Authorization': 'Bearer $_authToken'}),
        data: {
          'sessionId': _sessionId,
          'chunkNumber': chunkNumberForUpload,
          'mimeType': 'audio/wav',
        },
      );
      final presignedUrl = presignedUrlResponse.data['presignedUrl'];
      final gcsPath = presignedUrlResponse.data['gcsPath'];

      await _dio.put(
        presignedUrl,
        data: audioFile.openRead(),
        options: Options(headers: {
          'Content-Type': 'audio/wav',
          'Content-Length': await audioFile.length(),
        }),
      );

      final notifyResponse = await _dio.post(
        '$_serverBaseUrl/notify-chunk-uploaded',
        options: Options(headers: {'Authorization': 'Bearer $_authToken'}),
        data: {'sessionId': _sessionId, 'gcsPath': gcsPath, 'isLast': isLast},
      );
      
      if (notifyResponse.data['isFinal'] == true) {
         if (mounted) {
          setState(() {
            _finalTranscript = notifyResponse.data['transcript'] as String?;
            _transcripts.clear();
          });
        }
      } else {
        final transcript = notifyResponse.data['transcript'] as String?;
        if (mounted && transcript != null && transcript.isNotEmpty) {
          setState(() => _transcripts.add(transcript));
        }
      }
    } catch (e) {
      log('Error uploading chunk $chunkNumberForUpload: $e');
      if (mounted) {
        setState(() => _transcripts.add('[Error receiving transcript]'));
      }
    } finally {
      await audioFile.delete();
    }
  }
  
  Future<void> _saveTranscriptToServer() async {
    final String url = "${dotenv.env["BASE_API"]}/v1/save-transcript";
    if (_sessionId == null || _finalTranscript == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transcript to save.')));
      return;
    }
    
    try {
      await _dio.post(
        url,
        options: Options(headers: {'Authorization': 'Bearer $_authToken'}),
        data: {
          'patientId': widget.patientId,
          'sessionId': _sessionId,
          'transcript': _finalTranscript,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcript saved successfully!'), backgroundColor: Colors.green),
      );
      _resetState();

    } catch (e) {
      log('Error saving transcript: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not save transcript.'), backgroundColor: Colors.red),
      );
    }
  }
  
  void _resetState() {
    _chunkUploadTimer?.cancel();
    if(mounted) {
      setState(() {
        _recordingState = RecordingState.notStarted;
        _sessionId = null;
        _chunkCounter = 0;
        _transcripts = [];
        _finalTranscript = null;
      });
    }
  }

  // --- UI Build Methods ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.patientName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(child: _buildTranscriptArea()),
              const SizedBox(height: 20),
              _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptArea() {
    if (_finalTranscript != null) {
       return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green.shade200),
            borderRadius: BorderRadius.circular(8),
            color: Colors.green.shade50
          ),
          child: SingleChildScrollView(child: Text(_finalTranscript!)),
      );
    }

    if (_recordingState == RecordingState.notStarted && _transcripts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.mic_off_outlined, size: 80, color: Colors.grey),
             SizedBox(height: 16),
             Text('Recording has not started', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey.shade100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: _transcripts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(_transcripts[index]),
          );
        },
      ),
    );
  }

  Widget _buildControlButtons() {
    switch (_recordingState) {
      case RecordingState.notStarted:
        return ElevatedButton.icon(
          onPressed: _startRecording,
          icon: const Icon(Icons.mic),
          label: const Text('Start Recording'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
        );
      case RecordingState.recording:
      case RecordingState.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _togglePauseResume,
              icon: Icon(_recordingState == RecordingState.recording ? Icons.pause : Icons.play_arrow),
              label: Text(_recordingState == RecordingState.recording ? 'Pause' : 'Resume'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              onPressed: _endRecording,
              icon: const Icon(Icons.stop),
              label: const Text('End Recording'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ],
        );
      case RecordingState.sending:
        return const Column(
          children: [CircularProgressIndicator(), SizedBox(height: 10), Text('Initializing session...')],
        );
      case RecordingState.finalizing:
        return const Column(
          children: [CircularProgressIndicator(), SizedBox(height: 10), Text('Finalizing recording...')],
        );
      case RecordingState.finished:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _resetState,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Discard'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              onPressed: _saveTranscriptToServer,
              icon: const Icon(Icons.save_alt),
              label: const Text('Save Transcript'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ],
        );
    }
  }
}