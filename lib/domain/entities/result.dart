class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory Result.success(T data) {
    return Result._(
      data: data,
      isSuccess: true,
    );
  }

  factory Result.failure(String error) {
    return Result._(
      error: error,
      isSuccess: false,
    );
  }

  bool get isFailure => !isSuccess;
}