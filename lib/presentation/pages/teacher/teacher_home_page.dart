import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import 'TeacherShell.dart';

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMedium,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSmall,
                  vertical: 6,
                ),
                child: Image.asset(
                  'assets/images/hutech_logo.png',
                  width: 120, // tuỳ chỉnh kích thước
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Text(
                  'Tri thức - Đạo đức - Sáng tạo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Truy cập nhanh',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSizes.paddingSmall),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSizes.paddingMedium,
                  crossAxisSpacing: AppSizes.paddingMedium,
                  children: [
                    _quickAction(
                      context,
                      icon: Icons.school,
                      color: AppColors.info,
                      label: 'Eduzaa',
                      onTap: () => _comingSoon(context),
                    ),
                    _quickAction(
                      context,
                      icon: Icons.calendar_month,
                      color: AppColors.primary,
                      label: 'Thời khóa biểu',
                      onTap: () => _comingSoon(context),
                    ),
                    _quickAction(
                      context,
                      icon: Icons.event_available,
                      color: AppColors.success,
                      label: 'Lịch thi',
                      onTap: () => _comingSoon(context),
                    ),
                    _quickAction(
                      context,
                      icon: Icons.check_circle,
                      color: AppColors.secondary,
                      label: 'Điểm danh',
                      onTap: () {
                        TeacherShell.navigateToTab(context, 2);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.paddingLarge),

            Text(
              'Tuổi trẻ HUTECH kêu gọi chung tay khắc phục hậu quả bão Bualoi: Mỗi đóng góp - Một yêu thương gửi trao',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: Container(
                height: 180,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: Icon(Icons.image, size: 64, color: Colors.grey.shade400),
              ),
            ),

            const SizedBox(height: AppSizes.paddingLarge),

            Row(
              children: [
                Text(
                  'Tin HUTECH',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _comingSoon(context),
                  child: const Text('Xem thêm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: color.withOpacity(.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            ),
            child: Icon(icon, color: color, size: AppSizes.iconLarge),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tính năng sắp ra mắt')));
  }
}
