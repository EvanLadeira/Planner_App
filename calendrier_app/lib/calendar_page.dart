import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'api.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<dynamic> _allEvents = [];
  List<dynamic> _categories = [];
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  static const double _hourHeight = 60.0;
  static const double _timeWidth = 48.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final events = await getEvents();
    final categories = await getEventCategories();
    setState(() {
      _allEvents = events;
      _categories = categories;
    });
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final offset = (now.hour - 1) * _hourHeight;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(offset.clamp(0, _scrollController.position.maxScrollExtent));
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _allEvents.where((e) {
      final start = DateTime.parse(e['start']);
      return start.year == day.year &&
          start.month == day.month &&
          start.day == day.day;
    }).toList();
  }

  Future<void> _showAddEventDialog({DateTime? date}) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedColor = '#6C63FF';
    int? selectedCategoryId;
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
    final selectedDate = date ?? _selectedDay;

    final colors = [
      '#6C63FF', '#ec4899', '#f97316', '#22c55e',
      '#3b82f6', '#eab308', '#ef4444', '#14b8a6',
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvel événement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: 'Titre'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(hintText: 'Description (optionnel)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: startTime);
                          if (t != null) setDialogState(() => startTime = t);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(startTime.format(context), style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('→', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: endTime);
                          if (t != null) setDialogState(() => endTime = t);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(endTime.format(context), style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_categories.isNotEmpty) ...[
                  const Text('Catégorie', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      GestureDetector(
                        onTap: () => setDialogState(() => selectedCategoryId = null),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: selectedCategoryId == null ? Colors.grey.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: const Text('Aucune', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      ..._categories.map((cat) {
                        final color = _hexToColor(cat['color'] as String);
                        final isSelected = selectedCategoryId == cat['id'];
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedCategoryId = cat['id'] as int),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? color : Colors.grey.withOpacity(0.3)),
                            ),
                            child: Text(
                              cat['name'],
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? color : Colors.grey,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                const Text('Couleur', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: colors.map((color) => GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: _hexToColor(color),
                        shape: BoxShape.circle,
                        border: selectedColor == color ? Border.all(color: Colors.white, width: 2) : null,
                        boxShadow: selectedColor == color
                            ? [BoxShadow(color: _hexToColor(color).withOpacity(0.5), blurRadius: 6)]
                            : null,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                final start = DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day,
                  startTime.hour, startTime.minute,
                );
                final end = DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day,
                  endTime.hour, endTime.minute,
                );
                await createEventFull(
                  titleController.text,
                  descController.text,
                  start.toIso8601String(),
                  end.toIso8601String(),
                  selectedColor,
                  categoryId: selectedCategoryId,
                );
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

  void _openEventDetail(dynamic event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailPage(
          event: event,
          onDelete: () async {
            await deleteEvent(event['id']);
            _loadData();
          },
        ),
      ),
    );
  }

  // ── Vue grille (semaine/jour) ─────────────────────────────

  Widget _buildGrid(List<DateTime> days) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    final timeColor = Colors.grey.withOpacity(0.5);

    return SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        height: 24 * _hourHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colonne heures
            SizedBox(
              width: _timeWidth,
              child: Stack(
                children: List.generate(24, (hour) => Positioned(
                  top: hour * _hourHeight - 8,
                  left: 0,
                  right: 0,
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(fontSize: 10, color: timeColor),
                    textAlign: TextAlign.center,
                  ),
                )),
              ),
            ),
            // Colonnes jours
            Expanded(
              child: Stack(
                children: [
                  // Lignes horizontales
                  ...List.generate(24, (hour) => Positioned(
                    top: hour * _hourHeight,
                    left: 0,
                    right: 0,
                    child: Divider(height: 1, color: dividerColor),
                  )),
                  // Lignes verticales + événements
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: days.map((day) {
                      final dayEvents = _getEventsForDay(day);
                      final isToday = isSameDay(day, DateTime.now());
                      return Expanded(
                        child: Stack(
                          children: [
                            // Ligne verticale
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: dividerColor, width: 0.5),
                                  ),
                                  color: isToday ? const Color(0xFF6C63FF).withOpacity(0.03) : null,
                                ),
                              ),
                            ),
                            // Événements
                            SizedBox(
                              height: 24 * _hourHeight,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Grouper les événements qui se chevauchent
                                  final groups = _groupOverlappingEvents(dayEvents);
                                  return Stack(
                                    children: groups.expand((group) {
                                      final count = group.length;
                                      return group.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final event = entry.value;
                                        final start = DateTime.parse(event['start']);
                                        final end = DateTime.parse(event['end']);
                                        final top = (start.hour + start.minute / 60) * _hourHeight;
                                        final duration = end.difference(start).inMinutes / 60;
                                        final height = (duration * _hourHeight).clamp(20.0, double.infinity);
                                        final color = _hexToColor(event['color'] as String? ?? '#6C63FF');
                                        final width = constraints.maxWidth / count;

                                        return Positioned(
                                          top: top,
                                          left: index * width + 1,
                                          width: width - 2,
                                          child: GestureDetector(
                                            onTap: () => _openEventDetail(event),
                                            child: Container(
                                              height: height,
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.85),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border(left: BorderSide(color: color, width: 3)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    event['title'],
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (height > 35)
                                                    Text(
                                                      '${start.hour}h${start.minute.toString().padLeft(2, '0')}',
                                                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8)),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList();
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                            // Ligne "maintenant"
                            if (isToday)
                              Positioned(
                                top: (DateTime.now().hour + DateTime.now().minute / 60) * _hourHeight,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2,
                                  color: Colors.red.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
    List<List<dynamic>> _groupOverlappingEvents(List<dynamic> events) {
    if (events.isEmpty) return [];
    
    final sorted = [...events]..sort((a, b) {
      return DateTime.parse(a['start']).compareTo(DateTime.parse(b['start']));
    });

    List<List<dynamic>> groups = [];
    List<dynamic> currentGroup = [sorted[0]];

    for (int i = 1; i < sorted.length; i++) {
      final eventStart = DateTime.parse(sorted[i]['start']);
      bool overlaps = currentGroup.any((e) {
        final eEnd = DateTime.parse(e['end']);
        return eventStart.isBefore(eEnd);
      });

      if (overlaps) {
        currentGroup.add(sorted[i]);
      } else {
        groups.add([...currentGroup]);
        currentGroup = [sorted[i]];
      }
    }
    groups.add(currentGroup);
    return groups;
  }
  Widget _buildWeekView() {
    final startOfWeek = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Column(
      children: [
        // Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () => setState(() => _focusedDay = _focusedDay.subtract(const Duration(days: 7))),
              ),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(width: _timeWidth + 32), // espace pour les chevrons
                    ...days.map((day) {
                      final isToday = isSameDay(day, DateTime.now());
                      final isSelected = isSameDay(day, _selectedDay);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDay = day),
                          child: Column(
                            children: [
                              Text(
                                ['L', 'M', 'M', 'J', 'V', 'S', 'D'][day.weekday - 1],
                                style: TextStyle(fontSize: 10, color: Colors.grey.withOpacity(0.6)),
                              ),
                              const SizedBox(height: 2),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? const Color(0xFF6C63FF)
                                      : isSelected
                                          ? const Color(0xFF6C63FF).withOpacity(0.15)
                                          : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.normal,
                                      color: isToday ? Colors.white : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () => setState(() => _focusedDay = _focusedDay.add(const Duration(days: 7))),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildGrid(days)),
      ],
    );
  }

  Widget _buildDayView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () => setState(() => _selectedDay = _selectedDay.subtract(const Duration(days: 1))),
              ),
              Text(
                _formatDateFull(_selectedDay),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () => setState(() => _selectedDay = _selectedDay.add(const Duration(days: 1))),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildGrid([_selectedDay])),
      ],
    );
  }

  Widget _buildMonthView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(2030),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF6C63FF),
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: Color(0xFF6C63FF),
              shape: BoxShape.circle,
            ),
            weekendTextStyle: TextStyle(color: Colors.red.withOpacity(0.7)),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _buildEventList(_getEventsForDay(_selectedDay)),
        ),
      ],
    );
  }

  Widget _buildEventList(List<dynamic> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available, size: 40, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text('Aucun événement', style: TextStyle(fontSize: 13, color: Colors.grey.withOpacity(0.5))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final color = _hexToColor(event['color'] as String? ?? '#6C63FF');
        final start = DateTime.parse(event['start']);
        final end = DateTime.parse(event['end']);
        final duration = end.difference(start);
        final durationText = duration.inHours > 0
            ? '${duration.inHours}h${duration.inMinutes % 60 > 0 ? '${duration.inMinutes % 60}min' : ''}'
            : '${duration.inMinutes}min';

        return GestureDetector(
          onTap: () => _openEventDetail(event),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      if (event['description'] != null && event['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          event['description'],
                          style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.7)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 11, color: Colors.grey.withOpacity(0.6)),
                          const SizedBox(width: 3),
                          Text(
                            '${start.hour}h${start.minute.toString().padLeft(2, '0')} — ${end.hour}h${end.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.withOpacity(0.6)),
                          ),
                          const SizedBox(width: 8),
                          Text(durationText, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
                        ],
                      ),
                    ],
                  ),
                ),
                if (event['category_name'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event['category_name'],
                      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateFull(DateTime date) {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Mois'),
              Tab(text: 'Semaine'),
              Tab(text: 'Jour'),
            ],
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            indicatorColor: const Color(0xFF6C63FF),
            labelColor: const Color(0xFF6C63FF),
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMonthView(),
                _buildWeekView(),
                _buildDayView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        elevation: 0,
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Page détail ───────────────────────────────────────────────
class EventDetailPage extends StatelessWidget {
  final dynamic event;
  final VoidCallback onDelete;

  const EventDetailPage({super.key, required this.event, required this.onDelete});

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(event['color'] as String? ?? '#6C63FF');
    final start = DateTime.parse(event['start']);
    final end = DateTime.parse(event['end']);
    final duration = end.difference(start);
    final durationText = duration.inHours > 0
        ? '${duration.inHours}h${duration.inMinutes % 60 > 0 ? '${duration.inMinutes % 60}min' : ''}'
        : '${duration.inMinutes}min';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7)),
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  if (event['category_name'] != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event['category_name'],
                        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.access_time,
              color: color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${start.hour}h${start.minute.toString().padLeft(2, '0')} — ${end.hour}h${end.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(durationText, style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.7))),
                ],
              ),
            ),
            if (event['description'] != null && event['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.notes,
                color: color,
                child: Text(event['description'], style: const TextStyle(fontSize: 14)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Widget child;

  const _DetailRow({required this.icon, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Padding(padding: const EdgeInsets.only(top: 6), child: child)),
      ],
    );
  }
}