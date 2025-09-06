import 'dart:io';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:path/path.dart' as path;

void main() async {
  AppLogger.i(StringConstants.startOptimization);

  final assetsDir = Directory(StringConstants.assetsDir);
  if (!assetsDir.existsSync()) {
    AppLogger.d(StringConstants.noAssetsDir);
    return;
  }

  // 이미지 파일 찾기
  final imageFiles = assetsDir
      .listSync(recursive: true)
      .where((file) =>
          file is File &&
          (file.path.endsWith(StringConstants.pngExtension) ||
              file.path.endsWith(StringConstants.jpgExtension) ||
              file.path.endsWith(StringConstants.jpegExtension)))
      .toList();

  AppLogger.d('${StringConstants.foundImages}: ${imageFiles.length}${StringConstants.unitBytes}');

  for (var file in imageFiles) {
    final fileSize = (file as File).lengthSync();
    final fileSizeKB = (fileSize / NumericConstants.bytesPerKB).toStringAsFixed(ValidationConstants.debugDecimalPlaces);
    AppLogger.d('  - ${path.basename(file.path)}: $fileSizeKB${StringConstants.unitKB}');

    // 100KB 이상인 이미지 경고
    if (fileSize > ValidationConstants.maxImageFileSizeBytes) {
      AppLogger.d('    ${StringConstants.largeFileWarning}');
    }
  }

  AppLogger.d('\n💡 이미지 최적화 권장사항:');
  AppLogger.d('  1. PNG → WebP 변환으로 50-70% 크기 감소');
  AppLogger.d('  2. 큰 이미지는 여러 해상도로 분리 (1x, 2x, 3x)');
  AppLogger.d('  3. 불필요한 메타데이터 제거');
}
