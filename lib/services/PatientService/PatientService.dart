import 'dart:developer';
import 'package:assapp/models/Patient/Patient_model.dart';
import 'package:assapp/services/StorageService/StorageService.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PatientService {
  final Dio _dio;
  final String _baseUrl;

  PatientService({
    Dio? dio,
    String? baseUrl,
  }) : _dio = dio ?? Dio(),
        _baseUrl = baseUrl ?? dotenv.env["BASE_API"] ?? "http://localhost:3000";

  // FIXED: Only take patient name, let server get userId from auth token
  Future<PatientModel?> createPatient(String patientName) async {
    try {
      final String patientUrl = '$_baseUrl/v1/add-Patient';
      log("Creating a patient: $patientName");

      final storageService = StorageService();
      final String? token = await storageService.getToken();

      if (token == null) {
        log("No auth token found");
        return null;
      }

      final response = await _dio.post(
        patientUrl,
        data: {
          "name": patientName,
          // Removed userId - server gets it from auth token
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      log("Create patient response: ${response.toString()}");

      // FIXED: Check for 201 status code (created) instead of 200
      if (response.statusCode == 201 && response.data != null) {
        final data = response.data;
        if (data['patient'] != null) {
          final patient = PatientModel.fromJson(data['patient']);
          await storageService.addPatient(patient);
          log("Patient created successfully with ID: ${patient.id}");
          return patient;
        }
      }
    } catch (error) {
      log("Error creating the patient: $error");
      if (error is DioException) {
        log("DioException details: ${error.response?.data}");
      }
    }
    return null;
  }

  // Get all patients for the current user
  Future<List<PatientModel>> getPatients() async {
    try {
      final String patientsUrl = '$_baseUrl/v1/patients';
      final storageService = StorageService();
      final String? token = await storageService.getToken();

      if (token == null) {
        log("No auth token found");
        return [];
      }

      final response = await _dio.get(
        patientsUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      log("Get patients response: ${response.toString()}");

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['patients'] != null) {
          final List<dynamic> patientsJson = data['patients'];
          return patientsJson.map((json) => PatientModel.fromJson(json)).toList();
        }
      }
    } catch (error) {
      log("Error fetching patients: $error");
      if (error is DioException) {
        log("DioException details: ${error.response?.data}");
      }
    }
    return [];
  }

  // Save transcript to a patient's record
  Future<bool> saveTranscript({
    required String patientId,
    required String sessionId,
    required String transcript,
  }) async {
    try {
      final String saveTranscriptUrl = '$_baseUrl/v1/save-transcript';
      final storageService = StorageService();
      final String? token = await storageService.getToken();

      if (token == null) {
        log("No auth token found");
        return false;
      }

      log("Saving transcript for patient: $patientId, session: $sessionId");

      final response = await _dio.post(
        saveTranscriptUrl,
        data: {
          'patientId': patientId,
          'sessionId': sessionId,
          'transcript': transcript,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      log("Save transcript response: ${response.toString()}");

      if (response.statusCode == 200) {
        log("Transcript saved successfully");
        return true;
      }
    } catch (error) {
      log("Error saving transcript: $error");
      if (error is DioException) {
        log("DioException details: ${error.response?.data}");
        log("Response status code: ${error.response?.statusCode}");
      }
    }
    return false;
  }

  Future<void> sendCompleteRec() async {
    // Implementation for sending complete recording
  }

  Future<PatientModel?> getPatientDetails(String patientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('x-auth-token');
      // NOTE: Replace 'your_base_url' with your actual API base URL
      final response = await http.get(
        Uri.parse('your_base_url/api/patient-details/$patientId'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The API returns { "patient": { ... } }, so we extract the nested object
        return PatientModel.fromJson(data['patient']);
      } else {
        print('Failed to load patient details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching patient details: $e');
      return null;
    }
  }
}