import os

filepath = r'c:\Users\david\OneDrive\Desktop\civic-complaint-system-main-main (2)\civic-complaint-system-main-main\frontend\lib\modules\citizen\screens\my_complaints.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

import re
old_block_pattern = re.compile(r'(Widget _buildImageWithLabel\(String url, String\? label\) \{).*?(return Stack)', re.DOTALL)

# Use absolute literal strings to prevent ANY interpolation escapes
new_code = '''Widget _buildImageWithLabel(String url, String? label) {
    if (url.isEmpty) return const SizedBox();
    String finalUrl = url;
    if (url.contains("fe_uploads/")) {
      final cleanPath = url.substring(url.indexOf("fe_uploads/"));
      finalUrl = "/";
    } else if (url.contains("uploads/")) {
      final idx = url.indexOf("uploads/");
      if (idx == 0 || url[idx - 1] == '/') {
        final cleanPath = url.substring(idx);
        finalUrl = "/";
      }
    } else if (!url.startsWith('http')) {
      finalUrl = url.startsWith('/') 
          ? "" 
          : "/";
    }
    debugPrint("??? Loading Image: ");

    return Stack'''

# Avoid python f-strings natively
new_code = new_code.replace('', '')
new_code = new_code.replace('', '')
new_code = new_code.replace('', '')
new_code = new_code.replace('', '')

content = old_block_pattern.sub(new_code.replace('\\', '\\\\'), content, count=1)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done!')
