// lib/map/widgets/map_controls.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/controllers/map_controller.dart';
import 'package:flutter_application_1/managers/location_manager.dart';

class MapControls extends StatelessWidget {
  final MapScreenController controller;
  final VoidCallback? onMyLocationPressed;

  const MapControls({
    super.key,
    required this.controller,
    this.onMyLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationManager>(
      builder: (context, locationManager, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactControlButton(
              onPressed: () => controller.toggleBuildingMarkers(),
              icon: controller.buildingMarkersVisible ? Icons.location_on : Icons.location_off,
              color: controller.buildingMarkersVisible
                  ? const Color(0xFF1E3A8A)
                  : Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            _buildMyLocationButton(locationManager),
          ],
        );
      },
    );
  }

  Widget _buildMyLocationButton(LocationManager locationManager) {
    final bool isLoading = locationManager.isRequestingLocation;
    final bool hasLocation = locationManager.hasValidLocation;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onMyLocationPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: hasLocation
                  ? const Color(0xFF1E3A8A).withOpacity(0.3)
                  : Colors.grey.shade200,
              width: hasLocation ? 2 : 1,
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
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFF1E3A8A),
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  hasLocation ? Icons.my_location : Icons.location_searching,
                  color: const Color(0xFF1E3A8A),
                  size: 24,
                ),
        ),
      ),
    );
  }

  Widget _buildCompactControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
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
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }
}