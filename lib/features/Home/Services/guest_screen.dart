import 'package:flutter/material.dart';

class GuestScreen extends StatelessWidget {
  final String guestName;        // 'Afo' or 'Eileen'
  final bool isCurrentGuest;     // Optional flag for future use

  const GuestScreen({
    super.key,
    this.guestName = 'Afo',           // Default to current guest
    this.isCurrentGuest = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isCurrentGuest ? 'Guest' : 'Next Guest',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Guest'),
            _buildInfoRow('First and last name', guestName),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

            _buildSectionHeader('Reservation'),
            _buildInfoRow('Reservation', isCurrentGuest ? '9 nights' : '5 nights'),
            _buildInfoRow('Check-in', isCurrentGuest ? 'Apr 1 at 4:00 PM' : 'Apr 11 at 3:00 PM'),
            _buildInfoRow('Checkout', isCurrentGuest ? 'Apr 10 at 10:00 AM' : 'Apr 16 at 11:00 AM'),
            _buildInfoRow('Total guests', isCurrentGuest ? '1' : '2'),
            _buildInfoRow('Add-ons', 'Cleaning Fee', isChip: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isChip = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF8A8A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isChip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF555555),
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
        ],
      ),
    );
  }
}