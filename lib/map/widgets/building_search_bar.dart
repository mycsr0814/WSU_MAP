// lib/map/widgets/building_search_bar.dart - 새 창 열기 방식으로 수정

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/map/widgets/search_screen.dart';
import '../../generated/app_localizations.dart';

class BuildingSearchBar extends StatelessWidget {
  final Function(Building) onBuildingSelected;
  final VoidCallback? onSearchFocused;

  const BuildingSearchBar({
    super.key,
    required this.onBuildingSelected,
    this.onSearchFocused,
  });

  void _openSearchScreen(BuildContext context) {
    // 검색 화면이 포커스될 때 콜백 호출
    onSearchFocused?.call();
    
    // 전체 화면 검색 창 열기
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          onBuildingSelected: onBuildingSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return _buildSearchBar(context, l10n);
  }

  Widget _buildSearchBar(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _openSearchScreen(context),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.search,
                color: Colors.indigo.shade400,
                size: 22,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  l10n.search_campus_buildings,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}