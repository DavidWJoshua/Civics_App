import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/token_storage.dart';
import '../../../core/theme/app_colors.dart';

class MyComplaints extends StatefulWidget {
  const MyComplaints({super.key});

  @override
  State<MyComplaints> createState() => _MyComplaintsState();
}

class _MyComplaintsState extends State<MyComplaints> {
  bool loading = true;
  List<dynamic> complaints = [];

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConstants.baseUrl}/api/citizen/complaints");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            complaints = json.decode(response.body);
            loading = false;
          });
        }
      } else {
        throw Exception("Failed to load");
      }
    } catch (e) {
      debugPrint("Error fetching complaints: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Complaints",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:AppColors.primary,
        elevation: 0,
        centerTitle: false,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : complaints.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: complaints.length,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  itemBuilder: (context, index) {
                    final c = complaints[index];
                    return _buildComplaintCard(c);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Submissions Yet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          Text(
            "Issues you report will be listed here\nneatly for your tracking.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(dynamic c) {
    final status = c['status'] ?? 'UNKNOWN';
    final category = c['category'] ?? 'General';
    final severity = c['severity'] ?? 'Low';
    final imageUrl = c['image_url'] ?? '';
    final completionImageUrl = c['completion_image_url'] ?? '';
    final createdAt = c['created_at'] != null 
        ? DateTime.parse(c['created_at']).toLocal() 
        : DateTime.now();
    
    final street = c['street'] ?? '';
    final area = c['area'] ?? '';
    final city = c['city'] ?? 'Rajapalayam';

    Color statusColor;
    switch(status.toUpperCase()) {
      case "RAISED": statusColor = AppColors.warning; break;
      case "RESOLVED": 
      case "COMPLETED": statusColor = AppColors.success; break;
      case "IN_PROGRESS": statusColor = AppColors.secondary; break;
      default: statusColor = Colors.grey;
    }
    final rating = c['rating'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            if (imageUrl.isNotEmpty || completionImageUrl.isNotEmpty)
              Stack(
                children: [
                  if (imageUrl.isNotEmpty && completionImageUrl.isNotEmpty)
                    Row(
                      children: [
                        Expanded(child: _buildImageWithLabel(imageUrl, "BEFORE")),
                        const SizedBox(width: 2),
                        Expanded(child: _buildImageWithLabel(completionImageUrl, "AFTER")),
                      ],
                    )
                  else if (imageUrl.isNotEmpty)
                    _buildImageWithLabel(imageUrl, null)
                  else
                    _buildImageWithLabel(completionImageUrl, "COMPLETED"),

                  Positioned(
                    top: 16,
                    right: 16,
                    child: _statusBadge(status, statusColor),
                  ),
                ],
              )
            else
              Container(
                height: 80,
                color: statusColor.withOpacity(0.05),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(_getCategoryIcon(category), color: statusColor, size: 28),
                    _statusBadge(status, statusColor),
                  ],
                ),
              ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(severity).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          severity.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getSeverityColor(severity),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${street.isNotEmpty ? '$street, ' : ''}$area, $city",
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.year}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                      if (status == "COMPLETED")
                        if (rating > 0)
                          Row(
                            children: List.generate(5, (index) => Icon(
                              index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 18,
                              color: Colors.amber,
                            )),
                          )
                        else
                          TextButton(
                            onPressed: () => _showRatingDialog(c['id']),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text("Rate Resolution", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _showRatingDialog(String complaintId) {
    int selectedRating = 0;
    final feedbackController = TextEditingController();
    final List<String> emojis = ["😡", "😞", "😐", "😊", "😍"];
    final List<String> labels = ["Bad", "Poor", "Okay", "Good", "Great"];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Rate Service",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(5, (index) {
                    final isSelected = selectedRating == index + 1;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedRating = index + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        transform: Matrix4.identity()
                          ..scale(isSelected ? 1.2 : 1.0),
                        child: Column(
                          children: [
                            Text(
                              emojis[index],
                              style: TextStyle(
                                fontSize: isSelected ? 32 : 24,
                                color: isSelected
                                    ? null
                                    : Colors.black.withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isSelected)
                              Text(
                                labels[index],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: feedbackController,
                    decoration: const InputDecoration(
                      hintText: "Add a comment...",
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    maxLines: 2,
                    minLines: 1,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                        child: const Text("Skip"),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedRating == 0
                            ? null
                            : () {
                                _submitFeedback(complaintId, selectedRating,
                                    feedbackController.text);
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("Submit"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback(String id, int rating, String text) async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/citizen/complaints/$id/feedback"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "rating": rating,
          "feedback_text": text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Thank you for your feedback!")),
          );
          fetchComplaints();
        }
      }
    } catch (e) {
      debugPrint("Error submitting feedback: $e");
    }
  }

  Widget _buildImageWithLabel(String url, String? label) {
    String finalUrl;
    if (url.contains('fe_uploads/')) {
      final cleanPath = url.substring(url.indexOf('fe_uploads/'));
      finalUrl = '${ApiConstants.baseUrl}/$cleanPath';
    } else if (url.contains('uploads/')) {
      final cleanPath = url.substring(url.indexOf('uploads/'));
      finalUrl = '${ApiConstants.baseUrl}/$cleanPath';
    } else if (url.startsWith('http')) {
      finalUrl = url;
    } else if (url.startsWith('/')) {
      finalUrl = '${ApiConstants.baseUrl}$url';
    } else {
      finalUrl = '${ApiConstants.baseUrl}/$url';
    }
    debugPrint("🖼️ Loading Image: $finalUrl");

    return Stack(
      children: [
        Image.network(
          finalUrl,
          height: 200, // Increased height slightly
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Colors.grey[100],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (ctx, error, stackTrace) => Container(
            height: 200,
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined,
                    size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  "Image unavailable",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                )
              ],
            ),
          ),
        ),
        if (label != null)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _statusBadge(String status, Color color) {
    IconData statusIcon;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'RESOLVED':
        statusIcon = Icons.check_circle;
        break;
      case 'IN_PROGRESS':
        statusIcon = Icons.hourglass_top;
        break;
      case 'RAISED':
        statusIcon = Icons.pending;
        break;
      default:
        statusIcon = Icons.cancel;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'pipe breakage': return Icons.broken_image_rounded;
      case 'leakage': return Icons.water_drop_rounded;
      case 'overflow': return Icons.waves_rounded;
      case 'sinkhole': return Icons.warning_rounded; 
      case 'manhole missing': return Icons.dangerous_rounded;
      case 'clogged drain': return Icons.filter_list_off_rounded;
      default: return Icons.report_problem_rounded;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high': return AppColors.error;
      case 'medium': return AppColors.warning;
      default: return AppColors.success;
    }
  }
}
