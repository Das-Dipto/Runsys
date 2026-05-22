// lib/Admin/Widgets/add_property_dialog.dart
import 'package:flutter/material.dart';

class AddPropertyDialog extends StatefulWidget {
  const AddPropertyDialog({super.key});

  @override
  State<AddPropertyDialog> createState() => _AddPropertyDialogState();
}

class _AddPropertyDialogState extends State<AddPropertyDialog> {
  static const Color _bg      = Color(0xFF111118);
  static const Color _field   = Color(0xFF1E1E2E);
  static const Color _orange  = Color(0xFFFF7300);
  static const Color _textPri = Color(0xFFFFFFFF);
  static const Color _textSec = Color(0xFF8A8A9A);

  // Address
  final _streetController       = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController         = TextEditingController();
  final _zipController          = TextEditingController();
  String? _selectedState;
  String  _selectedCountry      = 'United States';

  // Additional Info
  final _livingAreaController = TextEditingController();
  final _yearBuiltController  = TextEditingController();
  String? _selectedStructureType;

  final List<String> _states = [
    'Alabama','Alaska','Arizona','Arkansas','California','Colorado',
    'Connecticut','Delaware','Florida','Georgia','Hawaii','Idaho',
    'Illinois','Indiana','Iowa','Kansas','Kentucky','Louisiana',
    'Maine','Maryland','Massachusetts','Michigan','Minnesota',
    'Mississippi','Missouri','Montana','Nebraska','Nevada',
    'New Hampshire','New Jersey','New Mexico','New York',
    'North Carolina','North Dakota','Ohio','Oklahoma','Oregon',
    'Pennsylvania','Rhode Island','South Carolina','South Dakota',
    'Tennessee','Texas','Utah','Vermont','Virginia','Washington',
    'West Virginia','Wisconsin','Wyoming',
  ];

  final List<String> _countries = [
    'United States','United Kingdom','Canada','Australia',
    'Bangladesh','India','Germany','France','Singapore',
  ];

  final List<String> _structureTypes = [
    'Apartment','House','Villa','Condo','Townhouse',
    'Studio','Duplex','Commercial','Office',
  ];

  @override
  void dispose() {
    _streetController.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _livingAreaController.dispose();
    _yearBuiltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.add_home_rounded, color: _orange, size: 26),
                  const SizedBox(width: 10),
                  const Text(
                    'Add Property',
                    style: TextStyle(
                        color: _textPri,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1E1E2E), height: 1),

            // ── Scrollable Body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── ADDRESS SECTION ──────────────────────────────
                    _sectionHeader(
                      icon: Icons.location_on_outlined,
                      title: 'Address',
                      subtitle: "Enter the property's physical address",
                    ),
                    const SizedBox(height: 20),

                    _label('Street Address *'),
                    _textField(_streetController, '123 Main Street'),
                    const SizedBox(height: 16),

                    _label('Address Line 2 (Optional)'),
                    _textField(_addressLine2Controller,
                        'Apartment, suite, unit, etc.'),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('City *'),
                              _textField(_cityController, 'New York'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('State *'),
                              _dropdownField(
                                value: _selectedState,
                                hint: 'Select state',
                                items: _states,
                                onChanged: (v) =>
                                    setState(() => _selectedState = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Zip Code *'),
                              _textField(_zipController, '12345',
                                  keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Country'),
                              _dropdownField(
                                value: _selectedCountry,
                                hint: 'Select country',
                                items: _countries,
                                onChanged: (v) => setState(() =>
                                    _selectedCountry =
                                        v ?? 'United States'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Divider(color: Color(0xFF1E1E2E)),
                    const SizedBox(height: 24),

                    // ── ADDITIONAL INFO SECTION ──────────────────────
                    _sectionHeader(
                      icon: Icons.settings_outlined,
                      title: 'Additional Info',
                      subtitle: 'Property specifications',
                    ),
                    const SizedBox(height: 20),

                    _label('Structure Type *'),
                    _dropdownField(
                      value: _selectedStructureType,
                      hint: 'Select structure type',
                      items: _structureTypes,
                      onChanged: (v) =>
                          setState(() => _selectedStructureType = v),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Living Area (sq ft)'),
                              _textField(_livingAreaController, '1500',
                                  keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Year Built'),
                              _textField(_yearBuiltController, '2020',
                                  keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // ── Bottom Buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Color(0xFF1E1E2E)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: save property logic
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Property added successfully!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Add Property',
                          style:
                              TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _textSec, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: _textPri,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            Text(subtitle,
                style:
                    const TextStyle(color: _textSec, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  // ── Label ─────────────────────────────────────────────────────────────────
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: _textPri,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      );

  // ── Text field ────────────────────────────────────────────────────────────
  Widget _textField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: _textPri, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textSec, fontSize: 14),
          filled: true,
          fillColor: _field,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      );

  // ── Dropdown field ────────────────────────────────────────────────────────
  Widget _dropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _field,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(color: _textSec, fontSize: 14)),
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: const Color(0xFF1E1E2E),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _textSec, size: 20),
          style: const TextStyle(color: _textPri, fontSize: 14),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      );
}