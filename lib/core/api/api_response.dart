class ApiResponse<T> {
  final String status;
  final String? message;
  final T? data;

  ApiResponse({
    required this.status,
    this.message,
    this.data,
  });

  bool get isSuccess => status == 'success';

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      status: json['status'] as String? ?? 'success',
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }
}
