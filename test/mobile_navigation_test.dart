import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/mobile_models.dart';
import '../lib/services/api_client.dart';
import '../lib/services/siba_access.dart';
import '../lib/screens/siba_home_page.dart';
import '../lib/screens/project_page.dart';
import '../lib/theme/siba_theme.dart';

const project=SibaProject(id:3,folio:'COT260001',company:'SIBA',client:'Cliente de prueba',title:'Construcción y pavimentación de avenida con un nombre extenso para comprobar el teléfono',area:'Zona norte',po:'Sin PO',state:'En proceso',status:'Proyecto aprobado',supervisor:'Supervisor',lastProgress:35);
void main(){
 setUp((){
  ApiClient.instance.currentUser=const MobileUser(id:1,name:'Alejandro',username:'admin',role:'SuperAdmin');
  ApiClient.instance.currentAccess=MobileAccessProfile.fromJson({'companyRole':'SuperAdmin','companyRoles':['SuperAdmin'],'modules':[{'key':'presupuesto','allowed':true,'mobileAvailable':true},{'key':'asistencias','allowed':true,'mobileAvailable':true},{'key':'nomina','allowed':true,'mobileAvailable':true}]});
 });
 tearDown((){ApiClient.instance.currentUser=null;ApiClient.instance.currentAccess=null;});
 testWidgets('inicio angosto conserva proyectos y asistencia sin mostrar módulos de computadora',(tester)async{
  tester.view.physicalSize=const Size(320,720);tester.view.devicePixelRatio=1;addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  String? destination;
  await tester.pumpWidget(MaterialApp(theme:buildSibaTheme(),home:Scaffold(body:SibaHomePage(onOpen:(key)=>destination=key,loadProjects:()async=>[project]))));await tester.pumpAndSettle();
  expect(SibaAccess.isSuperAdmin,true);expect(find.text('Módulos'),findsNothing);expect(find.text('Todos los proyectos'),findsOneWidget);
  await tester.ensureVisible(find.text('Mi asistencia'));await tester.tap(find.text('Mi asistencia'));expect(destination,'attendance');expect(tester.takeException(),isNull);
 });
 testWidgets('proyecto compacto ofrece informes, personal y detalles desplegables',(tester)async{
  tester.view.physicalSize=const Size(320,720);tester.view.devicePixelRatio=1;addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(theme:buildSibaTheme(),home:ProjectPage(project:project,loadOverview:()async=>{'project':{'accepted':true},'canTakeAttendance':true,'canManage':true,'personnel':[{'nombre':'Operador de prueba','puesto':'Operador','estado':'activo'}],'summary':{'limit':5000,'spent':1000,'available':4000},'meta':{'schedule':{}}})));await tester.pumpAndSettle();
  expect(find.text('Informes'),findsOneWidget);expect(find.text('Nuevo informe con fotos'),findsOneWidget);expect(find.text('Módulos'),findsNothing);
  await tester.ensureVisible(find.text('Información del proyecto'));await tester.tap(find.text('Información del proyecto'));await tester.pumpAndSettle();expect(find.text('Cliente de prueba'),findsOneWidget);expect(tester.takeException(),isNull);
 });
}
