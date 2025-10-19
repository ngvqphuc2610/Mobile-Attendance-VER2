import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/entity/account_entity.dart';
import '../../../../data/models/entity/profile_entity.dart';
import '../../../bloc/account/account_bloc.dart';
import '../../../bloc/account/account_event.dart';
import '../../../bloc/account/account_state.dart';
import '../../../widgets/loading_widget.dart';
import '../Edit/EditAccountPage.dart';

class AdminAccountList extends StatefulWidget {
  const AdminAccountList({Key? key}) : super(key: key);

  @override
  _AdminAccountListState createState() => _AdminAccountListState();
}

class _AdminAccountListState extends State<AdminAccountList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AccountBloc>().add(const LoadAccounts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAccounts(String query) {
    context.read<AccountBloc>().add(FilterAccounts(query));
  }

  void _toggleStatus(AccountEntity account) {
    context.read<AccountBloc>().add(ToggleAccountStatus(account.id));
  }

  void _resetPassword(AccountEntity account) {
    context.read<AccountBloc>().add(ResetPassword(account.id));
  }

  void _deleteAccount(AccountEntity account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa tài khoản "${account.profile?.fullName ?? account.email}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AccountBloc>().add(DeleteAccount(account.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditAccountPage(AccountEntity account) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditAccountPage(account: account),
      ),
    );

    if (updated == true && mounted) {
      context.read<AccountBloc>().add(const LoadAccounts());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        if (state is AccountLoading) {
          return const LoadingWidget(message: 'Đang tải danh sách tài khoản...');
        } else if (state is AccountError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Lỗi: ${state.message}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<AccountBloc>().add(const LoadAccounts()),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        } else if (state is AccountsLoaded) {
          if (state.filteredAccounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    state.accounts.isEmpty 
                      ? 'Chưa có tài khoản nào' 
                      : 'Không tìm thấy kết quả',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            itemCount: state.filteredAccounts.length,
            itemBuilder: (context, index) {
              final account = state.filteredAccounts[index];
              return _buildAccountCard(account);
            },
          );
        }

        return const Center(child: Text('Không có dữ liệu'));
      },
    );
  }

  Widget _buildAccountCard(AccountEntity account) {
    final profile = account.profile;
    final role = account.userRole;
    final isActive = account.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      elevation: 2,
      child: ListTile(
        // QUAN TRỌNG: Thêm onTap để navigate đến trang edit
        onTap: () => _showEditAccountPage(account),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: isActive ? AppColors.secondary : Colors.grey,
              child: Text(
                profile?.fullName.substring(0, 1).toUpperCase() ?? 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!isActive)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          profile?.fullName ?? 'Chưa có tên',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (profile?.code != null) 
              Text('Mã: ${profile!.code}', style: TextStyle(fontSize: 12)),
            Text(
              account.email,
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
            Row(
              children: [
                Icon(
                  _getRoleIcon(role?.role),
                  size: 14,
                  color: _getRoleColor(role?.role),
                ),
                const SizedBox(width: 4),
                Text(
                  _getRoleText(role?.role),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getRoleColor(role?.role),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Đã khóa',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditAccountPage(account);
                break;
              case 'toggle_status':
                _toggleStatus(account);
                break;
              case 'reset_password':
                _resetPassword(account);
                break;
              case 'delete':
                _deleteAccount(account);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Chỉnh sửa'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'toggle_status',
              child: ListTile(
                leading: Icon(
                  isActive ? Icons.block : Icons.check_circle,
                  color: isActive ? Colors.orange : Colors.green,
                ),
                title: Text(isActive ? 'Khóa tài khoản' : 'Mở khóa'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'reset_password',
              child: ListTile(
                leading: Icon(Icons.lock_reset, color: Colors.orange),
                title: Text('Reset mật khẩu'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Xóa', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'teacher':
        return Icons.school;
      case 'student':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'teacher':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleText(String? role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'teacher':
        return 'Giáo viên';
      case 'student':
        return 'Sinh viên';
      default:
        return 'Chưa xác định';
    }
  }
}