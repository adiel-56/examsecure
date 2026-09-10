import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_theme.dart';

/// Skeleton loading réutilisé sur tous les écrans à liste (section 31).
class LoadingList extends StatelessWidget {
  final int itemCount;
  const LoadingList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.bg,
      child: Column(
        children: List.generate(
          itemCount,
          (i) => Container(
            height: 66,
            margin: const EdgeInsets.only(bottom: 9),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
