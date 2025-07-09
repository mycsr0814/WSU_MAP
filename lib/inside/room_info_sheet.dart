import 'package:flutter/material.dart';
import 'room_info.dart';


class RoomInfoSheet extends StatelessWidget {
  final RoomInfo roomInfo;
  final VoidCallback? onDeparture;
  final VoidCallback? onArrival;

  const RoomInfoSheet({
    Key? key,
    required this.roomInfo,
    this.onDeparture,
    this.onArrival,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            roomInfo.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            roomInfo.desc,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (onDeparture != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.flag),
                  label: const Text("출발지로"),
                  onPressed: onDeparture,
                ),
              if (onArrival != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.location_on),
                  label: const Text("도착지로"),
                  onPressed: onArrival,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
