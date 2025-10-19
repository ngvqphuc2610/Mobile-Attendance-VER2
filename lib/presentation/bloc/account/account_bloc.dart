import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/account_repository.dart';
import 'account_event.dart';
import 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository _repository;

  AccountBloc({required AccountRepository repository})
      : _repository = repository,
        super(AccountInitial()) {
    on<LoadAccounts>(_onLoadAccounts);
    on<ToggleAccountStatus>(_onToggleAccountStatus);
    on<ResetPassword>(_onResetPassword);
    on<FilterAccounts>(_onFilterAccounts);
  }

  Future<void> _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());

    try {
      final accounts = await _repository.getAccounts();
      emit(AccountsLoaded(
        accounts: accounts,
        filteredAccounts: accounts,
      ));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onToggleAccountStatus(
    ToggleAccountStatus event,
    Emitter<AccountState> emit,
  ) async {
    try {
      await _repository.toggleAccountStatus(event.accountId);
      emit(const AccountOperationSuccess('Cập nhật trạng thái tài khoản thành công'));
      add(const LoadAccounts());
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onResetPassword(
    ResetPassword event,
    Emitter<AccountState> emit,
  ) async {
    try {
      await _repository.resetPassword(event.accountId);
      emit(const AccountOperationSuccess('Reset mật khẩu thành công'));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  void _onFilterAccounts(
    FilterAccounts event,
    Emitter<AccountState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoaded) {
      if (event.query.trim().isEmpty) {
        emit(currentState.copyWith(filteredAccounts: currentState.accounts));
        return;
      }

      final query = event.query.toLowerCase();
      final filtered = currentState.accounts.where((account) {
        return account.email.toLowerCase().contains(query) ||
               (account.profile?.fullName.toLowerCase().contains(query) ?? false) ||
               (account.username?.toLowerCase().contains(query) ?? false);
      }).toList();

      emit(currentState.copyWith(filteredAccounts: filtered));
    }
  }
}