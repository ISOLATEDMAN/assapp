import 'dart:developer';
import 'package:assapp/models/Doctor/Base_Doctor_model.dart';
import 'package:assapp/services/StorageService/StorageService.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final Dio _dio;
  final String _baseUrl;
  // 1. Add a dependency on StorageService
  final StorageService _storageService;

  AuthService({
    Dio? dio,
    String? baseUrl,
    // 2. Require StorageService in the constructor
    required StorageService storageService,
  })  : _dio = dio ?? Dio(),
        // 3. The base URL should NOT contain the endpoint path
        _baseUrl = baseUrl ?? dotenv.env["BASE_API"] ?? "http://localhost:3000",
        _storageService = storageService;

  Future<BaseDoctorModel?> doLogin(String email) async {
    try {
      // 4. Construct the full URL here
      final String loginUrl = '$_baseUrl/v1/auth/login';
      log('Attempting to login to: $loginUrl');

      final response = await _dio.post(
        loginUrl,
        data: {'email': email},
      );

      if (response.statusCode == 200 && response.data != null) {
        // 5. IMPORTANT: Extract the token from the response map.
        // The key might be 'token', 'access_token', etc. - check your API docs.
        final String? token = response.data['token'];

        if (token != null) {
          // 6. Use the injected StorageService instance to save the token
          await _storageService.storingToken(token);
          log('Token stored successfully!');
        } else {
          log('Token not found in response body.');
        }

        return BaseDoctorModel.fromJson(response.data);
      } else {
        return null;
      }
    } on DioException catch (e) {
      // It's good practice to handle Dio-specific errors
      debugPrint('Login Dio error: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      debugPrint('Login generic error: $e');
      return null;
    }
  }
}