import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';

class GetNavigationHistory {
  final NavigationRepository repository;

  GetNavigationHistory(this.repository);

  Future<List<RosModel>> execute({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    return await repository.getRosList(
      startDate: startDate,
      endDate: endDate,
      mmsi: mmsi,
      shipName: shipName,
    );
  }
}