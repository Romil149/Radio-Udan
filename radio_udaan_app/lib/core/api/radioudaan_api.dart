import 'package:dio/dio.dart';

import '../../features/events/models/form_schema.dart';
import '../config/remote_config.dart';
import '../constants/app_constants.dart';
import '../models/app_notification.dart';
import '../models/auth_session.dart';
import '../models/event_summary.dart';
import '../models/youtube_video.dart';
import '../models/otp_purpose.dart';
import '../models/otp_request_result.dart';
import '../models/otp_verify_result.dart';
import '../models/radio_schedule.dart';
import '../models/register_result.dart';
import '../models/registration_result.dart';
import '../models/upload_result.dart';
import 'api_client.dart';
import 'api_error.dart';

/// Typed client for `radioudaan/v1` REST endpoints (WordPress App API plugin).
class RadioUdaanApi {
  RadioUdaanApi(this._client);

  final ApiClient _client;

  Dio get _dio => _client.dio;

  Future<Map<String, dynamic>> fetchConfigJson() async {
    final response = await _dio.get<Map<String, dynamic>>('/config');
    final data = response.data;
    if (data == null) {
      throw ApiError(message: 'Server returned an empty configuration.');
    }
    return data;
  }

  Future<RemoteConfig> fetchConfig() async {
    return RemoteConfig.fromJson(await fetchConfigJson());
  }

  Future<Map<String, dynamic>> health() async {
    final response = await _dio.get<Map<String, dynamic>>('/health');
    return response.data ?? {};
  }

  Future<OtpRequestResult> requestOtp(
    String phoneE164, {
    OtpPurpose purpose = OtpPurpose.login,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/otp/request',
      data: {
        'phone_e164': phoneE164,
        'purpose': purpose.apiValue,
      },
    );
    final data = response.data ?? {};
    return OtpRequestResult(
      requestId: data['request_id']?.toString() ?? '',
      expiresInSec: (data['expires_in_sec'] as num?)?.toInt() ?? 300,
      resendAfterSec: (data['resend_after_sec'] as num?)?.toInt() ?? 60,
      devOtp: data['dev_otp']?.toString(),
      purpose: OtpPurpose.tryParse(data['purpose']?.toString()),
    );
  }

  Future<OtpVerifyResult> verifyOtp({
    required String requestId,
    required String otp,
    OtpPurpose? purpose,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/otp/verify',
      data: {
        'request_id': requestId,
        'otp': otp,
        if (purpose != null) 'purpose': purpose.apiValue,
      },
    );
    return OtpVerifyResult.fromJson(response.data ?? {});
  }

  Future<RegisterResult> register({
    required String name,
    required String email,
    required String phoneE164,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'phone_e164': phoneE164,
        'password': password,
      },
    );
    return RegisterResult.fromJson(response.data ?? {});
  }

  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'identifier': identifier,
        'password': password,
      },
    );
    return AuthSession.fromJson(response.data ?? {});
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String identifier,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      data: {'identifier': identifier},
    );
    return response.data ?? {};
  }

  Future<void> resetPassword({
    String? token,
    String? code,
    String? phoneE164,
    String? otp,
    required String password,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/reset-password',
      data: {
        if (token != null && token.isNotEmpty) 'token': token,
        if (code != null && code.isNotEmpty) 'code': code,
        if (phoneE164 != null && phoneE164.isNotEmpty) 'phone_e164': phoneE164,
        if (otp != null && otp.isNotEmpty) 'otp': otp,
        'password': password,
      },
    );
  }

  Future<AuthSession> verifyEmail({required String code}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/email/verify',
      data: {'code': code},
    );
    return AuthSession.fromJson(response.data ?? {});
  }

  Future<void> resendVerificationEmail() async {
    await _dio.post<Map<String, dynamic>>('/auth/email/resend');
  }

  /// Returns null when the bearer token is missing or expired.
  Future<AuthSession?> fetchMe({String? bearerToken}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: bearerToken != null && bearerToken.isNotEmpty
            ? Options(headers: {'Authorization': 'Bearer $bearerToken'})
            : null,
      );
      final data = response.data ?? {};
      return AuthSession.fromJson(
        data,
        fallbackToken: bearerToken ?? '',
      );
    } on ApiError catch (e) {
      if (e.statusCode == 401) return null;
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<void> logout() async {
    await _dio.post<Map<String, dynamic>>('/auth/logout');
  }

  /// Deletes the app login record and revokes the current bearer token.
  Future<void> deleteAccount() async {
    await _dio.post<Map<String, dynamic>>('/auth/account/delete');
  }

  Future<List<EventSummary>> listEvents({String status = 'open'}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/events',
      queryParameters: {'status': status},
    );
    final items = response.data?['items'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(EventSummary.fromJson)
        .toList();
  }

  Future<FormSchema> getEventForm(int eventId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/events/$eventId/form',
    );
    final data = response.data;
    if (data == null) {
      throw ApiError(message: 'Server returned an empty form definition.');
    }
    return FormSchema.fromJson(data);
  }

  Future<UploadResult> uploadFile({
    required int eventId,
    required String fieldKey,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/uploads',
      data: formData,
      queryParameters: {
        'event_id': eventId,
        'field_key': fieldKey,
      },
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onSendProgress,
    );
    final items = response.data?['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) {
      throw ApiError(message: 'Upload did not return a file reference.');
    }
    final first = items.first as Map<String, dynamic>;
    return UploadResult(
      uploadId: first['upload_id']?.toString() ?? '',
      fileName: first['file_name']?.toString() ?? fileName,
    );
  }

  Future<RegistrationResult> submitRegistration({
    required int eventId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/events/$eventId/registrations',
      data: {
        'payload': payload,
        'client': {
          'platform': AppConstants.clientPlatform,
          'app_version': AppConstants.appVersion,
        },
      },
    );
    final data = response.data ?? {};
    return RegistrationResult(
      entryId: (data['entry_id'] as num?)?.toInt() ?? 0,
      status: data['status']?.toString() ?? 'submitted',
    );
  }

  Future<YoutubeVideoListResponse> listYoutubeRecent({int perPage = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/library/youtube/recent',
      queryParameters: {'per_page': perPage},
    );
    return YoutubeVideoListResponse.fromJson(response.data ?? {});
  }

  Future<YoutubeVideoListResponse> searchYoutubeVideos({
    required String query,
    int page = 1,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/library/youtube/search',
      queryParameters: {
        'q': query.trim(),
        'page': page,
      },
    );
    return YoutubeVideoListResponse.fromJson(response.data ?? {});
  }

  Future<YoutubePlaylistListResponse> listFeaturedYoutubePlaylists() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/library/youtube/playlists/featured',
    );
    return YoutubePlaylistListResponse.fromJson(response.data ?? {});
  }

  Future<YoutubePlaylistListResponse> listYoutubePlaylists({int page = 1}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/library/youtube/playlists',
      queryParameters: {'page': page},
    );
    return YoutubePlaylistListResponse.fromJson(response.data ?? {});
  }

  Future<YoutubeVideoListResponse> listYoutubePlaylistVideos(
    String playlistId, {
    int page = 1,
  }) async {
    final id = playlistId.trim();
    final response = await _dio.get<Map<String, dynamic>>(
      '/library/youtube/playlists/$id/videos',
      queryParameters: {'page': page},
    );
    return YoutubeVideoListResponse.fromJson(response.data ?? {});
  }

  Future<RadioScheduleResponse> fetchRadioSchedule({int days = 2}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/library/schedule',
      queryParameters: {'days': days},
    );
    return RadioScheduleResponse.fromJson(response.data ?? {});
  }

  Future<ProfileUpdateResult> updateProfile({
    String? name,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;

    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/me',
      data: data,
    );
    final body = response.data ?? {};
    final user = body['user'] as Map<String, dynamic>? ?? {};
    final current = await fetchMe();
    final session = AuthSession.fromJson(
      {'user': user},
      fallbackToken: current?.token ?? '',
    );
    return ProfileUpdateResult(
      session: session,
      emailVerificationSent: body['email_verification_sent'] == true,
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/change-password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  Future<AuthSession> uploadAvatar({
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/avatar',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final body = response.data ?? {};
    final user = body['user'] as Map<String, dynamic>? ?? {};
    final current = await fetchMe();
    return AuthSession.fromJson(
      {'user': user},
      fallbackToken: current?.token ?? '',
    );
  }

  Future<int> submitSupportContact({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/support/contact',
      data: {
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
      },
    );
    return (response.data?['message_id'] as num?)?.toInt() ?? 0;
  }

  Future<void> registerPushDevice({
    required String fcmToken,
    required String platform,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/devices/register',
      data: {
        'fcm_token': fcmToken,
        'platform': platform,
      },
    );
  }

  Future<NotificationListResult> listNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return NotificationListResult.fromJson(response.data ?? {});
  }

  Future<AppNotification> markNotificationRead(int id) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/notifications/$id',
    );
    final notification =
        response.data?['notification'] as Map<String, dynamic>? ?? response.data;
    return AppNotification.fromJson(notification ?? {});
  }

  Future<NotificationPreferences> fetchNotificationPreferences() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/auth/notification-preferences',
    );
    return NotificationPreferences.fromJson(response.data ?? {});
  }

  Future<NotificationPreferences> updateNotificationPreferences({
    bool? liveBroadcastsEnabled,
    bool? eventsEnabled,
    bool? promotionsEnabled,
  }) async {
    final data = <String, dynamic>{};
    if (liveBroadcastsEnabled != null) {
      data['live_broadcasts_enabled'] = liveBroadcastsEnabled;
    }
    if (eventsEnabled != null) {
      data['events_enabled'] = eventsEnabled;
    }
    if (promotionsEnabled != null) {
      data['promotions_enabled'] = promotionsEnabled;
    }
    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/notification-preferences',
      data: data,
    );
    return NotificationPreferences.fromJson(response.data ?? {});
  }
}
