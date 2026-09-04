import 'package:flutter/material.dart';

class AddPetServiceScreen extends StatefulWidget {
  const AddPetServiceScreen({super.key});

  @override
  State<AddPetServiceScreen> createState() => _AddPetServiceScreenState();
}

class _AddPetServiceScreenState extends State<AddPetServiceScreen> {
  // State Variables
  final Set<String> _selectedPetTypes = {'Dogs'};
  String _selectedService = 'Boarding';
  bool _foodIncluded = false;
  bool _pickupDrop = false;
  bool _emergencySupport = true;

  final Map<String, bool> _amenities = {
    'AC Rooms': true,
    'CCTV Access': true,
    '24/7 Supervision': false,
    'Play Area': true,
    'Grooming station': false,
    'Vet on call': true,
  };

  final List<String> _selectedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2C221E),
          ),
          onPressed: () {},
        ),
        title: const Text(
          'Create Service Package',
          style: TextStyle(
            color: Color(0xFF2C221E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.pets_rounded, color: Color(0xFFA85B3C)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Basic Information'),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          label: 'Package Name',
                          hint: 'e.g., Premium Royal Canine Boarding',
                          icon: Icons.card_membership_rounded,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Pet Types Allowed',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A3E39),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPetTypeChip('Dogs', Icons.pets_rounded),
                            _buildPetTypeChip(
                              'Cats',
                              Icons.catching_pokemon_rounded,
                            ),
                            _buildPetTypeChip(
                              'Birds',
                              Icons.flutter_dash_rounded,
                            ),
                            _buildPetTypeChip(
                              'Rabbits',
                              Icons.cruelty_free_rounded,
                            ),
                            _buildPetTypeChip(
                              'Others',
                              Icons.more_horiz_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Service Type',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A3E39),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedService,
                          decoration: _inputDecoration(
                            hint: 'Select Service',
                            icon: Icons.home_work_rounded,
                          ),
                          items:
                              [
                                'Boarding',
                                'Day Care',
                                'Walking',
                                'Grooming',
                                'Pet Sitting',
                              ].map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                );
                              }).toList(),
                          onChanged:
                              (val) => setState(() => _selectedService = val!),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader('Pricing & Capacity'),
                  _buildCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Price (\$)',
                                hint: '45.00',
                                icon: Icons.attach_money_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: 'Duration',
                                hint: 'Per Night',
                                icon: Icons.schedule_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Maximum Pets',
                          hint: '3',
                          icon: Icons.groups_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader('Media & Description'),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload Photos',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A3E39),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 90,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              Container(
                                width: 90,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFA85B3C,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFA85B3C,
                                    ).withValues(alpha: 0.3),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_rounded,
                                      color: Color(0xFFA85B3C),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFA85B3C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildImagePlaceholder(),
                              const SizedBox(width: 12),
                              _buildImagePlaceholder(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Description',
                          hint:
                              'Describe the luxury experience your stay provides...',
                          icon: Icons.notes_rounded,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'House Rules',
                          hint:
                              'e.g., Must be fully vaccinated, non-aggressive...',
                          icon: Icons.gavel_rounded,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader('Features & Amenities'),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children:
                              _amenities.keys.map((amenity) {
                                final isSelected = _amenities[amenity]!;
                                return FilterChip(
                                  label: Text(amenity),
                                  selected: isSelected,
                                  selectedColor: const Color(
                                    0xFFA85B3C,
                                  ).withValues(alpha: 0.15),
                                  checkmarkColor: const Color(0xFFA85B3C),
                                  labelStyle: TextStyle(
                                    color:
                                        isSelected
                                            ? const Color(0xFFA85B3C)
                                            : const Color(0xFF6E5D56),
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                  backgroundColor: Colors.grey.shade100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color:
                                          isSelected
                                              ? const Color(0xFFA85B3C)
                                              : Colors.transparent,
                                    ),
                                  ),
                                  onSelected: (bool selected) {
                                    setState(
                                      () => _amenities[amenity] = selected,
                                    );
                                  },
                                );
                              }).toList(),
                        ),
                        const Divider(height: 32, color: Color(0xFFEFE8E4)),
                        _buildSwitchTile(
                          title: 'Food Included',
                          subtitle: 'Provide meals and daily snacks',
                          icon: Icons.set_meal_rounded,
                          value: _foodIncluded,
                          onChanged: (v) => setState(() => _foodIncluded = v),
                        ),
                        _buildSwitchTile(
                          title: 'Pickup & Drop Option',
                          subtitle: 'Offer door-to-door pet transport',
                          icon: Icons.airport_shuttle_rounded,
                          value: _pickupDrop,
                          onChanged: (v) => setState(() => _pickupDrop = v),
                        ),
                        _buildSwitchTile(
                          title: '24/7 Emergency Care Support',
                          subtitle: 'Immediate access to local partner clinics',
                          icon: Icons.health_and_safety_rounded,
                          value: _emergencySupport,
                          onChanged:
                              (v) => setState(() => _emergencySupport = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader('Availability & Hours'),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Days',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A3E39),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:
                              [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ].map((day) => _buildDaySelector(day)).toList(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimePickerField(
                                label: 'Opening Time',
                                time: _openTime,
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: _openTime,
                                  );
                                  if (t != null) {
                                    setState(() => _openTime = t);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTimePickerField(
                                label: 'Closing Time',
                                time: _closeTime,
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: _closeTime,
                                  );
                                  if (t != null) {
                                    setState(() => _closeTime = t);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildBottomActionPanel(),
        ],
      ),
    );
  }

  // --- UI Component Helpers ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C221E),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA85B3C).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A3E39),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: _inputDecoration(hint: hint, icon: icon),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFA69B95), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFFA85B3C), size: 20),
      filled: true,
      fillColor: const Color(0xFFFFF9F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF0E6E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFA85B3C), width: 1.5),
      ),
    );
  }

  Widget _buildPetTypeChip(String label, IconData icon) {
    final isSelected = _selectedPetTypes.contains(label);
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : const Color(0xFFA85B3C),
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFA85B3C),
      backgroundColor: const Color(0xFFFFF9F6),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4A3E39),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.transparent : const Color(0xFFF0E6E1),
        ),
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedPetTypes.add(label);
          } else {
            _selectedPetTypes.remove(label);
          }
        });
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF0E6E1),
      ),
      child: const Center(
        child: Icon(Icons.image_rounded, color: Color(0xFFA85B3C), size: 28),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFA85B3C), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C221E),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A7A73),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFFA85B3C),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(String day) {
    final isSelected = _selectedDays.contains(day);
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected ? _selectedDays.remove(day) : _selectedDays.add(day);
        });
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFFA85B3C) : const Color(0xFFFFF9F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected ? const Color(0xFFA85B3C) : const Color(0xFFF0E6E1),
          ),
        ),
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF6E5D56),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerField({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A3E39),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF0E6E1)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFFA85B3C),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C221E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFA85B3C)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Draft',
                  style: TextStyle(color: Color(0xFFA85B3C)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.visibility_rounded,
                color: Color(0xFFA85B3C),
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFFF9F6),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFF0E6E1)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA85B3C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Publish Package',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}