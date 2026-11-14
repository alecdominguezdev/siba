import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/mobile_models.dart';
import '../lib/services/api_client.dart';
import '../lib/services/siba_access.dart';
import '../lib/services/worksite_api.dart';
import '../lib/screens/module_common.dart';
import '../lib/screens/login_page.dart';
import '../lib/theme/siba_theme.dart';

void main() {
  tearDown(() { ApiClient.instance.currentAccess=null;ApiClient.instance.currentUser=null; });
  test('captura pesos sin alterar centavos y rechaza importes ambiguos', () {
    expect(WorksiteApi.amount(r'$1,500,000.25'),'1500000.25');
    expect(WorksiteApi.amount('400.00'),'400.00');
    for(final value in ['','1.999','-10','1e4','NaN','abc']) {
      expect(()=>WorksiteApi.amount(value),throwsA(isA<ApiException>()));
    }
    expect(sibaMoney(1500000.25),r'$1,500,000.25');
    expect(sibaMoney(-1500000.25),r'-$1,500,000.25');
  });
  test('Personal de obra no hereda el menú financiero de la sesión previa', () {
    ApiClient.instance.currentUser=const MobileUser(id:7,name:'Personal',username:'obra',role:'Personal de obra');
    ApiClient.instance.currentAccess=MobileAccessProfile.fromJson({
      'attendanceOnly':true,'companyRole':'Personal de obra','companyRoles':['Personal de obra'],
      'modules':[{'key':'asistencias','allowed':true,'mobileAvailable':true},{'key':'presupuesto','allowed':false,'mobileAvailable':true},{'key':'nomina','allowed':false,'mobileAvailable':true}]
    });
    expect(SibaAccess.attendanceOnly,true);
    expect(SibaAccess.canManage,false);
    expect(SibaAccess.allowed('asistencias'),true);
    expect(SibaAccess.allowed('presupuesto'),false);
    expect(SibaAccess.allowed('nomina'),false);
  });
  test('Gerencia y Dirección reconocen roles adicionales autorizados', () {
    for(final role in ['Dirección','Gerente de obra','Gerencia de proyectos']) {
      ApiClient.instance.currentUser=const MobileUser(id:7,name:'Usuario',username:'gerencia',role:'Supervisor');
      ApiClient.instance.currentAccess=MobileAccessProfile.fromJson({'companyRole':'Supervisor','companyRoles':['Supervisor',role],'modules':[{'key':'nomina','allowed':true,'mobileAvailable':true}]});
      expect(SibaAccess.canManage,true);
    }
  });
  testWidgets('el acceso conserva sus botones y campos en teléfono angosto', (tester) async {
    tester.view.physicalSize=const Size(320,640);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme:buildSibaTheme(),home:const LoginPage()));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'),findsOneWidget);
    expect(find.text('Entrar'),findsOneWidget);
    expect(find.byType(TextFormField),findsNWidgets(2));
    expect(tester.takeException(),isNull);
  });
}
