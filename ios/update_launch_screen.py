#!/usr/bin/env python3
import os
import re

storyboard_path = 'Runner/Base.lproj/LaunchScreen.storyboard'

if os.path.exists(storyboard_path):
    with open(storyboard_path, 'r') as f:
        content = f.read()
    
    # LaunchImage 제거
    content = re.sub(r'<imageView[^>]*image="LaunchImage"[^>]*>.*?</imageView>', 
                     '<!-- LaunchImage removed -->', content, flags=re.DOTALL)
    
    # 배경색을 투명으로 변경
    content = re.sub(r'red="1" green="1" blue="1"', 
                     'red="0" green="0.749" blue="1"', content)
    
    with open(storyboard_path, 'w') as f:
        f.write(content)
    
    print("iOS LaunchScreen.storyboard updated")
else:
    print(" LaunchScreen.storyboard not found")
