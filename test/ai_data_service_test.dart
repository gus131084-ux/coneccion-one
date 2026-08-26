import 'package:flutter_test/flutter_test.dart';
import 'package:coneccionone/services/ai_data_service.dart';

void main() {
  group('AiDataService helper unit tests', () {
    test('Status normalizer handles various string values', () {
      expect(AiDataService.normalizeStatusForTest('En proceso'), 'En proceso');
      expect(AiDataService.normalizeStatusForTest('en reparacion'), 'En proceso');
      expect(AiDataService.normalizeStatusForTest('Terminado'), 'Terminado');
      expect(AiDataService.normalizeStatusForTest('Listo para entregar'), 'Terminado');
      expect(AiDataService.normalizeStatusForTest('Entregado'), 'Entregado');
      expect(AiDataService.normalizeStatusForTest('pendiente'), 'Pendiente');
      expect(AiDataService.normalizeStatusForTest(null), 'Pendiente');
    });

    test('Number converters handle various types', () {
      expect(AiDataService.toDoubleForTest(150), 150.0);
      expect(AiDataService.toDoubleForTest('250.50'), 250.50);
      expect(AiDataService.toDoubleForTest(null), 0.0);
      expect(AiDataService.toDoubleForTest('invalid'), 0.0);

      expect(AiDataService.toIntForTest(10), 10);
      expect(AiDataService.toIntForTest('5'), 5);
      expect(AiDataService.toIntForTest(null), 0);
    });
  });
}

