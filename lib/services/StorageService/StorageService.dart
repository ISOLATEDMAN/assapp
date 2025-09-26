import 'dart:developer';


import 'dart:convert';
import 'package:assapp/models/Patient/Patient_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _patientsKey = 'patients_list';
  /// Save a list of patients to persistent storage.
  Future<void> savePatients(List<PatientModel> patients) async {
    final prefs = await SharedPreferences.getInstance();
    final patientsJson = jsonEncode(patients.map((e) => e.toJson()).toList());
    await prefs.setString(_patientsKey, patientsJson);
  }

  /// Retrieve the list of patients from persistent storage.
  Future<List<PatientModel>> getPatients() async {
    final prefs = await SharedPreferences.getInstance();
    final patientsJson = prefs.getString(_patientsKey);
    if (patientsJson == null) return [];
    final List<dynamic> decoded = jsonDecode(patientsJson);
    return decoded.map((e) => PatientModel.fromJson(e)).toList();
  }

  /// Add a patient to the list and save.
  Future<void> addPatient(PatientModel patient) async {
    final patients = await getPatients();
    patients.add(patient);
    await savePatients(patients);
  }
  static const String _tokenKey = 'auth_token';

  /// Saves the authentication token to persistent storage.
  Future<void> storingToken(String newToken) async {
    log("storing token ${newToken}");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);
  }

  /// Retrieves the authentication token from persistent storage.
  /// Returns null if no token is found.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Deletes the authentication token from storage (for logout).
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}