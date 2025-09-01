import 'dart:io';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:path/path.dart' as path;

void main() async {
  AppLogger.i('이미지 최적화 시작...');
  
  final assetsDir = Directory('assets');
  if (!assetsDir.existsSync()) {
    AppLogger.d('assets 디렉토리가 없습니다.');
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
  
  AppLogger.d('발견된 이미지: ${imageFiles.length}개');
  
  for (var file in imageFiles) {
    final fileSize = (file as File).lengthSync();
    final fileSizeKB = (fileSize / 1024).toStringAsFixed(2);
    AppLogger.d('  - ${path.basename(file.path)}: ${fileSizeKB}KB');
    
    // 100KB 이상인 이미지 경고
    if (fileSize > 100 * 1024) {
      AppLogger.d('    ⚠️  큰 이미지 파일! 최적화 필요');
    }
  }
  
  AppLogger.d('\n💡 이미지 최적화 권장사항:');
  AppLogger.d('  1. PNG → WebP 변환으로 50-70% 크기 감소');
  AppLogger.d('  2. 큰 이미지는 여러 해상도로 분리 (1x, 2x, 3x)');
  AppLogger.d('  3. 불필요한 메타데이터 제거');
}
