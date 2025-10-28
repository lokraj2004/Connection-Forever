import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'cf_data_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'BG_wrapper.dart';
import 'dart:convert';

class SensorDataPage extends StatefulWidget {
  final String slotKey;
  final String username;

  const SensorDataPage({
    super.key,
    required this.slotKey,
    required this.username,
  });

  @override
  State<SensorDataPage> createState() => _SensorDataPageState();
}
class _SensorDataPageState extends State<SensorDataPage> {
  final DatabaseReference _sensorsRef = FirebaseDatabase.instance.ref('sensors');
  late CFDataTracker _dataTracker;
  DateTime? _appLaunchTime;
  List<Batch> _discreteCache = [];

  bool isDiscreteMode = true;
  List<Batch> continuousDataList = [];
  Timer? pollingTimer;
  DateTime? _lastDataTimestamp;
  bool _isAdminUnavailable = false;
  Timer? _inactivityTimer;
  String? _lastSnapshotHash;

  @override
  void initState() {
    super.initState();
    _startPollingIfNeeded();
    _dataTracker = CFDataTracker();
    _startTracker(); // Start the tracker once the page is built
    _startInactivityMonitor();
  }
  void _startInactivityMonitor() {
    _inactivityTimer = Timer.periodic(Duration(seconds: 5), (_) {
      final now = DateTime.now();

      // First-time check if no data received yet
      if (_lastDataTimestamp == null) {
        if (_appLaunchTime == null) {
          _appLaunchTime = now;
        }
        final launchDiff = now.difference(_appLaunchTime!);
        if (launchDiff.inSeconds >= 180 && !_isAdminUnavailable) {
          setState(() {
            _isAdminUnavailable = true;
          });
        }
        return;
      }

      // Regular check if data has stopped after some time
      final diff = now.difference(_lastDataTimestamp!);
      if (diff.inSeconds >= 60 && !_isAdminUnavailable) {
        setState(() {
          _isAdminUnavailable = true;
        });
      }
    });
  }

  bool _isNewData(dynamic rawData) {
    if (rawData == null) return false;
    final hash = rawData.hashCode.toString();
    if (_lastSnapshotHash == hash) return false;
    _lastSnapshotHash = hash;
    return true;
  }

  Future<void> _startTracker() async {
    // Save slotKey to SharedPreferences for tracker
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('slotKey', widget.slotKey);
    await _dataTracker.startTracking();
  }

  @override
  void dispose() {
    pollingTimer?.cancel();
    _dataTracker.stopTracking(); // Make sure to stop the tracker
    _inactivityTimer?.cancel();

    super.dispose();
  }
  // Example: Suppose you receive new data from Firebase here
  void _onDataReceived(double newDataMB) {
    _dataTracker.addDownloadedData(newDataMB);

    setState(() {
      _lastDataTimestamp = DateTime.now();
      if (_isAdminUnavailable) {
        _isAdminUnavailable = false;
      }
    });
    // Continue normal logic of updating UI etc.
  }

  double _estimateDataMB(dynamic data) {
    dynamic encodable;

    if (data is List<Batch>) {
      encodable = data.map((b) => b.toMap()).toList();
    } else if (data is Batch) {
      encodable = data.toMap();
    } else {
      encodable = data;
    }

    final bytes = utf8.encode(jsonEncode(encodable)).length;
    return bytes / (1024 * 1024);
  }

  void _startPollingIfNeeded() {
    pollingTimer?.cancel();
    if (!isDiscreteMode) {
      pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        final snapshot = await _sensorsRef.get();
        final dynamic rawData = snapshot.value;
        if (rawData is List) {
          final List<Batch> newData = rawData
              .where((e) => e != null)
              .map((e) => Batch(
            id: e['id'] ?? 0,
            name: e['name'] ?? 'NULL',
            value: (e['value'] is num) ? e['value'] : null,
            unit: e['unit'] ?? 'NULL',
          ))
              .toList();
          setState(() {
            continuousDataList.addAll(newData);
          });
          double mbDownloaded = _estimateDataMB(newData);
          _onDataReceived(mbDownloaded);
        }
      });
    }
  }

  Future<bool> _onWillPop() async {
    await _dataTracker.stopTracking(); // Final sync before exiting
    return true; // Allow pop after cleanup
  }

  void _toggleMode(bool value) {
    setState(() {
      isDiscreteMode = value;
      continuousDataList.clear(); // reset continuous data list when switching
    });
    _startPollingIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
    child: Scaffold(
      appBar: AppBar(
        title: const Text("Sensor Data",style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF00687A),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,color: Colors.white.withOpacity(0.9)),
            onSelected: (value) {
              if (value == 'toggle') {
                _toggleMode(!isDiscreteMode);
              } else if (value == 'clear') {
                if (isDiscreteMode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Could not clear in discrete mode"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  setState(() {
                    continuousDataList.clear();
                  });
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'toggle',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discrete'),
                    Switch(
                      value: isDiscreteMode,
                      onChanged: (value) {
                        Navigator.pop(context); // Close the popup
                        _toggleMode(value);
                      },
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'clear',
                child: Text('Clear Continuous List'),
              ),
            ],
          ),
        ],

      ),
      body: BackgroundWrapper(
          child: isDiscreteMode ? _buildDiscreteStream() : _buildContinuousList(),
    ))
    );
  }

  Widget _buildDiscreteStream() {
    if (_isAdminUnavailable) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/SleepingMicrocontroller.png',
              width: 300,
              height: 300,
            ),
            const SizedBox(height: 30),
            const Text(
              "Admin (CT) is not available.\nPlease try after some time.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.red),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: _sensorsRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final rawData = snapshot.data!.snapshot.value;

          if (rawData is List && _isNewData(rawData)) {
            final List<Batch> newBatches = rawData
                .where((e) => e != null)
                .map((e) => Batch.fromMap(e))
                .toList();

            // --- Adaptive update logic ---
            for (int i = 0; i < newBatches.length; i++) {
              if (_discreteCache.length <= i) {
                // New batch added
                _discreteCache.add(newBatches[i]);
              } else if (!_discreteCache[i].isSame(newBatches[i])) {
                // Existing batch changed in any field
                _discreteCache[i] = newBatches[i];
              }
            }

            // If the new data has fewer elements (some removed)
            if (_discreteCache.length > newBatches.length) {
              _discreteCache = _discreteCache.sublist(0, newBatches.length);
            }

            // Track download usage
            double mbDownloaded = _estimateDataMB(newBatches);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _onDataReceived(mbDownloaded);
            });
          }

          return ListView.builder(
            itemCount: _discreteCache.length,
            itemBuilder: (context, index) {
              return _buildCard(_discreteCache[index]);
            },
          );
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading data"));
        } else {
          return Center(
            child: Lottie.asset(
              'assets/animations/SandLoading.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          );
        }
      },
    );
  }


  Widget _buildContinuousList() {
    if (continuousDataList.isEmpty) {
      return Center(
        child: Lottie.asset(
          'assets/animations/SandLoading.json',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      );
    }
    return ListView.builder(
      itemCount: continuousDataList.length,
      itemBuilder: (context, index) {
        return _buildCard(continuousDataList[index]);
      },
    );
  }

  Widget _buildCard(Batch batch) {
    bool isNameNull = batch.name == "NULL";
    bool isUnitNull = batch.unit == "NULL";
    bool isValueNegative = batch.value != null && batch.value < 0;

    String title = "";
    String subtitle = "";

    if (isNameNull && isUnitNull && isValueNegative) {
      return _emptyCard();
    }

    if (!isNameNull && !isUnitNull && batch.value != null && batch.value >= 0) {
      title = batch.name;
      subtitle = "${batch.value} ${batch.unit}";
      return _cardWithTitleSubtitle(batch.id, title, subtitle);
    }

    if (isNameNull && !isUnitNull && batch.value != null && batch.value >= 0) {
      return _simpleTextCard("${batch.value} ${batch.unit}");
    }

    if (isValueNegative && !isNameNull && !isUnitNull) {
      return _simpleTextCard("${batch.name} ${batch.unit}");
    }

    if (!isNameNull && isUnitNull && batch.value != null && batch.value >= 0) {
      return _simpleTextCard("${batch.name} ${batch.value}");
    }

    if (isValueNegative && isUnitNull && !isNameNull) {
      return _simpleTextCard(batch.name);
    }

    if (isNameNull && isUnitNull && batch.value != null && batch.value >= 0) {
      return _simpleTextCard("${batch.value}");
    }

    if (isNameNull && isValueNegative && !isUnitNull) {
      return _centeredCard(batch.unit);
    }

    return _simpleTextCard("Unclassified Batch");
  }

  Widget _cardWithTitleSubtitle(int id, String title, String subtitle) {
    return Card(
      key: ValueKey(id),
      margin: const EdgeInsets.all(10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(child: Text('$id')),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _centeredCard(String centerText) {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(centerText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _simpleTextCard(String text) {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _emptyCard() {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const SizedBox(height: 50),
    );
  }
}

class Batch {
  final int id;
  final String name;
  final dynamic value;
  final String unit;

  Batch({
    required this.id,
    required this.name,
    required this.value,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'unit': unit,
    };
  }

  factory Batch.fromMap(Map<dynamic, dynamic> map) {
    return Batch(
      id: map['id'] ?? 0,
      name: map['name'] ?? 'NULL',
      value: map['value'],
      unit: map['unit'] ?? 'NULL',
    );
  }

  bool isSame(Batch other) {
    return id == other.id &&
        name == other.name &&
        value == other.value &&
        unit == other.unit;
  }
}
