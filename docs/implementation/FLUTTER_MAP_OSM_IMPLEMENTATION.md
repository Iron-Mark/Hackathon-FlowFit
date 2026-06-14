# Flutter Map with OpenStreetMap (OSM) Implementation Guide

## 🗺️ Overview

This guide explains how Flutter Map with OpenStreetMap tiles was implemented in the FlowFit app, specifically in the Mission Creation screen for walking workouts.

---

## 📦 Dependencies Required

### 1. Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_map: ^6.0.0  # Flutter Map package
  latlong2: ^0.9.0     # Latitude/Longitude handling
```

### 2. Install packages:
```bash
flutter pub get
```

---

## 🏗️ Implementation Steps

### Step 1: Import Required Packages

```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
```

### Step 2: Create MapController

The `MapController` allows you to programmatically control the map (zoom, pan, etc.):

```dart
class _MissionCreationScreenState extends ConsumerState<MissionCreationScreen> {
  final MapController _mapController = MapController();
  
  @override
  void dispose() {
    _mapController.dispose();  // Clean up
    super.dispose();
  }
}
```

### Step 3: Set Up State Variables

```dart
LatLng? _currentLocation;      // User's current GPS location
LatLng? _selectedLocation;     // Location tapped on map
bool _isLoadingLocation = true; // Loading state
```

### Step 4: Get Current Location

```dart
Future<void> _loadCurrentLocation() async {
  try {
    final gpsService = ref.read(gpsTrackingServiceProvider);
    final location = await gpsService.getCurrentLocation();
    
    setState(() {
      _currentLocation = location;
      _selectedLocation = location;
      _isLoadingLocation = false;
    });

    // Center map on current location with zoom level 15
    _mapController.move(location, 15.0);
  } catch (e) {
    setState(() {
      _isLoadingLocation = false;
    });
    // Handle error
  }
}
```

### Step 5: Build the FlutterMap Widget

```dart
FlutterMap(
  mapController: _mapController,
  options: MapOptions(
    initialCenter: _currentLocation!,  // Starting position
    initialZoom: 15.0,                 // Zoom level (1-18)
    onTap: (tapPosition, point) {      // Handle map taps
      setState(() {
        _selectedLocation = point;
      });
    },
  ),
  children: [
    // 1. Tile Layer (OSM tiles)
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.flowfit.app',
    ),
    
    // 2. Marker Layer (pins on map)
    MarkerLayer(
      markers: [
        // Your markers here
      ],
    ),
    
    // 3. Circle Layer (radius circles)
    CircleLayer(
      circles: [
        // Your circles here
      ],
    ),
  ],
)
```

---

## 🎨 Key Components Explained

### 1. **TileLayer - The Map Tiles**

This is the actual map imagery from OpenStreetMap:

```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.flowfit.app',  // Required by OSM
)
```

**URL Template Breakdown:**
- `{z}` = Zoom level (1-18)
- `{x}` = Tile X coordinate
- `{y}` = Tile Y coordinate

**Alternative Tile Providers:**
```dart
// Dark mode
'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'

// Satellite
'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'

// Terrain
'https://tile.opentopomap.org/{z}/{x}/{y}.png'
```

### 2. **MarkerLayer - Pins on Map**

Add markers (pins) to show locations:

```dart
MarkerLayer(
  markers: [
    // Current location marker (blue dot)
    Marker(
      point: _currentLocation!,  // LatLng position
      width: 40,                 // Marker width
      height: 40,                // Marker height
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 20,
        ),
      ),
    ),
    
    // Selected location marker (red pin)
    if (_selectedLocation != null)
      Marker(
        point: _selectedLocation!,
        width: 40,
        height: 40,
        child: const Icon(
          Icons.location_on,
          color: Colors.red,
          size: 40,
        ),
      ),
  ],
)
```

### 3. **CircleLayer - Radius Circles**

Draw circles on the map (useful for geofences, safe zones):

```dart
CircleLayer(
  circles: [
    CircleMarker(
      point: _selectedLocation!,           // Center point
      radius: _radius,                     // Radius value
      useRadiusInMeter: true,              // Use meters (not pixels)
      color: Colors.blue.withOpacity(0.2), // Fill color
      borderColor: Colors.blue,            // Border color
      borderStrokeWidth: 2,                // Border width
    ),
  ],
)
```

### 4. **MapOptions - Map Behavior**

Configure how the map behaves:

```dart
MapOptions(
  initialCenter: LatLng(37.7749, -122.4194),  // Starting position
  initialZoom: 15.0,                          // Zoom level
  minZoom: 5.0,                               // Minimum zoom
  maxZoom: 18.0,                              // Maximum zoom
  
  // Interaction callbacks
  onTap: (tapPosition, point) {
    print('Tapped at: ${point.latitude}, ${point.longitude}');
  },
  
  onLongPress: (tapPosition, point) {
    print('Long pressed at: ${point.latitude}, ${point.longitude}');
  },
  
  onPositionChanged: (position, hasGesture) {
    print('Map moved to: ${position.center}');
  },
  
  // Interaction options
  interactionOptions: InteractionOptions(
    flags: InteractiveFlag.all,  // Enable all interactions
    // Or specific flags:
    // flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
  ),
)
```

---

## 🎯 Complete Implementation Example

### Mission Creation Screen with Map

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MissionCreationScreen extends StatefulWidget {
  const MissionCreationScreen({super.key});

  @override
  State<MissionCreationScreen> createState() => _MissionCreationScreenState();
}

class _MissionCreationScreenState extends State<MissionCreationScreen> {
  final MapController _mapController = MapController();
  
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  double _radius = 100.0;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    // Get GPS location
    final location = await _getGPSLocation();
    
    setState(() {
      _currentLocation = location;
      _selectedLocation = location;
      _isLoadingLocation = false;
    });

    // Move map to current location
    _mapController.move(location, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocation) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Mission')),
      body: Column(
        children: [
          // Map Section (top half)
          Expanded(
            child: _buildMap(),
          ),
          
          // Controls Section (bottom half)
          Expanded(
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation!,
            initialZoom: 15.0,
            onTap: (tapPosition, point) {
              setState(() {
                _selectedLocation = point;
              });
            },
          ),
          children: [
            // OSM Tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.flowfit.app',
            ),
            
            // Markers
            MarkerLayer(
              markers: [
                // Current location
                Marker(
                  point: _currentLocation!,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                
                // Selected location
                if (_selectedLocation != null && 
                    _selectedLocation != _currentLocation)
                  Marker(
                    point: _selectedLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
              ],
            ),
            
            // Radius circle
            if (_selectedLocation != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _selectedLocation!,
                    radius: _radius,
                    useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.2),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
          ],
        ),
        
        // Instructions overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Text(
              'Tap on the map to select target location',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Radius slider
          Row(
            children: [
              const Text('Radius:'),
              Expanded(
                child: Slider(
                  value: _radius,
                  min: 50,
                  max: 1000,
                  onChanged: (value) {
                    setState(() {
                      _radius = value;
                    });
                  },
                ),
              ),
              Text('${_radius.round()}m'),
            ],
          ),
          
          const Spacer(),
          
          // Start button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedLocation != null ? _startMission : null,
              child: const Text('Start Mission'),
            ),
          ),
        ],
      ),
    );
  }

  void _startMission() {
    // Start mission with selected location and radius
    print('Mission started at: $_selectedLocation with radius: $_radius');
  }

  Future<LatLng> _getGPSLocation() async {
    // Implement GPS location fetching
    // For now, return San Francisco
    return LatLng(37.7749, -122.4194);
  }
}
```

---

## 🎨 Styling & Customization

### 1. **Custom Markers**

Create custom marker widgets:

```dart
Widget _buildCustomMarker({
  required IconData icon,
  required Color color,
  String? label,
}) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      if (label != null) ...[
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ],
    ],
  );
}
```

### 2. **Polyline (Route Lines)**

Draw lines between points:

```dart
PolylineLayer(
  polylines: [
    Polyline(
      points: [
        LatLng(37.7749, -122.4194),
        LatLng(37.7849, -122.4094),
        LatLng(37.7949, -122.3994),
      ],
      strokeWidth: 4.0,
      color: Colors.blue,
      borderStrokeWidth: 2.0,
      borderColor: Colors.white,
    ),
  ],
)
```

### 3. **Polygon (Areas)**

Draw filled areas:

```dart
PolygonLayer(
  polygons: [
    Polygon(
      points: [
        LatLng(37.7749, -122.4194),
        LatLng(37.7849, -122.4094),
        LatLng(37.7949, -122.3994),
        LatLng(37.7749, -122.4194),  // Close the polygon
      ],
      color: Colors.blue.withOpacity(0.3),
      borderColor: Colors.blue,
      borderStrokeWidth: 2.0,
      isFilled: true,
    ),
  ],
)
```

---

## 🎮 MapController Methods

Control the map programmatically:

```dart
// Move to location
_mapController.move(LatLng(37.7749, -122.4194), 15.0);

// Animate to location
_mapController.animateTo(
  dest: LatLng(37.7749, -122.4194),
  zoom: 15.0,
  duration: const Duration(milliseconds: 500),
);

// Fit bounds (show multiple points)
_mapController.fitCamera(
  CameraFit.bounds(
    bounds: LatLngBounds(
      LatLng(37.7749, -122.4194),  // Southwest
      LatLng(37.7949, -122.3994),  // Northeast
    ),
    padding: const EdgeInsets.all(50),
  ),
);

// Rotate map
_mapController.rotate(45.0);  // Degrees

// Get current center
final center = _mapController.camera.center;

// Get current zoom
final zoom = _mapController.camera.zoom;
```

---

## 📍 Working with LatLng

### Create LatLng:
```dart
final location = LatLng(37.7749, -122.4194);  // Latitude, Longitude
```

### Calculate Distance:
```dart
import 'package:latlong2/latlong.dart';

final distance = const Distance();

final meters = distance.as(
  LengthUnit.Meter,
  LatLng(37.7749, -122.4194),
  LatLng(37.7849, -122.4094),
);

print('Distance: ${meters.toStringAsFixed(2)}m');
```

### Calculate Bearing:
```dart
final bearing = distance.bearing(
  LatLng(37.7749, -122.4194),
  LatLng(37.7849, -122.4094),
);

print('Bearing: ${bearing.toStringAsFixed(2)}°');
```

---

## 🔧 Common Issues & Solutions

### Issue 1: Map not loading

**Problem:** Tiles not appearing

**Solution:**
```dart
// Add userAgentPackageName (required by OSM)
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.yourapp.name',  // Required!
)
```

### Issue 2: Markers not showing

**Problem:** Markers outside visible area

**Solution:**
```dart
// Ensure marker point is within map bounds
// Use fitBounds to show all markers
_mapController.fitCamera(
  CameraFit.bounds(
    bounds: LatLngBounds.fromPoints(markerPoints),
    padding: const EdgeInsets.all(50),
  ),
);
```

### Issue 3: Performance issues

**Problem:** Map lagging with many markers

**Solution:**
```dart
// Use MarkerClusterLayer for many markers
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

MarkerClusterLayerWidget(
  options: MarkerClusterLayerOptions(
    maxClusterRadius: 120,
    size: const Size(40, 40),
    markers: markers,
    builder: (context, markers) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            markers.length.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    },
  ),
)
```

---

## 🌍 Alternative Map Providers

### 1. **Google Maps** (Requires API key)
```yaml
dependencies:
  google_maps_flutter: ^2.5.0
```

### 2. **Mapbox** (Requires API key)
```dart
TileLayer(
  urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token={accessToken}',
  additionalOptions: {
    'accessToken': 'YOUR_MAPBOX_TOKEN',
  },
)
```

### 3. **OpenStreetMap (Free)**
```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.flowfit.app',
)
```

---

## ✅ Best Practices

1. **Always dispose MapController:**
   ```dart
   @override
   void dispose() {
     _mapController.dispose();
     super.dispose();
   }
   ```

2. **Handle loading states:**
   ```dart
   if (_isLoadingLocation) {
     return const CircularProgressIndicator();
   }
   ```

3. **Check for null locations:**
   ```dart
   if (_currentLocation == null) {
     return const Text('Location unavailable');
   }
   ```

4. **Use appropriate zoom levels:**
   - City view: 10-12
   - Street view: 15-16
   - Building view: 18

5. **Respect OSM usage policy:**
   - Always include `userAgentPackageName`
   - Don't make excessive requests
   - Consider caching tiles

---

## 📚 Resources

- **Flutter Map Documentation:** https://docs.fleaflet.dev/
- **OpenStreetMap:** https://www.openstreetmap.org/
- **LatLng2 Package:** https://pub.dev/packages/latlong2
- **OSM Tile Usage Policy:** https://operations.osmfoundation.org/policies/tiles/

---

## 🎯 Summary

The Flutter Map with OSM implementation in FlowFit:

1. ✅ Uses `flutter_map` package for map rendering
2. ✅ Uses OpenStreetMap tiles (free, no API key needed)
3. ✅ Implements `MapController` for programmatic control
4. ✅ Shows current location with GPS
5. ✅ Allows tap-to-select target locations
6. ✅ Displays markers for locations
7. ✅ Draws circles for geofences/safe zones
8. ✅ Provides smooth user experience

**Status:** ✅ Fully implemented and working!

---

**Last Updated:** November 29, 2025
**Implementation:** Mission Creation Screen
**Package Version:** flutter_map ^6.0.0
