import 'package:equatable/equatable.dart';

abstract class SectionScheduleEvent extends Equatable {
  const SectionScheduleEvent();

  @override
  List<Object?> get props => [];
}

class LoadSectionSchedules extends SectionScheduleEvent {
  final String? sectionId;

  const LoadSectionSchedules({this.sectionId});

  @override
  List<Object?> get props => [sectionId];
}

class CreateSectionSchedule extends SectionScheduleEvent {
  final Map<String, dynamic> payload;

  const CreateSectionSchedule(this.payload);

  @override
  List<Object> get props => [payload];
}

class UpdateSectionSchedule extends SectionScheduleEvent {
  final String id;
  final Map<String, dynamic> payload;

  const UpdateSectionSchedule(this.id, this.payload);

  @override
  List<Object> get props => [id, payload];
}

class DeleteSectionSchedule extends SectionScheduleEvent {
  final String id;

  const DeleteSectionSchedule(this.id);

  @override
  List<Object> get props => [id];
}

class FilterSectionSchedules extends SectionScheduleEvent {
  final String query;

  const FilterSectionSchedules(this.query);

  @override
  List<Object> get props => [query];
}
