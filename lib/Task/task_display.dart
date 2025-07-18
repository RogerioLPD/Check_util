import 'package:checkutil/Services/agendamentos_provider.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarioAgendamentosScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final agendamentosProvider = Provider.of<AgendamentosProvider>(context);
    final unidadeSelecionada =
        Provider.of<UnidadeProvider>(context).unidadeSelecionada;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (unidadeSelecionada != null &&
          unidadeSelecionada != agendamentosProvider.unidadeSelecionada) {
        agendamentosProvider.setUnidadeSelecionada(unidadeSelecionada!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividades Agendadas'),
        backgroundColor: Colors.teal,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => _mostrarCalendario(context, agendamentosProvider),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Listagem de agendamentos
            Expanded(
              child: agendamentosProvider.agendamentos.isEmpty
                  ? const Center(
                      child: Text('Nenhuma atividade agendada para este dia.'))
                  : ListView.builder(
                      itemCount: agendamentosProvider.agendamentos.length,
                      itemBuilder: (context, index) {
                        final agendamento =
                            agendamentosProvider.agendamentos[index];
                        final checklistItems = agendamentosProvider
                                .agendamentosComChecklist[agendamento['id']] ??
                            [];
                        final dataAgendada =
                            (agendamento['dataAgendada'] as Timestamp).toDate();

                        return Card(
                          elevation: 8,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          color: _getCardColor(
                              agendamento['checklistNome'], dataAgendada),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            title: Text(
                              '${agendamento['tipoEquipamento']} - ${agendamento['equipamento']}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tipo de Inspeção: ${agendamento['checklistNome']}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black54),
                                ),
                                Text(
                                  'Status: ${agendamento['status']}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black54),
                                ),
                                if (checklistItems.isNotEmpty)
                                  ...checklistItems.map((item) {
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'Item: ${item['item']} - Status: ${item['status']}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarCalendario(BuildContext context, AgendamentosProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o modal ocupe mais espaço
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Garante que o conteúdo role se necessário
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecionar Data',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(height: 10),
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: provider.selectedDate,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) =>
                    isSameDay(provider.selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  provider.setSelectedDate(selectedDay);
                  Navigator.pop(context);
                },
                locale: 'pt_BR',
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  leftChevronIcon:
                      const Icon(Icons.chevron_left, color: Colors.teal),
                  rightChevronIcon:
                      const Icon(Icons.chevron_right, color: Colors.teal),
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.teal.shade300,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  selectedTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  outsideDaysVisible: false,
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87),
                  weekendStyle: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red.shade400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardColor(String checklistNome, DateTime dataAgendada) {
    DateTime now = DateTime.now();
    DateTime start =
        DateTime(dataAgendada.year, dataAgendada.month, dataAgendada.day, 7);
    DateTime end;

    switch (checklistNome) {
      case 'Diário':
        end = DateTime(
            dataAgendada.year, dataAgendada.month, dataAgendada.day, 18);
        break;
      case 'Semanal':
        end = start.add(const Duration(days: 6, hours: 11));
        break;
      case 'Mensal':
        end = DateTime(dataAgendada.year, dataAgendada.month + 1, 0, 18);
        break;
      case 'Trimestral':
        end = DateTime(dataAgendada.year, dataAgendada.month + 3, 0, 18);
        break;
      case 'Anual':
        end = DateTime(dataAgendada.year, 12, 31, 18);
        break;
      default:
        end = start;
    }

    return now.isBefore(end) ? Colors.yellow.shade200 : Colors.red.shade200;
  }
}
