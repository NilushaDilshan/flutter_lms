import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;

  // Track if a retry has already occurred for a request
  static const String _retryHeaderKey = 'x-has-retried-refresh';

  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio dio,
  })  : _tokenStorage = tokenStorage,
        _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Check if the request is to a public auth endpoint that doesn't need Bearer token
    final isPublicAuth = options.path.contains('/api/v1/auth/login') ||
        options.path.contains('/api/v1/auth/register') ||
        options.path.contains('/api/v1/auth/verify-email') ||
        options.path.contains('/api/v1/auth/resend-verification-otp') ||
        options.path.contains('/api/v1/auth/forgot-password') ||
        options.path.contains('/api/v1/auth/verify-reset-otp') ||
        options.path.contains('/api/v1/auth/reset-password') ||
        options.path.contains('/api/v1/auth/refresh-token');

    if (!isPublicAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    // Only handle 401 Unauthorized
    if (response?.statusCode == 401) {
      // Rule 1: Do not refresh if the failed request was already refresh-token or login
      final isAuthEndpoint = requestOptions.path.contains(ApiEndpoints.refreshToken) ||
          requestOptions.path.contains(ApiEndpoints.login);

      // Rule 2: Do not retry more than once
      final hasRetried = requestOptions.headers[_retryHeaderKey] == 'true';

      if (isAuthEndpoint || hasRetried) {
        // If refresh-token endpoint itself failed with 401, session is invalid -> clear storage
        if (requestOptions.path.contains(ApiEndpoints.refreshToken)) {
          await _tokenStorage.clear();
        }
        return handler.next(err);
      }

      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _tokenStorage.clear();
        return handler.next(err);
      }

      try {
        // Call backend refresh token endpoint using an isolated Dio instance to prevent infinite loop
        final refreshDio = Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        final refreshResponse = await refreshDio.post(
          ApiEndpoints.refreshToken,
          data: {'refreshToken': refreshToken},
        );

        if (refreshResponse.statusCode == 200 || refreshResponse.statusCode == 201) {
          final data = refreshResponse.data;
          String? newAccessToken;
          String? newRefreshToken;

          if (data is Map<String, dynamic> && data['data'] != null) {
            final tokens = data['data']['tokens'];
            if (tokens != null) {
              newAccessToken = tokens['accessToken']?.toString();
              newRefreshToken = tokens['refreshToken']?.toString();
            }
          }

          if (newAccessToken != null && newRefreshToken != null) {
            // Update stored tokens
            await _tokenStorage.updateTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );

            // Mark request as retried and attach new token
            requestOptions.headers[_retryHeaderKey] = 'true';
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

            // Retry the original request
            final retriedResponse = await _dio.fetch(requestOptions);
            return handler.resolve(retriedResponse);
          }
        }
      } catch (refreshError) {
        // Refresh token failed or expired -> clear session
        await _tokenStorage.clear();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
