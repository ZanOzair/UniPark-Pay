import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final bool showCurrentLocationMarker;
  final String? markerTitle;
  final double? markerRadius;
  final Color markerColor;

  const MapWidget({
    super.key,
    required this.center,
    this.zoom = 15.0,
    this.showCurrentLocationMarker = true,
    this.markerTitle,
    this.markerRadius,
    this.markerColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.uniparkpay',
        ),
        if (showCurrentLocationMarker)
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 80,
                height: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: markerColor,
                      size: 40,
                    ),
                    if (markerTitle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          markerTitle!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        if (markerRadius != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: center,
                radius: markerRadius!,
                color: markerColor.withValues(alpha: 0.2),
                borderColor: markerColor,
                borderStrokeWidth: 2,
              ),
            ],
          ),
      ],
    );
  }
}