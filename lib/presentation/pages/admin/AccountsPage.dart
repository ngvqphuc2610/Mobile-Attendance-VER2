import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/services/account_service.dart';
import 'Add/AddAccountPage.dart';
import 'Edit/EditAccountPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final _accountService = AccountService();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _filteredAccounts = [];
  bool _loading = true;
  String? _error;
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('''
            id, code, full_name, is_active, email, phone, created_at
          ''')
          .order('full_name');

      // Đảm bảo response là List
      if (response is List) {
        _accounts = List<Map<String, dynamic>>.from(response);

        // Load roles riêng biệt cho mỗi user
        for (var account in _accounts) {
          try {
            final roleResponse = await Supabase.instance.client
                .from('user_roles')
                .select('role')
                .eq('user_id', account['id'])
                .maybeSingle();

            account['role'] = roleResponse?['role'] ?? 'student';
          } catch (e) {
            account['role'] = 'student'; // fallback
          }
        }

        _filteredAccounts = List.from(_accounts);
        _filterAccounts( _searchController.text,
          );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterAccounts(String query) {
    setState(() {
      List<Map<String, dynamic>> filtered = _accounts;

      // Filter by search query
      if (query.isNotEmpty) {
        filtered = filtered.where((account) {
          final name = account['full_name']?.toString().toLowerCase() ?? '';
          final code = account['code']?.toString().toLowerCase() ?? '';
          final email = account['email']?.toString().toLowerCase() ?? '';

          return name.contains(query.toLowerCase()) ||
                 code.contains(query.toLowerCase()) ||
                 email.contains(query.toLowerCase());
        }).toList();
      }

      // Filter by role
      if (_roleFilter != null) {
        filtered = filtered.where((account) {
          return account['role'] == _roleFilter;
        }).toList();
      }

      _filteredAccounts = filtered;
    });
  }

  String _getRoleText(Map<String, dynamic> account) {
    final role = account['role'] ?? 'student';
    switch (role) {
      case 'admin':
        return 'Quản trị';
      case 'teacher':
        return 'Giáo viên';
      case 'student':
      default:
        return 'Sinh viên';
    }
  }

  String _getSubtitle(Map<String, dynamic> account) {
    final parts = <String>[];

    if (account['code'] != null) {
      parts.add('Mã: ${account['code']}');
    }

    if (account['email'] != null) {
      parts.add('${account['email']}');
    }

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Tài khoản'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _navigateToAdd),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm tài khoản...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _filterAccounts,
                ),
                
                const SizedBox(height: AppSizes.paddingMedium),
                
                // Role filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _roleFilter == null,
                        onSelected: (selected) {
                          setState(() => _roleFilter = null);
                          _filterAccounts(_searchController.text);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Sinh viên'),
                        selected: _roleFilter == 'student',
                        onSelected: (selected) {
                          setState(() => _roleFilter = selected ? 'student' : null);
                          _filterAccounts(_searchController.text);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Giáo viên'),
                        selected: _roleFilter == 'teacher',
                        onSelected: (selected) {
                          setState(() => _roleFilter = selected ? 'teacher' : null);
                          _filterAccounts(_searchController.text);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Quản trị'),
                        selected: _roleFilter == 'admin',
                        onSelected: (selected) {
                          setState(() => _roleFilter = selected ? 'admin' : null);
                          _filterAccounts(_searchController.text);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAccounts,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : _filteredAccounts.isEmpty
                ? const Center(child: Text('Không có tài khoản nào'))
                : RefreshIndicator(
                    onRefresh: _loadAccounts,
                    child: ListView.builder(
                      itemCount: _filteredAccounts.length,
                      itemBuilder: (context, index) {
                        final account = _filteredAccounts[index];
                        final isActive = account['is_active'] ?? true;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingMedium,
                            vertical: AppSizes.paddingSmall,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isActive
                                  ? AppColors.primary
                                  : AppColors.error,
                              child: Text(
                                account['full_name']?.isNotEmpty == true
                                    ? account['full_name'][0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    account['full_name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getRoleText(account),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_getSubtitle(account)),
                                if (!isActive)
                                  const Text(
                                    'Tài khoản bị vô hiệu hóa',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Sửa'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: isActive ? 'disable' : 'enable',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isActive
                                            ? Icons.block
                                            : Icons.check_circle,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isActive ? 'Vô hiệu hóa' : 'Kích hoạt',
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        'Xóa',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _navigateToEdit(account);
                                } else if (value == 'disable' ||
                                    value == 'enable') {
                                  _toggleAccountStatus(account);
                                } else if (value == 'delete') {
                                  _confirmDelete(account);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddAccountPage()),
    );

    if (result == true) {
      _loadAccounts();
    }
  }

  Future<void> _navigateToEdit(Map<String, dynamic> account) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAccountPage(account: account),
      ),
    );

    if (result == true) {
      _loadAccounts();
    }
  }

  Future<void> _toggleAccountStatus(Map<String, dynamic> account) async {
    final isActive = account['is_active'] ?? true;
    final action = isActive ? 'disable' : 'enable';

    try {
      await _accountService.disableAccount(
        userId: account['id'],
        action: action,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive ? 'Đã vô hiệu hóa tài khoản' : 'Đã kích hoạt tài khoản',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadAccounts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa tài khoản "${account['full_name']}"?\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _accountService.disableAccount(
          userId: account['id'],
          action: 'delete',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa tài khoản thành công'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAccounts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa tài khoản: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

