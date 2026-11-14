import 'dart:async';
import 'package:flutter/material.dart';

import '../models/mobile_models.dart';
import '../services/api_client.dart';
import '../theme/siba_theme.dart';
import '../widgets/siba_widgets.dart';
import 'project_page.dart';

class ProjectsPage extends StatefulWidget {
  final bool embedded;
  const ProjectsPage({super.key, this.embedded = false});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _search = TextEditingController();
  Timer? _searchDelay;
  int _generation=0;
  bool _loading = true;
  String? _error;
  List<SibaProject> _projects = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDelay?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation=++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final projects = await ApiClient.instance.projects(search: _search.text);
      if(mounted&&generation==_generation)setState(()=>_projects=projects);
    } catch (error) {
      if(mounted&&generation==_generation)setState(()=>_error=error.toString());
    } finally {
      if (mounted&&generation==_generation) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          const SibaAnimatedEntry(
            child: SibaSectionTitle(
              title: 'Proyectos',
            ),
          ),
          const SizedBox(height: 16),
          SibaAnimatedEntry(
            delayMs: 60,
            child: TextField(
              controller: _search,
              onChanged: (_){_searchDelay?.cancel();_searchDelay=Timer(const Duration(milliseconds:350),_load);},
              onSubmitted: (_) {_searchDelay?.cancel();_load();},
              decoration: InputDecoration(
                hintText: 'Buscar folio, empresa, proyecto u OC',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchDelay?.cancel();
                          _search.clear();
                          _load();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (!_loading && _error == null)
            SibaAnimatedEntry(
              delayMs: 90,
              child: Row(
                children: [
                  Text(
                    '${_projects.length} proyecto${_projects.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Actualizar'),
                  ),
                ],
              ),
            ),
          if (_loading) ...[
            const SibaSkeleton(height: 170),
            const SizedBox(height: 10),
            const SibaSkeleton(height: 170),
            const SizedBox(height: 10),
            const SibaSkeleton(height: 170),
          ] else if (_error != null)
            SibaEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'No se pudieron cargar los proyectos',
              message: _error!,
              error: true,
              action: OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            )
          else if (_projects.isEmpty)
            const SibaEmptyState(
              icon: Icons.dashboard_outlined,
              title: 'No hay proyectos disponibles',
              message: 'Tu usuario no tiene proyectos visibles con los filtros actuales.',
            )
          else
            ...List.generate(
              _projects.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: SibaAnimatedEntry(
                  delayMs: 30 * (index > 5 ? 5 : index),
                  child: _ProjectCard(project: _projects[index]),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.embedded) return content;
    return Scaffold(appBar: AppBar(title: const Text('Proyectos')), body: content);
  }
}

class _ProjectCard extends StatelessWidget {
 final SibaProject project;const _ProjectCard({required this.project});
 @override Widget build(BuildContext context)=>SibaProjectTile(project:project,onTap:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>ProjectPage(project:project))));
}
