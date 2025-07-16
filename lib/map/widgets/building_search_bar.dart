// lib/map/widgets/building_search_bar.dart - 검색 기능만 담당

import 'package:flutter/material.dart';
import 'package:flutter_application_1/generated/app_localizations.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/map/widgets/search_screen.dart';

class BuildingSearchBar extends StatelessWidget {
  final Function(Building) onBuildingSelected;
  final VoidCallback? onSearchFocused;
  final VoidCallback? onDirectionsTap; // 🔥 길찾기 버튼 콜백 추가

  const BuildingSearchBar({
    super.key,
    required this.onBuildingSelected,
    this.onSearchFocused,
    this.onDirectionsTap, // 🔥 콜백만 받아서 전달
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // 검색창
          Expanded(
            flex: 4,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    onSearchFocused?.call();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchScreen(
                          onBuildingSelected: onBuildingSelected,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.indigo.shade400,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
Text(
  AppLocalizations.of(context)!.search_hint,
  style: TextStyle(
    color: Colors.grey.shade500,
    fontSize: 15,
  ),
),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 🔥 길찾기 버튼 - 단순히 콜백만 호출
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.indigo.shade600,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onDirectionsTap, // 🔥 단순히 콜백만 호출
                child: const Icon(
                  Icons.directions,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}