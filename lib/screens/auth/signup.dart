import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/core/theme/pawstay_theme.dart';
import 'package:flutter_application_1/core/config/api_config.dart';
import 'package:flutter_application_1/screens/auth/verify_otp.dart';
import 'package:flutter_application_1/screens/auth/login.dart';

// ── Indian States list (for autocomplete)
const List<String> _kIndianStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  'Chandigarh',
  'Dadra and Nagar Haveli',
  'Daman and Diu',
  'Delhi',
  'Jammu and Kashmir',
  'Ladakh',
  'Lakshadweep',
  'Puducherry',
];

// ── State to City suggestions map
const Map<String, List<String>> _kStateCityMap = {
  'Maharashtra': [
    'Mumbai',
    'Pune',
    'Nagpur',
    'Nashik',
    'Thane',
    'Aurangabad',
    'Solapur',
    'Navi Mumbai',
    'Kolhapur',
    'Amravati',
  ],
  'Delhi': [
    'New Delhi',
    'North Delhi',
    'South Delhi',
    'East Delhi',
    'West Delhi',
    'Central Delhi',
    'Dwarka',
    'Rohini',
  ],
  'Karnataka': [
    'Bangalore',
    'Mysore',
    'Hubli',
    'Mangalore',
    'Belgaum',
    'Davangere',
    'Bellary',
    'Gulbarga',
  ],
  'Tamil Nadu': [
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Tiruchirappalli',
    'Salem',
    'Tirunelveli',
    'Vellore',
    'Erode',
  ],
  'Gujarat': [
    'Ahmedabad',
    'Surat',
    'Vadodara',
    'Rajkot',
    'Bhavnagar',
    'Jamnagar',
    'Gandhinagar',
    'Junagadh',
  ],
  'Uttar Pradesh': [
    'Lucknow',
    'Kanpur',
    'Agra',
    'Varanasi',
    'Ghaziabad',
    'Noida',
    'Meerut',
    'Prayagraj',
    'Bareilly',
    'Aligarh',
  ],
  'West Bengal': [
    'Kolkata',
    'Howrah',
    'Durgapur',
    'Asansol',
    'Siliguri',
    'Kharagpur',
  ],
  'Rajasthan': [
    'Jaipur',
    'Jodhpur',
    'Udaipur',
    'Kota',
    'Bikaner',
    'Ajmer',
    'Bhilwara',
  ],
  'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Khammam'],
  'Punjab': [
    'Ludhiana',
    'Amritsar',
    'Jalandhar',
    'Patiala',
    'Bathinda',
    'Mohali',
  ],
  'Haryana': [
    'Gurgaon',
    'Faridabad',
    'Panipat',
    'Ambala',
    'Karnal',
    'Hisar',
    'Rohtak',
  ],
  'Kerala': [
    'Kochi',
    'Thiruvananthapuram',
    'Kozhikode',
    'Thrissur',
    'Kollam',
    'Kannur',
  ],
  'Madhya Pradesh': [
    'Indore',
    'Bhopal',
    'Jabalpur',
    'Gwalior',
    'Ujjain',
    'Sagar',
  ],
  'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Purnia', 'Darbhanga'],
  'Andhra Pradesh': [
    'Visakhapatnam',
    'Vijayawada',
    'Guntur',
    'Nellore',
    'Kurnool',
    'Rajahmundry',
  ],
  'Assam': ['Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat', 'Nagaon'],
  'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Berhampur', 'Sambalpur'],
};

// ── Popular cities (fallback when state is not selected)
const List<String> _kPopularCities = [
  'Mumbai',
  'Delhi',
  'Bangalore',
  'Hyderabad',
  'Chennai',
  'Kolkata',
  'Pune',
  'Ahmedabad',
];

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _usernameCtr = TextEditingController();
  final _emailCtr = TextEditingController();
  final _passwordCtr = TextEditingController();
  final _confirmPasswordCtr = TextEditingController();
  final _stateCtr = TextEditingController();
  final _cityCtr = TextEditingController();
  final _postalCtr = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedRole = 'User';
  final List<String> _roles = [
    'User',
    'Service Provider',
    'Pet Service',
    'Seller',
    'Doctor',
  ];

  bool _isLoading = false;

  // ── Ultra-Fast Username Availability Check State
  bool? _usernameAvailable;
  bool _checkingUsername = false;
  Timer? _usernameDebounce;
  http.Client? _usernameHttpClient;

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    _usernameHttpClient?.close();
    _usernameHttpClient = null;

    final username = value.trim();

    if (username.length < 3) {
      setState(() {
        _usernameAvailable = null;
        _checkingUsername = false;
      });
      return;
    }

    setState(() {
      _checkingUsername = true;
      _usernameAvailable = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 250), () async {
      _usernameHttpClient = http.Client();
      try {
        final uri = Uri.parse(
          '${ApiConfig.baseUrl}/check-username?username=${Uri.encodeComponent(username)}',
        );
        final res = await _usernameHttpClient!
            .get(uri)
            .timeout(const Duration(seconds: 4));

        if (!mounted) return;

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          setState(() {
            _usernameAvailable = data['success'] == true;
            _checkingUsername = false;
          });
        } else {
          setState(() => _checkingUsername = false);
        }
      } catch (e) {
        if (mounted && _checkingUsername) {
          setState(() => _checkingUsername = false);
        }
      }
    });
  }

  late AnimationController _buttonCtrl;

  @override
  void initState() {
    super.initState();
    _buttonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _usernameCtr.dispose();
    _emailCtr.dispose();
    _passwordCtr.dispose();
    _confirmPasswordCtr.dispose();
    _stateCtr.dispose();
    _cityCtr.dispose();
    _postalCtr.dispose();
    _buttonCtrl.dispose();
    _usernameDebounce?.cancel();
    _usernameHttpClient?.close();
    super.dispose();
  }

  List<String> _getCitySuggestions() {
    final selectedState = _stateCtr.text.trim();
    if (_kStateCityMap.containsKey(selectedState)) {
      return _kStateCityMap[selectedState]!;
    }
    return _kPopularCities;
  }

  TextStyle _inputStyle() {
    return GoogleFonts.plusJakartaSans(
      fontSize: 16,
      color: PawStayTheme.onSurface,
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: PawStayTheme.onSurface,
      ),
    );
  }

  // ── API call ─────────────────────────────────────────────────────────────
  Future<void> _onSignupPressed() async {
    debugPrint('[AUTH] Signup Button Clicked');
    _buttonCtrl.reverse().then((_) => _buttonCtrl.forward());

    if (!_formKey.currentState!.validate()) {
      debugPrint('[AUTH] Form validation failed');
      _showError('Please fill in all required fields properly.');
      return;
    }

    if (_usernameAvailable == false) {
      debugPrint('[AUTH] Username is taken: ${_usernameCtr.text}');
      _showError('Username is already taken. Please choose another.');
      return;
    }

    if (_passwordCtr.text != _confirmPasswordCtr.text) {
      debugPrint('[AUTH] Passwords mismatch');
      _showError('Passwords do not match!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'full_name': _nameCtr.text.trim(),
        'username': _usernameCtr.text.trim(),
        'email': _emailCtr.text.trim(),
        'password': _passwordCtr.text,
        'state': _stateCtr.text.trim(),
        'city': _cityCtr.text.trim(),
        'postal_code': _postalCtr.text.trim(),
        'role': _selectedRole,
      };

      debugPrint('[AUTH] Calling Signup API: ${ApiConfig.baseUrl}/signup');
      debugPrint('[AUTH] Payload: ${jsonEncode(payload)}');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[AUTH] Signup Response: ${response.statusCode} - ${response.body}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final devOtp = decoded['development_otp'] as String?;

        debugPrint('[AUTH] Signup Success');
        debugPrint('[AUTH] OTP Sent (Dev OTP: $devOtp)');
        debugPrint('[AUTH] Navigating to OTP');

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (c, a, sa) => VerifyOtpScreen(
              email: _emailCtr.text.trim(),
              fullName: _nameCtr.text.trim(),
              developmentOtp: devOtp,
            ),
            transitionsBuilder: (c, a, sa, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: a, curve: Curves.easeInOut)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        final decoded = jsonDecode(response.body);
        final detail = decoded['detail'] ?? 'Signup failed. Please try again.';
        debugPrint('[AUTH] Signup failed with error: $detail');
        _showError(detail.toString());
      }
    } on TimeoutException {
      debugPrint('[AUTH] Signup timeout');
      _showError('Connection timed out. Is the backend running?');
    } catch (e, st) {
      debugPrint('[AUTH] Signup exception: $e\n$st');
      _showError('Could not connect to server. Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: PawStayTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Autocomplete field factory ────────────────────────────────────────────
  Widget _buildAutocompleteField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required List<String> options,
    required String? Function(String?) validator,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        final lower = textEditingValue.text.toLowerCase();
        return options.where((o) => o.toLowerCase().contains(lower));
      },
      onSelected: (String selection) {
        controller.text = selection;
        setState(() {});
      },
      fieldViewBuilder: (
        context,
        fieldTextEditingController,
        focusNode,
        onFieldSubmitted,
      ) {
        if (controller.text.isNotEmpty &&
            fieldTextEditingController.text.isEmpty) {
          fieldTextEditingController.text = controller.text;
        }
        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: focusNode,
          style: _inputStyle(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: PawStayTheme.outlineVariant),
          ),
          onChanged: (val) {
            controller.text = val;
            if (label == 'State') {
              setState(() {});
            }
          },
          validator: validator,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(PawStayTheme.radiusMd),
            color: PawStayTheme.surfaceContainerLowest,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 340),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        option,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: PawStayTheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;

    return Scaffold(
      backgroundColor: PawStayTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative background blurs
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PawStayTheme.primaryContainer.withValues(alpha: 0.4),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PawStayTheme.secondaryContainer.withValues(alpha: 0.35),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 0 : PawStayTheme.marginMobile,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    decoration: BoxDecoration(
                      color: PawStayTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(
                        PawStayTheme.radiusXl,
                      ),
                      border: Border.all(
                        color: PawStayTheme.surfaceDim,
                        width: 1.0,
                      ),
                      boxShadow: PawStayTheme.ambientShadow2,
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header ──────────────────────────────────────
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: PawStayTheme.primaryContainer,
                                  ),
                                  child: const Icon(
                                    Icons.pets_rounded,
                                    size: 28,
                                    color: PawStayTheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Join PawStay',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: PawStayTheme.primary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Create an account to start your pet journey',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: PawStayTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Full Name ───────────────────────────────────
                          _label('Full Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameCtr,
                            style: _inputStyle(),
                            decoration: const InputDecoration(
                              hintText: 'Jane Doe',
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: PawStayTheme.outlineVariant,
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter your name'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          // ── Username ─────────────────────────────────
                          _label('Username'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _usernameCtr,
                            style: _inputStyle(),
                            onChanged: _onUsernameChanged,
                            decoration: InputDecoration(
                              hintText: 'janedoe123',
                              prefixIcon: const Icon(
                                Icons.alternate_email,
                                color: PawStayTheme.outlineVariant,
                              ),
                              suffixIcon: _checkingUsername
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            PawStayTheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    )
                                  : _usernameAvailable == true
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF4CAF50),
                                    )
                                  : _usernameAvailable == false
                                  ? const Icon(
                                      Icons.cancel_rounded,
                                      color: PawStayTheme.error,
                                    )
                                  : null,
                              helperText: _usernameAvailable == true
                                  ? 'Username is available ✓'
                                  : _usernameAvailable == false
                                  ? 'Username is already taken'
                                  : null,
                              helperStyle: TextStyle(
                                color: _usernameAvailable == true
                                    ? const Color(0xFF4CAF50)
                                    : PawStayTheme.error,
                                fontSize: 12,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter a username';
                              }
                              if (v.trim().length < 3) {
                                return 'Username must be at least 3 characters';
                              }
                              if (_usernameAvailable == false) {
                                return 'This username is already taken';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ── Email ────────────────────────────────────
                          _label('Email'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtr,
                            keyboardType: TextInputType.emailAddress,
                            style: _inputStyle(),
                            decoration: const InputDecoration(
                              hintText: 'jane@example.com',
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                color: PawStayTheme.outlineVariant,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(
                                r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                              ).hasMatch(v.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ── Password ─────────────────────────────────
                          _label('Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordCtr,
                            obscureText: _obscurePassword,
                            style: _inputStyle(),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: PawStayTheme.outlineVariant,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: PawStayTheme.outlineVariant,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ── Confirm Password ──────────────────────────
                          _label('Confirm Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPasswordCtr,
                            obscureText: _obscureConfirmPassword,
                            style: _inputStyle(),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: PawStayTheme.outlineVariant,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: PawStayTheme.outlineVariant,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (v != _passwordCtr.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ── State (with autocomplete) ─────────────────
                          _label('State'),
                          const SizedBox(height: 6),
                          _buildAutocompleteField(
                            label: 'State',
                            hint: 'e.g. Maharashtra',
                            icon: Icons.map_outlined,
                            controller: _stateCtr,
                            options: _kIndianStates,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please select your state'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          // ── City (with state-based suggestions) ───────
                          _label('City'),
                          const SizedBox(height: 6),
                          _buildAutocompleteField(
                            label: 'City',
                            hint: 'e.g. Mumbai',
                            icon: Icons.location_city_outlined,
                            controller: _cityCtr,
                            options: _getCitySuggestions(),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter your city'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          // ── Postal Code ───────────────────────────────
                          _label('Postal Code'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _postalCtr,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: _inputStyle(),
                            decoration: const InputDecoration(
                              hintText: '400001',
                              prefixIcon: Icon(
                                Icons.pin_drop_outlined,
                                color: PawStayTheme.outlineVariant,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your postal code';
                              }
                              if (v.length < 4) {
                                return 'Postal code is too short';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ── Role ──────────────────────────────────────
                          _label('Role'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedRole,
                            elevation: 2,
                            icon: const Icon(
                              Icons.expand_more,
                              color: PawStayTheme.onSurfaceVariant,
                            ),
                            dropdownColor: PawStayTheme.surfaceContainerLowest,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: PawStayTheme.onSurface,
                            ),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              prefixIcon: Icon(
                                Icons.supervised_user_circle_outlined,
                                color: PawStayTheme.outlineVariant,
                              ),
                            ),
                            items: _roles
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedRole = val);
                              }
                            },
                          ),

                          const SizedBox(height: 28),

                          // ── Submit Button ─────────────────────────────
                          ScaleTransition(
                            scale: _buttonCtrl,
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _onSignupPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PawStayTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'Create Account',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Already have an account? Login ────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: PawStayTheme.onSurfaceVariant,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Log In',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: PawStayTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
