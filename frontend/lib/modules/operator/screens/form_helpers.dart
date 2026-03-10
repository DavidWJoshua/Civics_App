import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';

mixin FormHelpers<T extends StatefulWidget> on State<T> {
  final Map<String, dynamic> formData = {};
  bool isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const Divider(thickness: 1.5, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget buildTextField(String label, String key, {bool isNumber = false, bool isInt = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        onChanged: (val) {
          if (val.isEmpty) {
            formData.remove(key);
            return;
          }
          if (isNumber) {
            if (isInt) {
              formData[key] = int.tryParse(val) ?? val;
            } else {
              formData[key] = double.tryParse(val) ?? val;
            }
          } else {
            formData[key] = val;
          }
        },
        validator: (val) {
           if (isNumber && val != null && val.isNotEmpty) {
             if (isInt && int.tryParse(val) == null) return "Enter valid integer";
             if (!isInt && double.tryParse(val) == null) return "Enter valid number";
           }
           return null;
        },
      ),
    );
  }

  Widget buildDropdown(String label, String key, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => formData[key] = val,
      ),
    );
  }

  Widget buildSwitch(String label, String key) {
    // Ensure default is false if not set
    if (!formData.containsKey(key)) {
        formData[key] = false;
    }
    
    return FormField<bool>(
      initialValue: formData[key] ?? false,
      builder: (state) {
        return SwitchListTile(
          title: Text(label),
          value: state.value ?? false,
          activeColor: AppColors.primary,
          onChanged: (val) {
             state.didChange(val);
             setState(() => formData[key] = val);
          },
        );
      }
    );
  }

  Future<void> pickAndUploadImage(String key) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() => isUploading = true);

    try {
       // Simulator Mock
       await Future.delayed(const Duration(seconds: 1)); 
       
       setState(() {
         formData[key] = "https://via.placeholder.com/150"; 
         isUploading = false;
       });
       
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo Uploaded (Mock)!")));
       }
    } catch (e) {
      if (mounted) {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Widget buildImagePicker(String label, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: isUploading ? null : () => pickAndUploadImage(key),
              icon: const Icon(Icons.camera_alt),
              label: Text(formData[key] != null ? "Retake Photo" : "Take Photo"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200], 
                  foregroundColor: Colors.black,
                  elevation: 0
              ),
            ),
            const SizedBox(width: 10),
            if (isUploading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            if (formData[key] != null && !isUploading) 
              const Icon(Icons.check_circle, color: Colors.green, size: 24)
          ],
        ),
        if (formData[key] != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
                "Uploaded: ...${formData[key].toString().length > 10 ? formData[key].toString().substring(formData[key].toString().length - 10) : formData[key]}", 
                style: const TextStyle(color: Colors.grey, fontSize: 12)
            ),
          ),
        const SizedBox(height: 15),
      ],
    );
  }
}
