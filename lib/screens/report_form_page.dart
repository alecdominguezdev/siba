import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/mobile_models.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/siba_theme.dart';
import '../widgets/siba_widgets.dart';

class ReportFormPage extends StatefulWidget {
  final SibaProject project;
  final double? initialProgress;
  const ReportFormPage({super.key, required this.project, this.initialProgress});

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final _picker = ImagePicker();
  final _workDone = TextEditingController();
  final _pending = TextEditingController();
  final _incidents = TextEditingController();
  final _observations = TextEditingController();
  final _missingInformation = TextEditingController();
  final _progressInput = TextEditingController();

  double _progress = 0;
  bool _incomplete = false;
  bool _saving = false;
  int? _draftReportId;
  final Set<String> _uploadedPaths = {};
  final List<XFile> _photos = [];

  @override
  void initState() {
    super.initState();
    // Cada informe parte del último avance confirmado del proyecto; nunca vuelve a 0% por defecto.
    _progress = (widget.initialProgress ?? widget.project.lastProgress ?? 0).clamp(0, 100).toDouble();
    _progressInput.text = _progress.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _workDone.dispose();
    _pending.dispose();
    _incidents.dispose();
    _observations.dispose();
    _missingInformation.dispose();
    _progressInput.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_saving) return;
    try {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 78,
      maxWidth: 1920,
    );
    if (photo != null && mounted) {
      if(_photos.length>=10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Máximo 10 fotografías por informe.')));return;}
      setState(() {
        _photos.add(photo);
      });
    }
    } catch (_) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('No se pudo abrir la cámara. Revisa sus permisos.'))); }
  }

  Future<void> _pickPhotos() async {
    if (_saving) return;
    try {
    final photos = await _picker.pickMultiImage(imageQuality: 78, maxWidth: 1920);
    if (photos.isNotEmpty && mounted) {
      final unique=photos.where((p)=>!_photos.any((old)=>old.path==p.path)).toList();
      if(_photos.length+unique.length>10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Selecciona hasta 10 fotografías por informe.')));return;}
      setState(() {
        _photos.addAll(unique);
      });
    }
    } catch (_) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('No se pudo abrir la galería. Intenta de nuevo.'))); }
  }

  Future<void> _submit() async {
    if (_saving) return;
    final enteredProgress = double.tryParse(_progressInput.text.trim().replaceAll(',', '.'));
    if (enteredProgress == null || enteredProgress < 0 || enteredProgress > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un porcentaje de avance entre 0 y 100.')),
      );
      return;
    }
    _progress = enteredProgress;
    setState(() => _saving = true);
    try {
      for(final photo in _photos){if(await photo.length()>12*1024*1024)throw const ApiException('Cada fotografía debe pesar menos de 12 MB.');}
      // Los informes aceptan ubicación opcional; el checado de asistencia sigue requiriéndola.
      double? latitude,longitude,accuracy;
      try { final position=await LocationService.currentPosition();latitude=position.latitude;longitude=position.longitude;accuracy=position.accuracy; } catch (_) {}
      var reportId = _draftReportId;
      if (reportId == null) {
        reportId = await ApiClient.instance.createReport(
          projectId: widget.project.id,
          progress: _progress,
          workDone: _workDone.text,
          pending: _pending.text,
          incidents: _incidents.text,
          observations: _observations.text,
          incompleteInformation: _incomplete,
          missingInformation: _missingInformation.text,
          latitude: latitude,
          longitude: longitude,
          accuracyMeters: accuracy,
        );
        if (reportId > 0) _draftReportId = reportId;
      } else {
        await ApiClient.instance.updateReport(
          reportId: reportId,
          progress: _progress,
          workDone: _workDone.text,
          pending: _pending.text,
          incidents: _incidents.text,
          observations: _observations.text,
          incompleteInformation: _incomplete,
          missingInformation: _missingInformation.text,
          latitude: latitude,
          longitude: longitude,
          accuracyMeters: accuracy,
        );
      }
      if (reportId <= 0) throw Exception('No se pudo crear el informe.');

      final pendingPhotos=_photos.where((p)=>!_uploadedPaths.contains(p.path)).toList();
      if (pendingPhotos.isNotEmpty) {
        await ApiClient.instance.uploadPhotos(
          projectId: widget.project.id,
          reportId: reportId,
          filePaths: pendingPhotos.map((e) => e.path).toList(),
        );
        _uploadedPaths.addAll(pendingPhotos.map((p)=>p.path));
      }
      await ApiClient.instance.submitReport(reportId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe guardado en SIBA.')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el informe. Intenta nuevamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop:!_saving,child:Scaffold(appBar:AppBar(title:const Text('Nuevo informe')),body:AbsorbPointer(absorbing:_saving,child:ListView(padding:const EdgeInsets.fromLTRB(20,8,20,28),children:[
      _ProjectHeader(folio:widget.project.folio.isEmpty?'Proyecto #${widget.project.id}':widget.project.folio,title:widget.project.title),const SizedBox(height:14),
      SibaSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('Avance de la obra',style:TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:8),Text('Anterior: ${(widget.initialProgress??widget.project.lastProgress??0).toStringAsFixed(0)}%',style:const TextStyle(color:SibaColors.muted,fontSize:12)),const SizedBox(height:12),TextFormField(controller:_progressInput,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Avance actual',suffixText:'%',hintText:'0 a 100'))])),const SizedBox(height:20),
      _Field(controller:_workDone,label:'Trabajo realizado',hint:'¿Qué se realizó en la obra?',minLines:3),const SizedBox(height:24),
      Row(children:[const Expanded(child:Text('Fotografías',style:TextStyle(fontSize:16,fontWeight:FontWeight.w700))),Text('${_photos.length}/10',style:const TextStyle(color:SibaColors.muted))]),const SizedBox(height:12),
      Wrap(spacing:10,runSpacing:10,children:[FilledButton.icon(onPressed:_saving?null:_takePhoto,icon:const Icon(Icons.photo_camera_outlined,size:18),label:const Text('Tomar foto')),OutlinedButton.icon(onPressed:_saving?null:_pickPhotos,icon:const Icon(Icons.photo_library_outlined,size:18),label:const Text('Galería'))]),
      if(_photos.isNotEmpty)...[const SizedBox(height:14),GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:_photos.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:8,mainAxisSpacing:8),itemBuilder:(context,index)=>Stack(fit:StackFit.expand,children:[ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.file(File(_photos[index].path),fit:BoxFit.cover)),Positioned(right:3,top:3,child:IconButton(tooltip:_uploadedPaths.contains(_photos[index].path)?'Fotografía guardada':'Quitar fotografía',style:IconButton.styleFrom(backgroundColor:Colors.black54,foregroundColor:Colors.white),onPressed:_saving||_uploadedPaths.contains(_photos[index].path)?null:()=>setState(()=>_photos.removeAt(index)),icon:Icon(_uploadedPaths.contains(_photos[index].path)?Icons.check:Icons.close,size:17)))]))],const SizedBox(height:24),
      SibaSurface(padding:EdgeInsets.zero,child:ExpansionTile(shape:const Border(),collapsedShape:const Border(),title:const Text('Más detalles (opcional)'),leading:const Icon(Icons.notes_outlined),expandedCrossAxisAlignment:CrossAxisAlignment.stretch,childrenPadding:const EdgeInsets.fromLTRB(16,0,16,18),children:[
        _Field(controller:_pending,label:'Pendientes',hint:'Trabajos por realizar',minLines:2),const SizedBox(height:14),_Field(controller:_incidents,label:'Incidencias',hint:'¿Hubo algún percance?',minLines:2),const SizedBox(height:14),_Field(controller:_observations,label:'Observaciones',hint:'Información adicional',minLines:2),const SizedBox(height:10),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Falta información'),value:_incomplete,onChanged:(v)=>setState(()=>_incomplete=v)),if(_incomplete)_Field(controller:_missingInformation,label:'Información faltante',hint:'¿Qué hace falta?',minLines:2),
      ])),
    ])),bottomNavigationBar:SafeArea(top:false,minimum:const EdgeInsets.fromLTRB(20,10,20,14),child:FilledButton.icon(onPressed:_saving?null:_submit,icon:_saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.save_outlined),label:Text(_saving?'Guardando…':'Guardar informe')))));
  }
}

class _ProjectHeader extends StatelessWidget {
  final String folio;
  final String title;

  const _ProjectHeader({required this.folio, required this.title});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SibaIconTile(
              icon: Icons.assignment_outlined,
              size: 40,
              color: Colors.white,
              background: SibaColors.ink,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(folio, style: Theme.of(context).textTheme.titleMedium),
                  if (title.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.minLines = 3,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        minLines: minLines,
        maxLines: 6,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: true,
        ),
      );
}
