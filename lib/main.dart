import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

void main() => runApp(const LocationTrackerApp());

class LocationTrackerApp extends StatelessWidget {
  const LocationTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0xFF123456), // Replace with color from image
        scaffoldBackgroundColor:
            const Color(0xFFEEEEEE), // Replace with color from image
        appBarTheme: const AppBarTheme(
          backgroundColor:
              Color.fromARGB(255, 24, 93, 163), // Replace with color from image
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(
                255, 24, 93, 163), // Replace with color from image
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const LocationTrackerPage(),
    );
  }
}

class LocationTrackerPage extends StatefulWidget {
  const LocationTrackerPage({super.key});

  @override
  _LocationTrackerPageState createState() => _LocationTrackerPageState();
}

class _LocationTrackerPageState extends State<LocationTrackerPage> {
  LatLng? _initialLocation;
  LatLng? _currentLocation;
  double? _radius;
  bool _isOutsideRadius = false;
  bool _canVibrate = false;
  bool _isLoading = false;

  final TextEditingController _radiusController = TextEditingController();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initVibration();
    _checkLocationPermission();
  }

  Future<void> _initVibration() async {
    bool canVibrate = await Vibrate.canVibrate;
    setState(() {
      _canVibrate = canVibrate;
    });
  }

  void _checkAndNotify(bool isOutside) {
    if (isOutside && _canVibrate) {
      Vibrate.vibrate();
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Location services are disabled. Please enable location services.'),
        duration: Duration(seconds: 3),
      ));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are denied. Please enable them in settings.'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Location permissions are permanently denied. Please enable them in settings.'),
        duration: Duration(seconds: 3),
      ));
      return;
    }
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _initialLocation = LatLng(position.latitude, position.longitude);
        _currentLocation = _initialLocation;
        _mapController.move(_initialLocation!, 15.0);
        _isLoading = false;
      });
      _showRadiusDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location capture failed: $e')),
      );
    }
  }

  void _updateLocation(LatLng newLocation) {
    setState(() {
      _currentLocation = newLocation;
      _mapController.move(newLocation, 15.0);

      if (_initialLocation != null && _radius != null) {
        double distance = Geolocator.distanceBetween(
          _initialLocation!.latitude,
          _initialLocation!.longitude,
          newLocation.latitude,
          newLocation.longitude,
        );

        bool wasOutside = _isOutsideRadius;
        _isOutsideRadius = distance > _radius!;

        if (!wasOutside && _isOutsideRadius) {
          _checkAndNotify(_isOutsideRadius);
        }
      }
    });
  }

  void _showRadiusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Radius (meters)'),
        content: TextField(
          controller: _radiusController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter radius'),
        ),
        actions: [
          TextButton(
            child: const Text('Set'),
            onPressed: () {
              setState(() {
                _radius = double.tryParse(_radiusController.text);
              });
              Navigator.pop(context);
              _startLocationUpdates();
            },
          ),
        ],
      ),
    );
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    ).listen((Position position) {
      _updateLocation(LatLng(position.latitude, position.longitude));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        'Location Tracker',
        style: TextStyle(color: Colors.black54),
      )),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialLocation ?? const LatLng(0, 0),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              if (_initialLocation != null && _radius != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _initialLocation!,
                      color:
                          const Color.fromARGB(255, 100, 163, 214).withOpacity(0.3),
                      borderColor: const Color.fromARGB(255, 19, 87, 142),
                      borderStrokeWidth: 2,
                      useRadiusInMeter: true, // Ensures fixed area
                      radius: _radius!, // Radius in meters
                    ),
                  ],
                ),
              if (_initialLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _initialLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _captureLocation,
              child: const Text('Capture Location'),
            ),
          ),
          if (_isOutsideRadius)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.red.withOpacity(0.8),
                child: const Text(
                  'WARNING: Outside Allowed Radius!',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
