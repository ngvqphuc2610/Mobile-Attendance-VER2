import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_attendance/data/models/entity/account_entity.dart';
import 'package:mobile_attendance/presentation/bloc/account/account_bloc.dart';
import 'package:mobile_attendance/presentation/bloc/account/account_event.dart';
import '../../../core/constants/app_theme.dart';
import 'add/AddAccountPage.dart';
import 'List/AdminAccountList.dart';
import 'edit/EditAccountPage.dart';

class AdminAccounts extends StatefulWidget {
  final List<AccountEntity> accounts;
  const AdminAccounts({super.key, required this.accounts});

  @override
  State<AdminAccounts> createState() => _AdminAccountsState();
}

class _AdminAccountsState extends State<AdminAccounts> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddAccountPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddAccountPage()),
    );
  }

  void _showEditAccountPage(AccountEntity account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAccountPage(account: account.toJson()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài khoản'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddAccountPage,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm theo tên, email...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
              ),
              onChanged: (query) {
                context.read<AccountBloc>().add(FilterAccounts(query));
              },
            ),
          ),
          Expanded(child: AdminAccountList()),
        ],
      ),
    );
  }
}
