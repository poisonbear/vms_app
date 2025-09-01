import 'dart:io';
import 'package:path/path.dart' as path;

void main() async {
  print('이미지 최적화 시작...');
  
  final assetsDir = Directory('assets');
  if (!assetsDir.existsSync()) {
    print('assets 디렉토리가 없습니다.');
    return;
  }
  
  // 이미지 파일 찾기
  final imageFiles = assetsDir
      .listSync(recursive: true)
      .where((file) => 
          file is File &&
          (file.path.endsWith('.png') || 
           file.path.endsWith('.jpg') || 
           file.path.endsWith('.jpeg')))
      .toList();
  
  print('발견된 이미지: ${imageFiles.length}개');
  
  for (var file in imageFiles) {
    final fileSize = (file as File).lengthSync();
    final fileSizeKB = (fileSize / 1024).toStringAsFixed(2);
    print('  - ${path.basename(file.path)}: ${fileSizeKB}KB');
    
    // 100KB 이상인 이미지 경고
    if (fileSize > 100 * 1024) {
      print('    ⚠️  큰 이미지 파일! 최적화 필요');
    }
  }
  
  print('\n💡 이미지 최적화 권장사항:');
  print('  1. PNG → WebP 변환으로 50-70% 크기 감소');
  print('  2. 큰 이미지는 여러 해상도로 분리 (1x, 2x, 3x)');
  print('  3. 불필요한 메타데이터 제거');
}
