// lib/utils/category_localization.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/generated/app_localizations.dart';

class CategoryLocalization {
  static String getLabel(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;

    switch (id) {
      case 'cafe': return l10n.cafe;
      case 'restaurant': return l10n.restaurant;
      case 'convenience': return l10n.convenience_store;
      case 'vending': return l10n.vending_machine;
      case 'water': return l10n.water_purifier;
      case 'printer': return l10n.printer;
      case 'copier': return l10n.copier;
      case 'atm': return l10n.atm;
      case 'bank_atm': return l10n.bank_atm;
      case 'medical': return l10n.medical;
      case 'health_center': return l10n.health_center;
      case 'library': return l10n.library;
      case 'bookstore': return l10n.bookstore;
      case 'post_office': return l10n.post_office;
      case 'gym': return l10n.gym;
      case 'fitness_center': return l10n.fitness_center;
      case 'lounge': return l10n.lounge;
      case 'extinguisher': return l10n.extinguisher;

      default:
        return id; // fallback: 번역 키가 없을 경우 그냥 그대로 노출
    }
  }
}
