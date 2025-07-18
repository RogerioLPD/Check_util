import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  final String userId;
  const CalendarScreen({required this.userId, Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadChecklists();
  }

  Future<void> _loadChecklists() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('checklists')
        .where('usuario', isEqualTo: widget.userId)
        .get();

    Map<DateTime, List<Map<String, dynamic>>> events = {};
    for (var doc in querySnapshot.docs) {
      DateTime date = DateTime.parse(doc.get('data_inicio'));
      events[date] = events[date] ?? [];
      events[date]!.add(doc.data() as Map<String, dynamic>);
    }

    setState(() => _events = events);
  }

  Future<void> _createChecklist() async {
    TextEditingController checklistController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Novo Checklist'),
        content: TextField(
          controller: checklistController,
          decoration: const InputDecoration(hintText: 'Tipo de Checklist'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (checklistController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('checklists').add({
                  'tipo': checklistController.text,
                  'data_inicio': _selectedDay.toIso8601String(),
                  'data_fim': _selectedDay.toIso8601String(),
                  'status': 'pendente',
                  'usuario': widget.userId,
                  'itens': [],
                });
                _loadChecklists();
                Navigator.pop(context);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendário de Checklists')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() => _selectedDay = selectedDay);
            },
            eventLoader: (day) => _events[day] ?? [],
          ),
          Expanded(
            child: ListView(
              children: _events[_selectedDay]?.map((event) {
                    return ListTile(
                      title: Text(event['tipo']),
                      subtitle: Text(event['status']),
                      trailing: Icon(Icons.check, color: event['status'] == 'concluído' ? Colors.green : Colors.grey),
                    );
                  }).toList() ??
                  [const Center(child: Text('Nenhum checklist para este dia.'))],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createChecklist,
        child: const Icon(Icons.add),
        tooltip: 'Criar Novo Checklist',
      ),
    );
  }
}
