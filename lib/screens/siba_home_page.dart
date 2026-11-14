import 'package:flutter/material.dart';
import '../models/mobile_models.dart';
import '../services/api_client.dart';
import '../services/siba_access.dart';
import '../theme/siba_theme.dart';
import '../widgets/siba_widgets.dart';
import 'project_page.dart';

class SibaHomePage extends StatefulWidget {
  final void Function(String) onOpen;
  final Future<List<SibaProject>> Function()? loadProjects;
  const SibaHomePage({super.key,required this.onOpen,this.loadProjects});
  @override State<SibaHomePage> createState()=>_SibaHomePageState();
}
class _SibaHomePageState extends State<SibaHomePage>{
  List<SibaProject> _projects=[];String? _error;bool _loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{
    setState((){_loading=true;_error=null;});
    try{final rows=SibaAccess.allowed('presupuesto')?await (widget.loadProjects?.call()??ApiClient.instance.projects()):<SibaProject>[];if(mounted)setState(()=>_projects=rows);}
    catch(e){if(mounted)setState(()=>_error='$e');}finally{if(mounted)setState(()=>_loading=false);}
  }
  @override Widget build(BuildContext context){
    final name=ApiClient.instance.currentUser?.displayName.trim().split(' ').first??'Usuario';
    return RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.fromLTRB(20,20,20,30),physics:const AlwaysScrollableScrollPhysics(),children:[
      Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:SibaColors.primaryDeep,borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('EN OBRA',style:TextStyle(color:Color(0xFFB7CBF0),letterSpacing:2,fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(height:12),Text('Hola, $name',style:const TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.w800)),const SizedBox(height:8),Text(SibaAccess.roleLabel,style:const TextStyle(color:Color(0xFFC9D8ED))),const SizedBox(height:24),
        Wrap(spacing:24,runSpacing:14,children:[_HomeMetric(value:_loading?'—':'${_projects.length}',label:'Proyectos'),_HomeMetric(value:_loading?'—':'${_projects.where((p)=>p.lastReportAt!=null).length}',label:'Con informes')]),
      ])),const SizedBox(height:24),
      const SibaSectionTitle(title:'Accesos rápidos'),const SizedBox(height:12),
      if(SibaAccess.allowed('presupuesto'))_HomeAction(icon:Icons.business_center_outlined,title:SibaAccess.isSuperAdmin?'Todos los proyectos':'Proyectos',subtitle:'Avances, equipo y documentos',onTap:()=>widget.onOpen('projects')),
      if(SibaAccess.allowed('asistencias'))_HomeAction(icon:Icons.fingerprint_rounded,title:'Mi asistencia',subtitle:'Registrar entrada o salida',onTap:()=>widget.onOpen('attendance')),
      if(SibaAccess.allowed('presupuesto'))...[
        const SizedBox(height:20),SibaSectionTitle(title:'Proyectos recientes',trailing:TextButton(onPressed:()=>widget.onOpen('projects'),child:const Text('Ver todos'))),const SizedBox(height:12),
        if(_loading)const SibaSkeleton(height:140)
        else if(_error!=null)SibaEmptyState(icon:Icons.cloud_off_outlined,title:'No se pudo actualizar',message:_error!,action:TextButton(onPressed:_load,child:const Text('Reintentar')))
        else if(_projects.isEmpty)const SibaEmptyState(icon:Icons.business_center_outlined,title:'Sin proyectos disponibles',message:'Aquí aparecerán los proyectos de tu cuenta.')
        else for(final project in _projects.take(3))Padding(padding:const EdgeInsets.only(bottom:12),child:SibaProjectTile(project:project,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProjectPage(project:project))))),
      ],
    ]));
  }
}
class _HomeMetric extends StatelessWidget{
 final String value,label;const _HomeMetric({required this.value,required this.label});
 @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:const TextStyle(fontSize:26,color:Colors.white,fontWeight:FontWeight.w800)),Text(label,style:const TextStyle(color:Color(0xFFB7CBF0),fontSize:12))]);
}
class _HomeAction extends StatelessWidget{
 final IconData icon;final String title,subtitle;final VoidCallback onTap;const _HomeAction({required this.icon,required this.title,required this.subtitle,required this.onTap});
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:12),child:SibaSurface(onTap:onTap,child:Row(children:[SibaIconTile(icon:icon,size:46),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:4),Text(subtitle,style:Theme.of(context).textTheme.bodySmall)])),const Icon(Icons.chevron_right_rounded,color:SibaColors.muted)])));
}
