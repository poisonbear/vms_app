import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';

class GetNavigationHistoryParams {
  final String? startDate;
  final String? endDate;
  final int? mmsi;
  final String? shipName;

  GetNavigationHistoryParams({
    this.startDate,
    this.endDate,
    this.mmsi,
    this.shipName,
  });
}

class GetNavigationHistory {
  final NavigationRepository repository;

  GetNavigationHistory(this.repository);

  Future<List<RosModel>> execute(GetNavigationHistoryParams params) async {
    return await repository.getRosList(
      startDate: params.startDate,
      endDate: params.endDate,
      mmsi: params.mmsi,
      shipName: params.shipName,
    );
  }
}
