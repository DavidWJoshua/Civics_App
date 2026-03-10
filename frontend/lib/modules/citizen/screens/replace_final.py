import os

filepath = r'c:\Users\david\OneDrive\Desktop\civic-complaint-system-main-main (2)\civic-complaint-system-main-main\frontend\lib\modules\citizen\screens\my_complaints.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

import re
pattern = re.compile(r'(Widget _buildImageWithLabel\(String url, String\? label\) \{).*?(return Stack)', re.DOTALL)

new_content = r'''\1
    if (url.isEmpty) return const SizedBox();
    String finalUrl = url;
    if (url.contains("fe_uploads/")) {
      final cleanPath = url.substring(url.indexOf("fe_uploads/"));
      finalUrl = "/" + cleanPath;
    } else if (url.contains("uploads/")) {
      final idx = url.indexOf("uploads/");
      if (idx == 0 || url[idx - 1] == '/') {
        final cleanPath = url.substring(idx);
        finalUrl = "/" + cleanPath;
      }
    } else if (!url.startsWith('http')) {
      finalUrl = url.startsWith('/') 
          ? "" + url 
          : "/" + url;
    }
    debugPrint("??? Loading Image: " + finalUrl);

    \2'''

# Inject actual literal string ""
new_content = new_content.replace('', r'')

content = pattern.sub(new_content, content, count=1)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done!')
