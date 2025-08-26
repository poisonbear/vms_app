# Data Layer
데이터 레이어 - API 통신, 로컬 저장소, 모델 정의

## 마이그레이션 매핑
### DataSources
- `CmdSource.dart` → `datasources/remote/terms_remote_datasource.dart`
- `RosSource.dart` → `datasources/remote/navigation_remote_datasource.dart`
- `VesselSearchSource.dart` → `datasources/remote/vessel_remote_datasource.dart`

### Models
- `CmdModel.dart` → `models/terms/terms_model.dart`
- `RosModel.dart` → `models/navigation/navigation_model.dart`
- `VesselSearchModel.dart` → `models/vessel/vessel_model.dart`

### Repositories
- `CmdRepository.dart` → `repositories/terms_repository_impl.dart`
- `RosRepository.dart` → `repositories/navigation_repository_impl.dart`
- `VesselSearchRepository.dart` → `repositories/vessel_repository_impl.dart`
