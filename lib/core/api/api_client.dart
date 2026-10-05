import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio dio;
  final TokenStorage tokenStorage;

  ApiClient({
    TokenStorage? tokenStorage,
    Dio? customDio,
  }) : tokenStorage = tokenStorage ?? TokenStorage() {
    dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            sendTimeout: AppConfig.sendTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            validateStatus: (status) => status != null && status >= 200 && status < 300,
          ),
        );

    // Attach AuthInterceptor
    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: this.tokenStorage,
        dio: dio,
      ),
    );
  }

  // GET Request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // POST Request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // PUT Request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // PATCH Request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // DELETE Request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Multipart / Form Data Upload
  // Per task plan rules: "Let Dio generate multipart boundaries, avoid manual Content-Type header override"
  Future<Response<T>> uploadMultipart<T>(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final uploadOptions = (options ?? Options()).copyWith(
        contentType: 'multipart/form-data',
      );

      return await dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: uploadOptions,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
