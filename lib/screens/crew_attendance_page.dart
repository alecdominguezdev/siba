import 'package:flutter/material.dart';
import '../models/mobile_models.dart';
import '../services/worksite_api.dart';
import '../theme/siba_theme.dart';
import '../widgets/siba_widgets.dart';

class CrewAttendancePage extends StatefulWidget {
  final SibaProject project;
  const CrewAttendancePage({super.key, required this.project});
  @override
  State<CrewAttendancePage> createState() => _CrewAttendancePageState();
}

class _CrewAttendancePageState extends State<CrewAttendancePage> {
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _rows = [];
  final Map<int, Map<String, dynamic>> _drafts = {};
  final Map<int, TextEditingController> _hours = {};
  final _search = TextEditingController();
  bool _loading = true, _saving = false;
  String? _error;

  String _day(DateTime date) => WorksiteApi.day(date.toIso8601String());
  DateTime get _monday => DateTime(_date.year, _date.month, _date.day).subtract(Duration(days: _date.weekday - 1));
  String get _base => '/projects/${widget.project.id}/crew-attendance';

  @override
  void initState() {
    super.initState();
    if (_date.weekday == DateTime.sunday) _date = _date.subtract(const Duration(days: 1));
    _load();
  }
  @override
  void dispose() {
    _search.dispose();
    for (final c in _hours.values) { c.dispose(); }
    super.dispose();
  }
  Map<String, dynamic> _current(Map<String, dynamic> row) {
    final id = WorksiteApi.number(row['empleadoId']).toInt();
    return _drafts[id] ?? WorksiteApi.rows(row['dias']).firstWhere((d) => d['fecha'] == _day(_date), orElse: () => {});
  }
  Future<void> _load({bool discard = false}) async {
    if (_saving) return;
    if (_drafts.isNotEmpty && !discard) {
      setState(() => _error = 'Guarda los cambios o usa Descartar y actualizar.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = await WorksiteApi.request(_base, query: {'inicio': _day(_monday)});
      if (!mounted) return;
      for (final c in _hours.values) { c.dispose(); }
      _hours.clear(); _drafts.clear();
      setState(() => _rows = WorksiteApi.rows(data['rows']));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  Future<void> _selectDate() async {
    if (_saving || _loading || _drafts.isNotEmpty) {
      setState(() => _error = 'Guarda o descarta los cambios antes de cambiar de día.');
      return;
    }
    final result = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100), selectableDayPredicate: (day) => day.weekday != DateTime.sunday);
    if (result == null || !mounted) return;
    setState(() => _date = result);
    await _load();
  }
  void _edit(Map<String, dynamic> row, {String? status, String? hours}) {
    final id = WorksiteApi.number(row['empleadoId']).toInt();
    final current = Map<String, dynamic>.from(_current(row));
    if (status != null) {
      current['estado'] = status;
      if (status != 'asistio') { current['horas_extra'] = 0; _hours[id]?.text = '0'; }
    }
    if (hours != null) current['horas_extra'] = hours;
    setState(() { _drafts[id] = current; _error = null; });
  }
  Future<void> _save() async {
    if (_saving || _loading || _drafts.isEmpty) return;
    final entries = _drafts.entries.toList();
    for (final entry in entries) {
      final value = double.tryParse('${entry.value['horas_extra'] ?? 0}');
      if (value == null || value < 0 || value > 24 || (value * 100 - (value * 100).round()).abs() > .00001) {
        setState(() => _error = 'Revisa las horas extra: de 0 a 24 y hasta dos decimales.');
        return;
      }
    }
    setState(() { _saving = true; _error = null; });
    var saved = 0;
    try {
      for (final entry in entries) {
        final body = entry.value;
        final result = await WorksiteApi.request('$_base/${entry.key}/day', method: 'PUT', data: {
          'fecha': _day(_date), 'estado': body['estado'],
          'horas_extra': WorksiteApi.number(body['horas_extra']), 'revision': body['revision'] ?? 0,
        });
        if (!mounted) return;
        final row = _rows.firstWhere((r) => WorksiteApi.number(r['empleadoId']).toInt() == entry.key);
        final days = WorksiteApi.rows(row['dias']);
        final index = days.indexWhere((d) => d['fecha'] == _day(_date));
        if (index >= 0) days[index] = {...body, 'horas_extra': WorksiteApi.number(body['horas_extra']), 'revision': result['revision']};
        row['dias'] = days; _drafts.remove(entry.key); saved++;
        setState(() {});
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$saved asistencias guardadas.')));
    } catch (e) {
      if (mounted) setState(() => _error = '$saved guardadas. $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final rows = _rows.where((r) => _current(r)['estado']!='no_aplica'&&'${r['nombre']} ${r['puesto']}'.toLowerCase().contains(_search.text.toLowerCase())).toList();
    return PopScope(canPop: !_saving, child: Scaffold(
      appBar: AppBar(title: const Text('Tomar asistencia')),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: FilledButton.icon(
        onPressed: _saving || _loading || _drafts.isEmpty ? null : _save,
        icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Guardando…' : 'Guardar asistencia (${_drafts.length})'),
      ))),
      body: RefreshIndicator(onRefresh: _load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(18), children: [
        Text(widget.project.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _saving || _loading ? null : _selectDate, icon: const Icon(Icons.calendar_today_outlined), label: Text(_day(_date))),
        const SizedBox(height: 12),
        TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Buscar trabajador', prefixIcon: Icon(Icons.search))),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_error!, style: const TextStyle(color: SibaColors.danger))),
        if (_drafts.isNotEmpty) TextButton(onPressed: _saving ? null : () => _load(discard: true), child: const Text('Descartar y actualizar')),
        if (_error != null && _drafts.isEmpty) TextButton(onPressed: _saving ? null : _load, child: const Text('Reintentar')),
        const SizedBox(height: 14),
        if (!_loading && rows.isEmpty) const SibaEmptyState(icon: Icons.groups_outlined, title: 'Sin trabajadores', message: 'Asigna empleados a este proyecto desde Nómina.'),
        for (final row in rows) _worker(row),
      ])),
    ));
  }
  Widget _worker(Map<String, dynamic> row) {
    final id = WorksiteApi.number(row['empleadoId']).toInt(), current = _current(row);
    final state = '${current['estado'] ?? 'pendiente'}';
    final fromApp=current['asistenciaAppId']!=null;
    final locked = row['enviada'] == true || state == 'no_aplica';
    final hours = _hours.putIfAbsent(id, () => TextEditingController(text: '${current['horas_extra'] ?? 0}'));
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: SibaSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${row['nombre']}', style: Theme.of(context).textTheme.titleMedium),
      Text('${row['puesto']}', style: const TextStyle(color: SibaColors.muted)),
      if(fromApp)const Padding(padding:EdgeInsets.only(top:6),child:Text('Entrada confirmada en Mi asistencia',style:TextStyle(color:SibaColors.success,fontSize:12))),
      const SizedBox(height: 10),
      if (locked) Text(row['enviada'] == true ? 'Semana enviada a pagos' : 'Fuera de asignación', style: const TextStyle(color: SibaColors.muted))
      else Wrap(spacing: 8, children: [
        ChoiceChip(label: const Text('Asistió'), selected: state == 'asistio', onSelected: _saving || _loading ? null : (_) => _edit(row, status: 'asistio')),
        ChoiceChip(label: const Text('Falta'), selected: state == 'falta', onSelected: _saving || _loading || fromApp ? null : (_) => _edit(row, status: 'falta')),
      ]),
      if (state == 'pendiente') const Text('Sin capturar', style: TextStyle(color: SibaColors.muted)),
      if (state == 'asistio') ...[
        const SizedBox(height: 10), TextField(controller: hours, enabled: !locked && !_saving && !_loading, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Horas extra'), onChanged: (value) => _edit(row, hours: value)),
      ],
    ])));
  }
}
