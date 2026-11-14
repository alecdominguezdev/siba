import 'package:flutter/material.dart';

import '../models/mobile_models.dart';
import '../services/api_client.dart';
import '../theme/siba_theme.dart';
import '../widgets/siba_widgets.dart';
import 'report_form_page.dart';
import 'report_detail_page.dart';

class ProjectReportsPage extends StatefulWidget {
  final SibaProject project;
  const ProjectReportsPage({super.key, required this.project});

  @override
  State<ProjectReportsPage> createState() => _ProjectReportsPageState();
}

class _ProjectReportsPageState extends State<ProjectReportsPage> {
  bool _loading = true;
  String? _error;
  List<SupervisionReport> _reports = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _reports = await ApiClient.instance.reports(widget.project.id);
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _newReport() async {
    final previousProgress = _reports.isNotEmpty
        ? (_reports.first.progress ?? widget.project.lastProgress ?? 0)
        : (widget.project.lastProgress ?? 0);
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ReportFormPage(
        project: widget.project,
        initialProgress: previousProgress,
      )),
    );
    if (created == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final project=widget.project;
    final progress=_reports.isNotEmpty?_reports.first.progress:project.lastProgress;
    return Scaffold(appBar:AppBar(title:const Text('Informes del proyecto'),actions:[IconButton(tooltip:'Actualizar',onPressed:_load,icon:const Icon(Icons.refresh_rounded))]),body:RefreshIndicator(onRefresh:_load,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(20,12,20,24),children:[
      Text(project.folio,style:const TextStyle(color:SibaColors.primary,fontWeight:FontWeight.w700)),const SizedBox(height:8),Text(project.title,maxLines:3,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:16),
      Wrap(spacing:8,runSpacing:8,children:[SibaBadge(label:'${_reports.length} informes',icon:Icons.description_outlined),SibaBadge(label:progress==null?'Sin avance registrado':'Avance ${progress.toStringAsFixed(0)}%',icon:Icons.trending_up)]),const SizedBox(height:22),
      if(_loading)const SibaSkeleton(height:126)
      else if(_error!=null)SibaEmptyState(icon:Icons.cloud_off_outlined,title:'No se pudieron cargar los informes',message:_error!,error:true,action:TextButton(onPressed:_load,child:const Text('Reintentar')))
      else if(_reports.isEmpty)const SibaEmptyState(icon:Icons.add_a_photo_outlined,title:'Aún no hay informes',message:'Registra el avance y agrega fotografías de esta obra.')
      else for(final report in _reports)Padding(padding:const EdgeInsets.only(bottom:12),child:_ReportCard(report:report,label:'Informe #${report.id}',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ReportDetailPage(report:report,label:'Informe #${report.id}'))))),
    ])),bottomNavigationBar:SafeArea(top:false,minimum:const EdgeInsets.fromLTRB(20,10,20,14),child:FilledButton.icon(onPressed:_loading?null:_newReport,icon:const Icon(Icons.add_a_photo_outlined),label:const Text('Nuevo informe con fotos'))));
  }
}

class _ReportCard extends StatelessWidget {
  final SupervisionReport report;
  final String label;
  final VoidCallback onTap;
  const _ReportCard({
    required this.report,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = report.visitDate?.toLocal();
    final dateText = date == null
        ? 'Sin fecha'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final incomplete = report.incompleteInformation;
    final color = incomplete ? SibaColors.warning : SibaColors.success;

    return SibaSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SibaIconTile(
                icon: incomplete ? Icons.warning_amber_rounded : Icons.task_alt_rounded,
                color: color,
                background: color.withOpacity(.10),
                size: 41,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(dateText, style: Theme.of(context).textTheme.bodySmall),
                    if (report.supervisor.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(report.supervisor, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              SibaBadge(
                label: '${report.progress?.toStringAsFixed(0) ?? '-'}%',
                foreground: color,
                background: color.withOpacity(.10),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Text(
                  report.status.replaceAll('_', ' '),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.photo_camera_outlined, size: 17, color: SibaColors.muted),
              const SizedBox(width: 5),
              Text('${report.photosCount}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 7),
              const Icon(Icons.chevron_right_rounded, color: SibaColors.muted),
            ],
          ),
          if (incomplete && report.missingInformation.isNotEmpty) ...[
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SibaColors.warningSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                report.missingInformation,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: SibaColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
