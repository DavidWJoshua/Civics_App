import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/token_storage.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';

class RaiseComplaint extends StatefulWidget {
  const RaiseComplaint({super.key});

  @override
  State<RaiseComplaint> createState() => _RaiseComplaintState();
}

class _RaiseComplaintState extends State<RaiseComplaint> with WidgetsBindingObserver {
  final _addressCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool loading = false;
  String? category;
  String? severity;
  Position? currentPosition;
  File? _image;
  bool _isAnalyzing = false;
  String? _mlCategory;
  String? _mlSeverity;
  bool _manualEntry = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> categories = [
    "Pipe Breakage",
    "Leakage",
    "Overflow",
    "Sinkhole",
    "Manhole Missing",
    "Clogged Drain",
    "Others"
  ];

  // Map ML Model output to UI labels
  final Map<String, String> _mlToUiMap = {
    "Breakage": "Pipe Breakage",
    "Pipe_Leak": "Leakage",
    "Overflow": "Overflow",
    "Sinkhole": "Sinkhole",
    "Manhole_Missing": "Manhole Missing",
    "Clogged_Drain": "Clogged Drain",
    "Others": "Others",
  };

  final List<String> severities = ["Low", "Medium", "High"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showLocationDialog());
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to choose
      builder: (context) => AlertDialog(
        title: const Text("Use Location?"),
        content: const Text(
            "To automatically fill your address, we need access to your location."),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _manualEntry = true);
              Navigator.pop(context); // Close dialog
            },
            child: const Text("DENY", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _manualEntry = false);
              Navigator.pop(context); // Close dialog
              _fetchLocation(); // Start fetching
            },
            child: const Text("ALLOW",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _addressCtrl.dispose();
    _streetCtrl.dispose();
    _areaCtrl.dispose();
    _wardCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Retry fetching location if it's missing or if we were waiting for GPS activation
      if (currentPosition == null) {
        _fetchLocation();
      }
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => loading = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Fetching GPS location..."),
            duration: Duration(seconds: 1)),
      );

      final pos = await LocationService.getCurrentLocation();
      currentPosition = pos;

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          debugPrint("📍 PLACEMARK: $place");

          _addressCtrl.text =
              "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";

          _streetCtrl.text = place.street ?? place.name ?? "";

          // Default City to Rajapalayam
          _cityCtrl.text = "Rajapalayam";

          // Area detection logic
          String detectedArea = "";

          // Check all fields for "Vadaku Venganallur" first
          bool isVenganallur = false;
          List<String?> allFields = [
            place.subLocality,
            place.locality,
            place.street,
            place.name,
            place.subAdministrativeArea,
            place.administrativeArea,
            place.thoroughfare,
            place.subThoroughfare
          ];

          for (var field in allFields) {
            if (field != null &&
                field.toLowerCase().contains("venganallur")) {
              isVenganallur = true;
              break;
            }
          }

          if (isVenganallur) {
            detectedArea = "Vadaku Venganallur";
          } else {
            // Fallback area detection: prefer subLocality, then locality, then others
            detectedArea =
                (place.subLocality != null && place.subLocality!.isNotEmpty)
                    ? place.subLocality!
                    : (place.locality != null && place.locality!.isNotEmpty)
                        ? place.locality!
                        : (place.subAdministrativeArea ?? place.name ?? "");
          }

          _areaCtrl.text = detectedArea;

          // Try to get Ward from backend API using coordinates
          String ward = "";
          try {
            final token = await TokenStorage.getToken();
            final wardResponse = await http.get(
              Uri.parse("${ApiConstants.baseUrl}/api/citizen/ward?lat=${pos.latitude}&lng=${pos.longitude}"),
              headers: {"Authorization": "Bearer $token"},
            );
            if (wardResponse.statusCode == 200) {
              final wardData = jsonDecode(wardResponse.body);
              if (wardData['ward'] != null && wardData['ward'].toString().trim().isNotEmpty) {
                ward = wardData['ward'].toString();
              }
            }
          } catch (e) {
            debugPrint("Failed to fetch ward from KML API: $e");
          }

          // Fallback to regex if backend fails
          if (ward.isEmpty) {
            RegExp wardRegex =
                RegExp(r'Ward\s*(?:No\.?)?\s*(\d+)', caseSensitive: false);

            for (var field in allFields) {
              if (field != null) {
                Match? match = wardRegex.firstMatch(field);
                if (match != null) {
                  ward = match.group(1) ?? "";
                  break;
                }
              }
            }
          }

          _wardCtrl.text = ward;
        }
      } catch (e) {
        debugPrint("Geocoding failed: $e");
        _addressCtrl.text = "Lat: ${pos.latitude}, Lng: ${pos.longitude}";
      }
    } catch (e) {
      debugPrint("Location error: $e");
      String errorMsg = e.toString().replaceAll("Exception: ", "");

      if (errorMsg.contains("Location services are disabled")) {
        // Show Action to Open Settings
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Location is disabled. Enable to auto-fill?"),
            action: SnackBarAction(
              label: "ENABLE",
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (errorMsg.contains("denied")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location denied. Please enter details manually."),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location Error: $errorMsg")),
        );
      }
    }
    setState(() => loading = false);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _image = File(photo.path);
        });
        // Refresh location when photo is taken to "tag" it
        _fetchLocation();
        _analyzeImage();
      }
    } catch (e) {
      debugPrint("Camera error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to capture photo")),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;
    
    setState(() {
      _isAnalyzing = true;
      _mlCategory = null;
      _mlSeverity = null;
    });

    try {
      final token = await TokenStorage.getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConstants.baseUrl}/api/citizen/predict"),
      );
      request.headers['Authorization'] = "Bearer $token";
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _mlCategory = data['category'];
          _mlSeverity = data['severity'];
          // Auto-fill suggested category and severity using map
          if (_mlCategory != null && _mlToUiMap.containsKey(_mlCategory)) {
            final uiCategory = _mlToUiMap[_mlCategory];
            if (uiCategory != "Others") {
              category = uiCategory;
            }
          }
          
          if (_mlSeverity != "NA" && _mlSeverity != null) {
            severity = _mlSeverity;
          }
        });
      }
    } catch (e) {
      debugPrint("ML Analysis error: $e");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _submitComplaint() async {
    if (category == null || severity == null || _addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final token = await TokenStorage.getToken();
      if (token == null) throw Exception("Not logged in");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConstants.baseUrl}/api/citizen/complaints"),
      );
      
      request.headers['Authorization'] = "Bearer $token";
      
      // Fields
      request.fields['category'] = category!;
      request.fields['severity'] = severity!;
      request.fields['latitude'] = currentPosition?.latitude.toString() ?? "0";
      request.fields['longitude'] = currentPosition?.longitude.toString() ?? "0";
      request.fields['street'] = _streetCtrl.text;
      request.fields['area'] = _areaCtrl.text;
      request.fields['ward'] = _wardCtrl.text;
      request.fields['city'] = _cityCtrl.text;
      
      // Location JSON
      final locMap = {
        "address": _addressCtrl.text,
        "lat": currentPosition?.latitude,
        "lng": currentPosition?.longitude,
        "street": _streetCtrl.text,
        "area": _areaCtrl.text,
        "ward": _wardCtrl.text,
        "city": _cityCtrl.text,
      };
      request.fields['location_json'] = jsonEncode(locMap);

      // File
      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _image!.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Complaint raised successfully!")),
        );
        Navigator.pop(context);
      } else {
        throw Exception("Server Error: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Raise Complaint"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Info Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              color: AppColors.primary.withOpacity(0.05),
              child: Row(
                children: [
                  const Icon(Icons.info, size: 18, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      currentPosition == null
                          ? (_manualEntry
                              ? "Enter Location Manually"
                              : "Fetching your location...")
                          : "Location accurately detected",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (currentPosition == null && !_manualEntry)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Location Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionHeader("LOCATION DETAILS"),
                      TextButton.icon(
                        onPressed: _fetchLocation,
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text("Use Current Location",
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildStyledField(_streetCtrl, "Street", Icons.map),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildStyledField(_areaCtrl, "Area", Icons.location_city)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildStyledField(_wardCtrl, "Ward No.", Icons.tag)),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildStyledField(_cityCtrl, "City", Icons.business),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 2. Complaint Details
                  _sectionHeader("COMPLAINT DETAILS"),
                  const SizedBox(height: 12),
                  
                  // Category Selection
                  const Text("Category", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((c) => ChoiceChip(
                      label: Text(c),
                      selected: category == c,
                      onSelected: (selected) => setState(() => category = selected ? c : null),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: category == c ? Colors.white : Colors.black87),
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Severity Selection
                  const Text("Severity", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: severities.map((s) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(child: Text(s)),
                          selected: severity == s,
                          onSelected: (selected) => setState(() => severity = selected ? s : null),
                          selectedColor: s == "High" ? AppColors.error : (s == "Medium" ? AppColors.warning : AppColors.success),
                          labelStyle: TextStyle(color: severity == s ? Colors.white : Colors.black87),
                        ),
                      ),
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 3. Photo Evidence
                  _sectionHeader("PHOTO EVIDENCE"),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!, width: 1, style: BorderStyle.solid),
                        image: _image != null
                            ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _image == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 32, color: AppColors.primary),
                                ),
                                const SizedBox(height: 12),
                                const Text("Capture Photo", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                                const Text("Tap to open camera", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            )
                          : Stack(
                              children: [
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () => setState(() => _image = null),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  if (_isAnalyzing || _mlCategory != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                      ),
                      child: _isAnalyzing 
                        ? Row(
                            children: [
                              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              const SizedBox(width: 12),
                              Text("AI analyzing image...", style: TextStyle(color: Colors.blue[800], fontSize: 13)),
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("AI SUGGESTION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue[600], letterSpacing: 1.1)),
                                    Text("Detected: $_mlCategory • Priority: $_mlSeverity", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    if (_mlCategory != null && _mlToUiMap.containsKey(_mlCategory)) {
                                      category = _mlToUiMap[_mlCategory];
                                    }
                                    severity = _mlSeverity;
                                  });
                                },
                                child: const Text("APPLY", style: TextStyle(fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                    ),
                  
                  const SizedBox(height: 48),
                  
                  // Submit Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SUBMIT REPORT", style: TextStyle(fontSize: 16, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildStyledField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
