import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/siba_access.dart';
import '../services/budget_notification_service.dart';
import '../services/push_notification_service.dart';
import '../services/shared_document_service.dart';
import '../theme/siba_theme.dart';
import '../widgets/siba_widgets.dart';
import 'siba_home_page.dart';
import 'modules_page.dart';
import 'login_page.dart';
import 'attendance_page.dart';
import 'profile_page.dart';
import 'projects_page.dart';
import 'budgets_page.dart';
import 'document_assignment_page.dart';

class SibaShellPage extends StatefulWidget {
  const SibaShellPage({super.key});
  @override State<SibaShellPage> createState()=>_SibaShellPageState();
}
class _SibaShellPageState extends State<SibaShellPage> with WidgetsBindingObserver {
  String _current='home';Timer? _timer;StreamSubscription<int?>? _push;StreamSubscription? _foreground;bool _opening=false;
  List<(String,String,IconData)> get _destinations=>[
    if(!SibaAccess.attendanceOnly)('home','Inicio',Icons.home_outlined),
    if(SibaAccess.allowed('presupuesto'))('projects','Proyectos',Icons.business_center_outlined),
    if(SibaAccess.allowed('asistencias'))('attendance','Asistencias',Icons.fingerprint),
    if(!SibaAccess.attendanceOnly)('modules','Módulos',Icons.grid_view_rounded),
    ('account','Cuenta',Icons.person_outline),
  ];
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);if(SibaAccess.attendanceOnly)_current='attendance';_prepare();}
  Future<void> _prepare()async{
    _push=PushNotificationService.instance.openedBudgets.listen((id){if(!mounted||!SibaAccess.allowed('presupuesto'))return;if(id!=null&&id>0){Navigator.push(context,MaterialPageRoute(builder:(_)=>BudgetDetailPage(budgetId:id,onStatusChanged:_refreshBudgets)));}});
    _foreground=PushNotificationService.instance.foregroundMessages.listen((message){if(!SibaAccess.allowed('presupuesto'))return;_refreshBudgets();PushNotificationService.showBackgroundBudgetNotification(message);});
    try{await PushNotificationService.instance.initialize();await PushNotificationService.instance.registerCurrentDevice();}catch(_){}
    if(!mounted)return;
    SharedDocumentService.instance.addListener(_shared);
    if(SibaAccess.allowed('presupuesto')){_refreshBudgets();_timer=Timer.periodic(const Duration(minutes:2),(_)=>_refreshBudgets());}
    _shared();
  }
  Future<void> _refreshBudgets()async{if(!SibaAccess.allowed('presupuesto'))return;try{final items=await ApiClient.instance.budgets(pendingApproval:true);BudgetNotificationService.instance.setBudgetBadge(items.length);}catch(_){}}
  Future<void> _shared()async{if(!mounted||_opening||!SharedDocumentService.instance.hasPending)return;final files=SharedDocumentService.instance.takePending();if(SibaAccess.attendanceOnly){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Tu perfil solo permite registrar asistencias.')));return;}_opening=true;await Navigator.push(context,MaterialPageRoute(builder:(_)=>DocumentAssignmentPage(initialFiles:files,source:'compartido')));_opening=false;}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed)_access();}
  Future<void> _access()async{try{await ApiClient.instance.access();if(mounted)setState((){if(!_destinations.any((d)=>d.$1==_current))_current=_destinations.first.$1;});}catch(_){}}
  void _go(String key){if(_destinations.any((d)=>d.$1==key))setState(()=>_current=key);}
  Future<void> _logout()async{await ApiClient.instance.logout();if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginPage()),(_)=>false);}
  Widget _page(){switch(_current){case 'projects':return const ProjectsPage(embedded:true);case 'attendance':return const AttendancePage();case 'modules':return const ModulesPage();case 'account':return ProfilePage(onLogout:_logout);default:return SibaHomePage(onOpen:_go);}}
  @override void dispose(){WidgetsBinding.instance.removeObserver(this);_timer?.cancel();_push?.cancel();_foreground?.cancel();SharedDocumentService.instance.removeListener(_shared);super.dispose();}
  @override Widget build(BuildContext context){final destinations=_destinations;final index=destinations.indexWhere((d)=>d.$1==_current);if(index<0)_current=destinations.first.$1;
    return Scaffold(appBar:AppBar(title:const SibaLogo(width:110),actions:[IconButton(onPressed:()=>_go('account'),icon:const Icon(Icons.account_circle_outlined))]),drawer:Drawer(child:SafeArea(child:Column(children:[const Padding(padding:EdgeInsets.all(24),child:SibaLogo(width:145)),ListTile(title:Text(ApiClient.instance.currentUser?.displayName??''),subtitle:Text(SibaAccess.roleLabel)),const Divider(),for(final d in destinations)ListTile(leading:Icon(d.$3),title:Text(d.$2),selected:_current==d.$1,onTap:(){Navigator.pop(context);_go(d.$1);}),const Spacer(),ListTile(leading:const Icon(Icons.logout),title:const Text('Cerrar sesión'),onTap:(){Navigator.pop(context);_logout();})]))),body:KeyedSubtree(key:ValueKey(_current),child:_page()),bottomNavigationBar:destinations.length<2?null:NavigationBar(selectedIndex:destinations.indexWhere((d)=>d.$1==_current),onDestinationSelected:(i)=>_go(destinations[i].$1),backgroundColor:SibaColors.surface,indicatorColor:SibaColors.primarySoft,destinations:destinations.map((d)=>NavigationDestination(icon:Icon(d.$3),label:d.$2)).toList()));
  }
}
