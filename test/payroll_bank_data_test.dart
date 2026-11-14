import 'package:flutter_test/flutter_test.dart';
import '../lib/services/api_client.dart';
import '../lib/services/payroll_bank_data.dart';

void main() {
  test('conserva los ceros iniciales de cuenta y CLABE como texto', () {
    final value = PayrollBankData.normalize({
      'banco': ' Banco de ejemplo ', 'cuenta': '0012345678',
      'clabe': '001 234 567 890 123 456', 'titular': '',
    }, fallbackHolder: 'Elena Pérez');
    expect(value['banco'], 'Banco de ejemplo');
    expect(value['cuenta'], '0012345678');
    expect(value['clabe'], '001234567890123456');
    expect(value['titular'], 'Elena Pérez');
  });
  test('los datos bancarios son opcionales al registrar un empleado', () {
    final value = PayrollBankData.normalize({}, fallbackHolder: 'Elena Pérez');
    expect(value['banco'], ''); expect(value['cuenta'], ''); expect(value['clabe'], '');
  });
  test('rechaza CLABE incompleta o con letras antes de enviar', () {
    for (final clabe in ['123', '00123456789012345', '00123456789012345A']) {
      expect(() => PayrollBankData.normalize({'clabe': clabe}), throwsA(isA<ApiException>()));
    }
  });
  test('conserva el titular capturado y valida longitudes del servidor', () {
    expect(PayrollBankData.normalize({'titular': ' Otra persona '}, fallbackHolder: 'Elena')['titular'], 'Otra persona');
    expect(() => PayrollBankData.normalize({'banco': List.filled(101, 'A').join()}), throwsA(isA<ApiException>()));
    expect(() => PayrollBankData.normalize({'cuenta': List.filled(41, '0').join()}), throwsA(isA<ApiException>()));
  });
}
