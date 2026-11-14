import 'package:flutter/material.dart';
import '../models/mobile_models.dart';
import '../services/api_client.dart';
import '../services/worksite_api.dart';
import '../theme/siba_theme.dart';
import '../widgets/siba_widgets.dart';
import 'module_common.dart';
import 'worksite_forms.dart';
import 'project_reports_page.dart';
import 'report_form_page.dart';
import 'crew_attendance_page.dart';
import 'project_expenses_page.dart';

const paymentMethods={'Transferencia':'Transferencia','Efectivo':'Efectivo','Cheque':'Cheque','Otro':'Otro'};
class ProjectPage extends StatefulWidget {
 final SibaProject project;
 final Future<Map<String,dynamic>> Function()? loadOverview;
 const ProjectPage({super.key,required this.project,this.loadOverview});
 @override State<ProjectPage> createState()=>_ProjectPageState();
}
class _ProjectPageState extends State<ProjectPage>{
 Map<String,dynamic> _data={};List<Map<String,dynamic>> _documents=[];List<SupervisionReport> _reports=[];
 bool _loading=true;String? _error;
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{
  setState((){_loading=true;_error=null;});
  try{
   if(widget.loadOverview!=null){final result=await widget.loadOverview!();if(mounted)setState(()=>_data=result);}
   else{final results=await Future.wait<Object>([WorksiteApi.request('/projects/${widget.project.id}/operations'),WorksiteApi.request('/projects/${widget.project.id}/documents'),ApiClient.instance.reports(widget.project.id)]);if(mounted)setState((){_data=results[0] as Map<String,dynamic>;_documents=WorksiteApi.rows((results[1] as Map<String,dynamic>)['files']);_reports=results[2] as List<SupervisionReport>;});}
  }catch(e){if(mounted)setState(()=>_error='$e');}finally{if(mounted)setState(()=>_loading=false);}
 }
 Future<void> _open(Widget page)async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>page));if(mounted)await _load();}
 Future<void> _file(Map<String,dynamic> file)async{try{await WorksiteApi.open(kind:'project-document',recordId:WorksiteApi.number(file['id']).toInt(),projectId:widget.project.id);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}}
 Future<void> _upload()async{
  final hseOnly=_data['canCaptureCosts']!=true&&_data['canManageHse']==true;
  await _open(SibaFormPage(title:'Subir documento',attachments:true,document:true,fields:[SibaField('tipo','Tipo de documento',kind:'select',isRequired:true,choices:hseOnly?const {'Permiso HSE':'Permiso HSE'}:const {'Plano':'Plano','Documento técnico':'Documento técnico','Permiso HSE':'Permiso HSE','Otro':'Otro'})],initial:{'tipo':hseOnly?'Permiso HSE':'Plano'},onSave:(data,files,key)async{if(files.isEmpty)throw const ApiException('Selecciona un archivo.');await WorksiteApi.upload('/projects/${widget.project.id}/documents',data,files,fileField:'archivo',document:true);}));
 }
 @override Widget build(BuildContext context){
  final p=widget.project,summary=WorksiteApi.map(_data['summary']),schedule=WorksiteApi.map(WorksiteApi.map(_data['meta'])['schedule']),accepted=WorksiteApi.map(_data['project'])['accepted']==true;
  final crew=WorksiteApi.rows(_data['personnel']).where((e)=>e['estado']=='activo').toList(),progress=(_reports.isNotEmpty?_reports.first.progress:p.lastProgress)?.clamp(0,100).toDouble();
  return Scaffold(appBar:AppBar(title:Text(p.folio.isEmpty?'Proyecto':p.folio),actions:[IconButton(tooltip:'Actualizar',onPressed:_load,icon:const Icon(Icons.refresh_rounded))]),body:RefreshIndicator(onRefresh:_load,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(20,16,20,32),children:[
   Text(p.title.isEmpty?'Proyecto #${p.id}':p.title,style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:10),Text(p.company,style:Theme.of(context).textTheme.bodyMedium),const SizedBox(height:14),
   Wrap(spacing:8,runSpacing:8,children:[SibaBadge(label:p.status.isEmpty?p.state:p.status),if(_data.isNotEmpty)SibaBadge(label:accepted?'OC confirmada':'Sin OC confirmada',foreground:accepted?SibaColors.success:SibaColors.warning,background:accepted?SibaColors.successSoft:SibaColors.warningSoft)]),const SizedBox(height:22),
   if(_loading)const LinearProgressIndicator(),
   if(_error!=null)SibaEmptyState(icon:Icons.cloud_off_outlined,title:'No se pudo cargar el proyecto',message:_error!,error:true,action:TextButton(onPressed:_load,child:const Text('Reintentar'))),
   if(!_loading&&_error==null)...[
    SibaSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Expanded(child:Text('Avance del proyecto',style:TextStyle(fontWeight:FontWeight.w700))),Text(progress==null?'Sin informe':'${progress.toStringAsFixed(0)}%',style:const TextStyle(color:SibaColors.primary,fontSize:24,fontWeight:FontWeight.w800))]),const SizedBox(height:14),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:(progress??0)/100,minHeight:7,backgroundColor:SibaColors.primarySoft)),if(_reports.isNotEmpty)...[const SizedBox(height:10),Text('Último informe: ${sibaDate(_reports.first.visitDate?.toIso8601String())}',style:Theme.of(context).textTheme.bodySmall)]])),const SizedBox(height:22),
    const SibaSectionTitle(title:'En este proyecto'),const SizedBox(height:12),
    if(_data['canCaptureCosts']==true)_ProjectAction(icon:Icons.receipt_long_outlined,title:'Gastos de obra',subtitle:'Registrar gastos, tickets y facturas',onTap:()=>_open(ProjectExpensesPage(project:p))),
    if(_data['canCaptureCosts']==true)SibaSurface(child:_InfoLine('Límite de gasto',WorksiteApi.number(summary['limit'])>0?sibaMoney(summary['limit']):'Por definir')),
    const SizedBox(height:12),
    _ProjectAction(icon:Icons.description_outlined,title:'Informes',subtitle:'Avances y fotografías',onTap:()=>_open(ProjectReportsPage(project:p))),
    if(_data['canTakeAttendance']==true)_ProjectAction(icon:Icons.fact_check_outlined,title:'Asistencia del personal',subtitle:accepted?'Registrar días y horas extra':'Confirma la OC en la web para capturar',onTap:accepted?()=>_open(CrewAttendancePage(project:p)):null),
    const SizedBox(height:10),
    _ProjectExpansion(title:'Información del proyecto',icon:Icons.info_outline,children:[_InfoLine('Cliente',p.client),_InfoLine('Área',p.area),_InfoLine('Responsable',p.supervisor),_InfoLine('Orden de compra',p.po),_InfoLine('Inicio',sibaDate(schedule['start'])),_InfoLine('Fecha límite',sibaDate(schedule['end']))]),
    _ProjectExpansion(title:'Personal asignado (${crew.length})',icon:Icons.groups_outlined,children:[if(crew.isEmpty)const Text('Sin personal asignado.'),for(final e in crew)ListTile(contentPadding:EdgeInsets.zero,dense:true,title:Text('${e['nombre']}'),subtitle:Text('${e['puesto']??''}'),leading:const Icon(Icons.person_outline,size:22))]),
    _ProjectExpansion(title:'Documentos (${_documents.length})',icon:Icons.folder_open_outlined,children:[if(_documents.isEmpty)const Text('Sin documentos.'),for(final f in _documents)ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.insert_drive_file_outlined),title:Text('${f['nombre']??'Documento'}',maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Text('${f['tipo']??''}'),trailing:const Icon(Icons.open_in_new,size:18),onTap:()=>_file(f)),if(accepted&&(_data['canCaptureCosts']==true||_data['canManageHse']==true))Padding(padding:const EdgeInsets.only(top:8),child:OutlinedButton.icon(onPressed:_upload,icon:const Icon(Icons.upload_file),label:const Text('Subir documento')))]),
    if(_data['canManage']==true)_ProjectExpansion(title:'Resumen de la obra',icon:Icons.account_balance_wallet_outlined,children:[_InfoLine('Meta de gasto',sibaMoney(summary['limit'])),_InfoLine('Gasto registrado',sibaMoney(summary['spent'])),_InfoLine('Disponible',summary['available']==null?'Sin meta':sibaMoney(summary['available']))]),
   ],
  ])),bottomNavigationBar:_loading||_error!=null?null:SafeArea(top:false,minimum:const EdgeInsets.fromLTRB(20,10,20,14),child:FilledButton.icon(onPressed:()=>_open(ReportFormPage(project:p,initialProgress:progress)),icon:const Icon(Icons.add_a_photo_outlined),label:const Text('Nuevo informe con fotos'))));
 }
}
class _ProjectAction extends StatelessWidget{
 final IconData icon;final String title,subtitle;final VoidCallback? onTap;const _ProjectAction({required this.icon,required this.title,required this.subtitle,this.onTap});
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:12),child:SibaSurface(onTap:onTap,child:Row(children:[SibaIconTile(icon:icon),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:4),Text(subtitle,style:Theme.of(context).textTheme.bodySmall)])),if(onTap!=null)const Icon(Icons.chevron_right_rounded)])));
}
class _InfoLine extends StatelessWidget{
 final String label,value;const _InfoLine(this.label,this.value);
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:Theme.of(context).textTheme.bodySmall),const SizedBox(height:3),Text(value.trim().isEmpty?'Sin registrar':value)]));
}
class _ProjectExpansion extends StatelessWidget{
 final String title;final IconData icon;final List<Widget> children;const _ProjectExpansion({required this.title,required this.icon,required this.children});
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:12),child:SibaSurface(padding:EdgeInsets.zero,child:ExpansionTile(shape:const Border(),collapsedShape:const Border(),leading:Icon(icon,color:SibaColors.primary),title:Text(title,style:Theme.of(context).textTheme.titleMedium),childrenPadding:const EdgeInsets.fromLTRB(20,0,20,18),expandedCrossAxisAlignment:CrossAxisAlignment.stretch,children:children)));
}
