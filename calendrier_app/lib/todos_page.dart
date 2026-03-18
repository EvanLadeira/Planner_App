import 'package:flutter/material.dart';
import 'api.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  List<dynamic> _todos = [];
  List<dynamic> _themes = [];
  Set<int> _selectedThemeFilters = {};
  Set<int> _collapsedThemes = {};
  bool _flatView = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final todos = await getTodos();
    final themes = await getThemes();
    setState(() {
      _todos = todos;
      _themes = themes;
    });
  }

  List<dynamic> _getChildren(int? parentId) {
    return _themes.where((t) => t['parent_id'] == parentId).toList();
  }

  List<dynamic> _getSubTodos(int parentId) {
    return _todos.where((t) => t['parent_id'] == parentId).toList();
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  List<dynamic> _getFilteredTodos(int themeId) {
    return _todos.where((t) => t['theme_id'] == themeId).toList();
  }

  List<int> _getAllThemeIds(int themeId) {
    List<int> ids = [themeId];
    final children = _getChildren(themeId);
    for (final child in children) {
      ids.addAll(_getAllThemeIds(child['id']));
    }
    return ids;
  }

  bool _themeOrParentMatchesFilter(int themeId) {
    if (_selectedThemeFilters.isEmpty) return true;
    int? currentId = themeId;
    while (currentId != null) {
      if (_selectedThemeFilters.contains(currentId)) return true;
      final theme = _themes.firstWhere(
        (t) => t['id'] == currentId,
        orElse: () => null,
      );
      currentId = theme?['parent_id'];
    }
    return false;
  }

  Future<void> _showAddThemeDialog({int? parentId, String? parentName}) async {
    final nameController = TextEditingController();
    String selectedColor = '#6366f1';

    final colors = [
      '#6366f1', '#ec4899', '#f97316', '#22c55e',
      '#3b82f6', '#eab308', '#ef4444', '#14b8a6',
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            parentId == null ? 'Nouveau thème' : 'Sous-thème de "$parentName"',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Nom du thème'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('Couleur', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: colors.map((color) => GestureDetector(
                  onTap: () => setDialogState(() => selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _hexToColor(color),
                      shape: BoxShape.circle,
                      border: selectedColor == color
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: selectedColor == color
                          ? [BoxShadow(color: _hexToColor(color).withOpacity(0.5), blurRadius: 6)]
                          : null,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await createTheme(nameController.text, selectedColor, parentId: parentId);
                if (context.mounted) Navigator.pop(context);
                _loadData();
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTodoDialog(int themeId) async {
    final titleController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle tâche', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'Titre de la tâche'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              await createTodo(titleController.text, themeId: themeId);
              if (context.mounted) Navigator.pop(context);
              _loadData();
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(dynamic theme, int depth) {
    final themeId = theme['id'] as int;
    final color = _hexToColor(theme['color'] as String);
    final children = _getChildren(themeId);
    final todos = _getFilteredTodos(themeId);
    final isCollapsed = _collapsedThemes.contains(themeId);

    if (!_themeOrParentMatchesFilter(themeId) && _selectedThemeFilters.isNotEmpty) {
      final allIds = _getAllThemeIds(themeId);
      final hasFilteredChild = allIds.any((id) => _selectedThemeFilters.contains(id));
      if (!hasFilteredChild) return const SizedBox.shrink();
    }

    final allIds = _getAllThemeIds(themeId);
    final allTodos = _todos.where((t) => allIds.contains(t['theme_id'])).toList();
    final doneTodos = allTodos.where((t) => t['done'] == 1).toList();
    final progress = allTodos.isEmpty ? 0.0 : doneTodos.length / allTodos.length;

    return Padding(
      padding: EdgeInsets.only(left: depth * 12.0, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          InkWell(
            onTap: () {
              setState(() {
                if (isCollapsed) {
                  _collapsedThemes.remove(themeId);
                } else {
                  _collapsedThemes.add(themeId);
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isCollapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: color, size: 18),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    theme['name'],
                    style: TextStyle(
                      fontSize: depth == 0 ? 15 : 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (allTodos.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${doneTodos.length}/${allTodos.length}',
                      style: TextStyle(fontSize: 11, color: color.withOpacity(0.6)),
                    ),
                  ],
                  const Spacer(),
                  // Actions discrètes
                  _IconAction(
                    icon: Icons.account_tree_outlined,
                    onTap: () => _showAddThemeDialog(parentId: themeId, parentName: theme['name']),
                  ),
                  _IconAction(
                    icon: Icons.add,
                    onTap: () => _showAddTodoDialog(themeId),
                  ),
                  _IconAction(
                    icon: Icons.delete_outline,
                    onTap: () async {
                      await deleteTheme(themeId);
                      _loadData();
                    },
                    color: Colors.red.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          // Barre de progression
          if (allTodos.isNotEmpty && !isCollapsed)
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 8, bottom: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.5)),
                  minHeight: 3,
                ),
              ),
            ),
          // Contenu
          if (!isCollapsed) ...[
            ...todos.where((t) => t['parent_id'] == null).map((todo) => _buildTodoItem(todo, depth)),
            ...children.map((child) => _buildThemeSection(child, depth + 1)),
          ],
          if (depth == 0)
            Divider(height: 16, thickness: 0.5, color: Colors.grey.withOpacity(0.2)),
        ],
      ),
    );
  }

  Widget _buildTodoItem(dynamic todo, int depth) {
    final subTodos = _getSubTodos(todo['id'] as int);
    final isCollapsed = _collapsedThemes.contains(-(todo['id'] as int));
    final isDone = todo['done'] == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 28.0 + depth * 12),
          child: Row(
            children: [
              if (subTodos.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      final id = -(todo['id'] as int);
                      if (isCollapsed) {
                        _collapsedThemes.remove(id);
                      } else {
                        _collapsedThemes.add(id);
                      }
                    });
                  },
                  child: AnimatedRotation(
                    turns: isCollapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: Colors.grey.withOpacity(0.5), size: 16),
                  ),
                )
              else
                const SizedBox(width: 16),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: isDone ? null : () async {
                  await completeTodo(todo['id']);
                  _loadData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? Colors.green : Colors.grey.withOpacity(0.4),
                      width: 1.5,
                    ),
                    color: isDone ? Colors.green : Colors.transparent,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  todo['title'],
                  style: TextStyle(
                    fontSize: 14,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey.withOpacity(0.5) : null,
                  ),
                ),
              ),
              _IconAction(
                icon: Icons.add,
                size: 14,
                onTap: () async {
                  final controller = TextEditingController();
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Nouvelle sous-tâche', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(hintText: 'Titre'),
                        autofocus: true,
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                        FilledButton(
                          onPressed: () async {
                            if (controller.text.isEmpty) return;
                            await createSubTodo(controller.text, todo['id']);
                            if (context.mounted) Navigator.pop(context);
                            _loadData();
                          },
                          child: const Text('Créer'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _IconAction(
                icon: Icons.delete_outline,
                size: 14,
                color: Colors.red.withOpacity(0.5),
                onTap: () async {
                  await deleteTodo(todo['id']);
                  _loadData();
                },
              ),
            ],
          ),
        ),
        if (!isCollapsed)
          ...subTodos.map((sub) => _buildTodoItem(sub, depth + 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rootThemes = _getChildren(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Barre d'ajout
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _AddTodoBar(
              themes: _themes,
              onAdd: (title, themeId) async {
                await createTodo(title, themeId: themeId);
                _loadData();
              },
            ),
          ),
          // Contrôles
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                // Filtres
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Sans thème',
                          selected: _selectedThemeFilters.contains(-1),
                          onTap: () {
                            setState(() {
                              if (_selectedThemeFilters.contains(-1)) {
                                _selectedThemeFilters.remove(-1);
                              } else {
                                _selectedThemeFilters.add(-1);
                              }
                            });
                          },
                        ),
                        ..._themes.where((t) => t['parent_id'] == null).map((t) {
                          final id = t['id'] as int;
                          final color = _hexToColor(t['color'] as String);
                          return _FilterChip(
                            label: t['name'],
                            selected: _selectedThemeFilters.contains(id),
                            color: color,
                            onTap: () {
                              setState(() {
                                if (_selectedThemeFilters.contains(id)) {
                                  _selectedThemeFilters.remove(id);
                                } else {
                                  _selectedThemeFilters.add(id);
                                }
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                // Toggle vue
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Thèmes',
                      style: TextStyle(
                        fontSize: 12,
                        color: !_flatView ? Theme.of(context).colorScheme.secondary : Colors.grey,
                        fontWeight: !_flatView ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: _flatView,
                      onChanged: (val) => setState(() => _flatView = val),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Liste',
                      style: TextStyle(
                        fontSize: 12,
                        color: _flatView ? Theme.of(context).colorScheme.secondary : Colors.grey,
                        fontWeight: _flatView ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste
          Expanded(
            child: _flatView
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    children: _todos
                        .where((t) => t['parent_id'] == null || t['parent_id'] == 'null')
                        .map((todo) => _buildTodoItem(todo, 0))
                        .toList(),
                  )
                : rootThemes.isEmpty && _todos.where((t) => t['theme_id'] == null).isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text('Aucune tâche', style: TextStyle(color: Colors.grey.withOpacity(0.5))),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        children: [
                          ..._todos
                              .where((t) =>
                                  (t['theme_id'] == null || t['theme_id'] == 'null') &&
                                  t['parent_id'] == null &&
                                  (_selectedThemeFilters.isEmpty || _selectedThemeFilters.contains(-1)))
                              .map((todo) => _buildTodoItem(todo, 0)),
                          ...rootThemes.map((t) => _buildThemeSection(t, 0)),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddThemeDialog(),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thème', style: TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }
}

// ── Widgets utilitaires ───────────────────────────────────────

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final double size;

  const _IconAction({
    required this.icon,
    required this.onTap,
    this.color,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: size,
          color: color ?? Colors.grey.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? c : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _AddTodoBar extends StatefulWidget {
  final List<dynamic> themes;
  final Function(String title, int? themeId) onAdd;

  const _AddTodoBar({required this.themes, required this.onAdd});

  @override
  State<_AddTodoBar> createState() => _AddTodoBarState();
}

class _AddTodoBarState extends State<_AddTodoBar> {
  final TextEditingController _controller = TextEditingController();
  int? _selectedThemeId;

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  String _getSelectedThemeName() {
    if (_selectedThemeId == null) return 'Thème';
    final theme = widget.themes.firstWhere(
      (t) => t['id'] == _selectedThemeId,
      orElse: () => null,
    );
    return theme != null ? theme['name'] : 'Thème';
  }

  Future<void> _showThemePicker(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir un thème', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                dense: true,
                leading: const CircleAvatar(backgroundColor: Colors.grey, radius: 8),
                title: const Text('Sans thème', style: TextStyle(fontSize: 14)),
                selected: _selectedThemeId == null,
                onTap: () {
                  setState(() => _selectedThemeId = null);
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1),
              ..._buildThemeListItems(widget.themes, null, 0, context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildThemeListItems(List<dynamic> themes, int? parentId, int depth, BuildContext context) {
    List<Widget> items = [];
    final children = themes.where((t) => t['parent_id'] == parentId).toList();
    for (final theme in children) {
      final color = _hexToColor(theme['color'] as String);
      items.add(ListTile(
        dense: true,
        contentPadding: EdgeInsets.only(left: 16.0 + depth * 16, right: 16),
        leading: CircleAvatar(backgroundColor: color, radius: 8),
        title: Text(
          theme['name'],
          style: TextStyle(
            fontSize: 14,
            fontWeight: depth == 0 ? FontWeight.w600 : FontWeight.normal,
            color: color,
          ),
        ),
        selected: _selectedThemeId == theme['id'],
        onTap: () {
          setState(() => _selectedThemeId = theme['id'] as int);
          Navigator.pop(context);
        },
      ));
      items.addAll(_buildThemeListItems(themes, theme['id'], depth + 1, context));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final selectedTheme = _selectedThemeId == null
        ? null
        : widget.themes.firstWhere((t) => t['id'] == _selectedThemeId, orElse: () => null);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Nouvelle tâche...'),
            onSubmitted: (_) {
              if (_controller.text.isEmpty) return;
              widget.onAdd(_controller.text, _selectedThemeId);
              _controller.clear();
            },
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showThemePicker(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: selectedTheme != null
                  ? _hexToColor(selectedTheme['color'] as String).withOpacity(0.1)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedTheme != null)
                  CircleAvatar(
                    backgroundColor: _hexToColor(selectedTheme['color'] as String),
                    radius: 5,
                  )
                else
                  Icon(Icons.label_outline, size: 14, color: Colors.grey.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                  _getSelectedThemeName(),
                  style: TextStyle(
                    fontSize: 12,
                    color: selectedTheme != null
                        ? _hexToColor(selectedTheme['color'] as String)
                        : Colors.grey,
                  ),
                ),
                Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey.withOpacity(0.6)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            if (_controller.text.isEmpty) return;
            widget.onAdd(_controller.text, _selectedThemeId);
            _controller.clear();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}