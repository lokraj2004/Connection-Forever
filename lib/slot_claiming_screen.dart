import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'cf_auth_validator.dart';

class SlotClaimingScreen extends StatefulWidget {
  final String clientID;
  final String username;

  const SlotClaimingScreen({
    required this.clientID,
    required this.username,
  });

  @override
  State<SlotClaimingScreen> createState() => _SlotClaimingScreenState();
}

class _SlotClaimingScreenState extends State<SlotClaimingScreen> {
  String statusMessage = "Searching for available slot...";
  bool _isClaiming = true;
  String? _claimedSlotKey;

  @override
  void initState() {
    super.initState();
    _claimSlot();
  }

  Future<void> _claimSlot() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final DocumentReference activeSlotsDoc =
      firestore.collection('slots').doc('activeSlots');

      final docSnapshot = await activeSlotsDoc.get();

      if (!docSnapshot.exists) {
        setState(() {
          statusMessage = "Slots not initialized by admin.";
          _isClaiming = false;
        });
        return;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      bool slotClaimed = false;

      for (int i = 1; i <= 10; i++) {
        final String slotKey = 'slot$i';
        final slotData = data[slotKey];

        if (slotData != null &&
            slotData['username'] == widget.username &&
            slotData['clientID'] == widget.clientID) {
          continue;
        }

        if (slotData == null) {
          final newSlotData = {
            'username': widget.username,
            'clientID': widget.clientID,
            'joinedAt': DateTime.now().toUtc().toIso8601String(),
          };

          await activeSlotsDoc.update({slotKey: newSlotData});

          setState(() {
            statusMessage = "✅ Slot $i claimed successfully!";
            _claimedSlotKey = slotKey;
            _isClaiming = false;
          });

          slotClaimed = true;
          break;
        }
      }

      if (!slotClaimed) {
        setState(() {
          statusMessage =
          "❌ No slots available. Kindly ask your admin and restart the app.";
          _isClaiming = false;
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "❌ Error occurred: ${e.toString()}";
        _isClaiming = false;
      });
    }
  }

  void _navigateToNext() {
    if (_claimedSlotKey != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CFSlotAuthScreen(
            slotKey: _claimedSlotKey!,
            username: widget.username,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Slot Claiming")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isClaiming
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(statusMessage),
            ],
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_claimedSlotKey != null)
                Lottie.asset(
                  'assets/animations/SlotSuccess.json',
                  width: 180,
                  height: 180,
                  repeat: false,
                )
              else
                Lottie.asset(
                  'assets/animations/NotAvailable.json',
                  width: 180,
                  height: 180,
                  repeat: false,
                ),
              SizedBox(height: 20),
              Text(
                statusMessage,
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              if (_claimedSlotKey != null) ...[
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _navigateToNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  icon: Icon(Icons.arrow_forward),
                  label: Text("Next"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }}