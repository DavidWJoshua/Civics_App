import 'dart:io';

void main() {
  final file = File('c:/Users/david/OneDrive/Desktop/civic-complaint-system-main-main (2)/civic-complaint-system-main-main/frontend/lib/modules/citizen/screens/my_complaints.dart');
  String content = file.readAsStringSync();
  
  final RegExp regex = RegExp(r'(Widget _buildImageWithLabel\(String url, String\? label\) \{).*?(return Stack)', multiLine: true, dotAll: true);
  
  final replacement = '''Widget _buildImageWithLabel(String url, String? label) {
    if (url.isEmpty) return const SizedBox();
    String finalUrl = url;
    if (url.contains("fe_uploads/")) {
      final cleanPath = url.substring(url.indexOf("fe_uploads/"));
      finalUrl = "\\\/\";
    } else if (url.contains("uploads/")) {
      final idx = url.indexOf("uploads/");
      if (idx == 0 || url[idx - 1] == '/') {
        final cleanPath = url.substring(idx);
        finalUrl = "\\\/\";
      }
    } else if (!url.startsWith('http')) {
      finalUrl = url.startsWith('/') 
          ? "\\\\" 
          : "\\\/\";
    }
    debugPrint("??? Loading Image: \");

    return Stack''';

  final ext = content.replaceAll(regex, replacement.replaceAll('\\\$', '\$'));
  file.writeAsStringSync(ext);
  print('Done');
}
