import 'package:equatable/equatable.dart';
import '../../../data/models/entity/account_entity.dart';

abstract class AccountState extends Equatable {
  const AccountState();

  @override
  List<Object?> get props => [];
}

class AccountInitial extends AccountState {}

class AccountLoading extends AccountState {}

class AccountsLoaded extends AccountState {
  final List<AccountEntity> accounts;
  final List<AccountEntity> filteredAccounts;

  const AccountsLoaded({
    required this.accounts,
    required this.filteredAccounts,
  });

  @override
  List<Object> get props => [accounts, filteredAccounts];

  AccountsLoaded copyWith({
    List<AccountEntity>? accounts,
    List<AccountEntity>? filteredAccounts,
  }) {
    return AccountsLoaded(
      accounts: accounts ?? this.accounts,
      filteredAccounts: filteredAccounts ?? this.filteredAccounts,
    );
  }
}

class AccountError extends AccountState {
  final String message;

  const AccountError(this.message);

  @override
  List<Object> get props => [message];
}

class AccountOperationSuccess extends AccountState {
  final String message;

  const AccountOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}