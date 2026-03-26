import os

filepath = r'c:\Users\david\OneDrive\Desktop\civic-complaint-system-main-main (2)\civic-complaint-system-main-main\frontend\lib\modules\citizen\screens\my_complaints.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

import re
pattern = re.compile(r'String finalUrl[\s\S]*?ApiConstants\.baseUrl\}/\\"\)\);', re.MULTILINE)

new_content = '''    String finalUrl = url;
    if (url.contains("fe_uploads/")) {
      final cleanPath = url.substring(url.indexOf("fe_uploads/"));
      finalUrl = "\/\";
    } else if (url.contains("uploads/")) {
      final idx = url.indexOf("uploads/");
      if (idx == 0 || url[idx - 1] == '/') {
        final cleanPath = url.substring(idx);
        finalUrl = "\/\";
      }
    } else if (!url.startsWith('http')) {
      finalUrl = url.startsWith('/') 
          ? "\\" 
          : "\/\";
    }'''

content = pattern.sub(new_content, content, count=1)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done!')
