import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SpinKitFadingCircle(color: AppColors.primary, size: 50.0),
          if (message != null) const SizedBox(height: AppSizes.paddingMedium),
          if (message != null)
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
