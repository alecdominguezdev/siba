import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/siba_access.dart';
import '../services/worksite_api.dart';
import '../theme/siba_theme.dart';
import '../widgets/siba_widgets.dart';
import 'module_common.dart';

class SibaHomePage extends StatefulWidget {
  final void Function(String) onOpen;
  const SibaHomePage({super.key,required this.onOpen});
  @override State<SibaHomePage> createState()=>_SibaHomePageState();
}
class _SibaHomePageState extends State<SibaHomePage>{
  Map<String,dynamic>? _summary;String? _error;bool _loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{setState((){_loading=true;_error=null;});try{if(SibaAccess.allowed('presupuesto'))_summary=await WorksiteApi.request('/projects/operations-summary');}catch(e){_error='$e';}finally{if(mounted)setState(()=>_loading=false);}}
  @override Widget build(BuildContext context){
    final totals=WorksiteApi.map(_summary?['summary']),projects=WorksiteApi.rows(_summary?['projects']);
    return RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(20),physics:const AlwaysScrollableScrollPhysics(),children:[
      Text('Hola, ${ApiClient.instance.currentUser?.displayName ?? 'Usuario'}',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:6),Text(SibaAccess.roleLabel,style:const TextStyle(color:SibaColors.muted)),const SizedBox(height:22),
      if(_loading)const LinearProgressIndicator(),if(_error!=null)SibaEmptyState(icon:Icons.error_outline,title:'No se pudo actualizar',message:_error!,error:true,action:TextButton(onPressed:_load,child:const Text('Reintentar'))),
      if(_summary!=null)...[SibaSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Control de gastos',style:TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:14),Text(sibaMoney(totals['spent']),style:Theme.of(context).textTheme.headlineSmall),const Text('Gasto registrado',style:TextStyle(color:SibaColors.muted)),const SizedBox(height:12),Text('Disponible: ${totals['available']==null?'Metas por definir':sibaMoney(totals['available'])}',style:const TextStyle(fontWeight:FontWeight.w600)),const SizedBox(height:6),Text('${projects.length} obras activas',style:const TextStyle(color:SibaColors.muted))])),const SizedBox(height:20)],
      for(final item in <(String,String,IconData)>[if(SibaAccess.allowed('presupuesto'))('projects','Proyectos',Icons.business_center_outlined),if(SibaAccess.allowed('asistencias'))('attendance','Asistencias',Icons.fingerprint),('modules','Módulos',Icons.grid_view_rounded)])Padding(padding:const EdgeInsets.only(bottom:12),child:SibaSurface(onTap:()=>widget.onOpen(item.$1),child:Row(children:[SibaIconTile(icon:item.$3),const SizedBox(width:14),Expanded(child:Text(item.$2,style:Theme.of(context).textTheme.titleMedium)),const Icon(Icons.chevron_right)]))),
    ]));
  }
}
