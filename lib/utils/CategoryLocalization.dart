// lib/utils/category_localization.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/generated/app_localizations.dart';

class CategoryLocalization {
  static String getLabel(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;

    // 🔥 서버에서 받은 원본 카테고리 이름 처리
    switch (id) {
      // 영어 ID들
      case 'cafe': return l10n.cafe;
      case 'restaurant': return l10n.restaurant;
      case 'convenience': return l10n.convenience_store;
      case 'vending': return l10n.vending_machine;
      case 'water': return l10n.water_purifier;
      case 'printer': return l10n.printer;
      case 'copier': return l10n.copier;
      case 'atm': return l10n.atm;
      case 'bank_atm': return l10n.bank_atm;
      case 'bank': return l10n.atm;
      case 'fire_extinguisher': return l10n.extinguisher;
      case 'water_purifier': return l10n.water_purifier;
      case 'post_office': return l10n.post_office;
      case 'post': return l10n.post_office;
      case 'medical': return l10n.medical;
      case 'health_center': return l10n.health_center;
      case 'library': return l10n.library;
      case 'bookstore': return l10n.bookstore;
      case 'gym': return l10n.gym;
      case 'fitness_center': return l10n.fitness_center;
      case 'lounge': return l10n.lounge;
      case 'extinguisher': return l10n.extinguisher;

      // 🔥 서버에서 받은 한국어 카테고리 이름들
      case '카페': return l10n.cafe;
      case '식당': return l10n.restaurant;
      case '편의점': return l10n.convenience_store;
      case '자판기': return l10n.vending_machine;
      case '정수기': return l10n.water_purifier;
      case '프린터': return l10n.printer;
      case '복사기': return l10n.copier;
      case 'ATM': return l10n.atm;
      case '은행(atm)': return l10n.atm;
      case '소화기': return l10n.extinguisher;
      case '우체국': return l10n.post_office;
      case '의료': return l10n.medical;
      case '보건소': return l10n.health_center;
      case '도서관': return l10n.library;
      case '서점': return l10n.bookstore;
      case '헬스장': return l10n.gym;
      case '체육관': return l10n.fitness_center;
      case '라운지': return l10n.lounge;

      default:
        // 🔥 알 수 없는 카테고리는 그대로 표시
        return id;
    }
  }
}
