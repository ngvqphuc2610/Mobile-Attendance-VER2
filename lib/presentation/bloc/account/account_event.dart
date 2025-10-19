import 'package:equatable/equatable.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class LoadAccounts extends AccountEvent {
  const LoadAccounts();
}

class ToggleAccountStatus extends AccountEvent {
  final String accountId;

  const ToggleAccountStatus(this.accountId);

  @override
  List<Object> get props => [accountId];
}

class ResetPassword extends AccountEvent {
  final String accountId;

  const ResetPassword(this.accountId);

  @override
  List<Object> get props => [accountId];
}
class DeleteAccount extends AccountEvent {
  final String accountId;

  const DeleteAccount(this.accountId);

  @override
  List<Object> get props => [accountId];
}

class FilterAccounts extends AccountEvent {
  final String query;

  const FilterAccounts(this.query);

  @override
  List<Object> get props => [query];
}