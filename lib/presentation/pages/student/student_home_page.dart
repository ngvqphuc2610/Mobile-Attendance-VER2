import 'package:flutter/material.dart';

import '../../../core/constants/app_theme.dart';

class StudentHomePage extends StatefulWidget {
  final String studentId;
  final ValueChanged<int>? onNavigateToTab;

  const StudentHomePage({
    super.key,
    required this.studentId,
    this.onNavigateToTab,
  });

  @override
  StudentHomePageState createState() => StudentHomePageState();
}

class StudentHomePageState extends State<StudentHomePage> {
  final ScrollController _scrollController = ScrollController();

  void scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSmall,
                  vertical: 6,
                ),
                child: Image.asset(
                  'assets/images/hutech_logo.png',
                  width: 120,
                  height: 44,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Text(
                  'Tri thuc - Dao duc - Sang tao',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Truy cap nhanh',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            _QuickActions(
              onNavigateToTab: widget.onNavigateToTab,
              studentId: widget.studentId,
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            Text(
              'Thong bao moi',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: Container(
                height: 180,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            Row(
              children: [
                Text(
                  'Tin noi bat',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _comingSoon(context),
                  child: const Text('Xem them'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              'Noi dung se duoc cap nhat sau.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tinh nang se som ra mat')),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;
  final String studentId;

  const _QuickActions({
    required this.onNavigateToTab,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppSizes.paddingMedium,
            crossAxisSpacing: AppSizes.paddingMedium,
            childAspectRatio: 1,
          ),
          children: [
            _QuickActionItem(
              icon: Icons.class_outlined,
              color: AppColors.primary,
              label: 'Lop hoc',
              onTap: () => onNavigateToTab?.call(1),
            ),
            _QuickActionItem(
              icon: Icons.calendar_month,
              color: AppColors.info,
              label: 'Thoi khoa bieu',
              onTap: () => onNavigateToTab?.call(2),
            ),
            _QuickActionItem(
              icon: Icons.qr_code_scanner,
              color: AppColors.secondary,
              label: 'Diem danh',
              onTap: () => onNavigateToTab?.call(3),
            ),
            _QuickActionItem(
              icon: Icons.task_alt_outlined,
              color: AppColors.success,
              label: 'Ket qua hoc tap',
              onTap: () => _comingSoon(context),
            ),
            _QuickActionItem(
              icon: Icons.article_outlined,
              color: AppColors.warning,
              label: 'Thong tin khoa',
              onTap: () => _comingSoon(context),
            ),
            _QuickActionItem(
              icon: Icons.support_agent,
              color: AppColors.error,
              label: 'Ho tro',
              onTap: () => _comingSoon(context),
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tinh nang se som ra mat')),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: color.withOpacity(.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            ),
            child: Icon(icon, color: color, size: AppSizes.iconLarge),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
