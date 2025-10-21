import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/enrollment_repository.dart';
import 'enrollment_event.dart';
import 'enrollment_state.dart';

class EnrollmentBloc extends Bloc<EnrollmentEvent, EnrollmentState> {
  final EnrollmentRepository _repository;

  EnrollmentBloc({required EnrollmentRepository repository})
    : _repository = repository,
      super(EnrollmentInitial()) {
    on<LoadEnrollments>(_onLoadEnrollments);
    on<CreateEnrollment>(_onCreateEnrollment);
    on<DeleteEnrollment>(_onDeleteEnrollment);
    on<FilterEnrollments>(_onFilterEnrollments);
  }

  Future<void> _onLoadEnrollments(
    LoadEnrollments event,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(EnrollmentLoading());

    try {
      final enrollments = await _repository.getEnrollments(
        sectionId: event.sectionId,
        studentId: event.studentId,
      );

      emit(
        EnrollmentsLoaded(
          enrollments: enrollments,
          filteredEnrollments: enrollments,
        ),
      );
    } catch (e) {
      emit(EnrollmentError(e.toString()));
    }
  }

  Future<void> _onCreateEnrollment(
    CreateEnrollment event,
    Emitter<EnrollmentState> emit,
  ) async {
    try {
      await _repository.createEnrollment(
        sectionId: event.sectionId,
        studentId: event.studentId,
      );

      emit(const EnrollmentOperationSuccess('Đăng ký học phần thành công'));
      add(LoadEnrollments(sectionId: event.sectionId));
    } catch (e) {
      emit(EnrollmentError(e.toString()));
    }
  }

  Future<void> _onDeleteEnrollment(
    DeleteEnrollment event,
    Emitter<EnrollmentState> emit,
  ) async {
    try {
      await _repository.deleteEnrollment(
        sectionId: event.sectionId,
        studentId: event.studentId,
      );

      emit(const EnrollmentOperationSuccess('Hủy đăng ký học phần thành công'));
      add(LoadEnrollments(sectionId: event.sectionId));
    } catch (e) {
      emit(EnrollmentError(e.toString()));
    }
  }

  void _onFilterEnrollments(
    FilterEnrollments event,
    Emitter<EnrollmentState> emit,
  ) {
    final currentState = state;
    if (currentState is EnrollmentsLoaded) {
      if (event.query.trim().isEmpty) {
        emit(
          currentState.copyWith(filteredEnrollments: currentState.enrollments),
        );
        return;
      }

      final query = event.query.toLowerCase();
      final filtered = currentState.enrollments.where((enrollment) {
        final studentName = enrollment.student?.fullName?.toLowerCase() ?? '';
        final sectionName =
            enrollment.section?.sectionCode?.toLowerCase() ?? '';

        return studentName.contains(query) || sectionName.contains(query);
      }).toList();

      emit(currentState.copyWith(filteredEnrollments: filtered));
    }
  }
}
