import 'package:checkutil/Services/date_utils.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class AgendamentoScreen extends StatefulWidget {
  @override
  _AgendamentoScreenState createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  String? unidadeSelecionada;
  String? selectedEquipment;
  String? selectedEquipmentType;
  List<Map<String, String>> equipmentList = [];
  DateTime selectedDate = DateTime.now();
  String selectedChecklistType = 'Diário';
  final List<String> checklistTypes = [
    'Diário',
    'Semanal',
    'Mensal',
    'Trimestral',
    'Anual'
  ];

  List<Map<String, dynamic>> checklistItems = [];

  Map<String, String> checklistMapping = {
    'Diário': 'Diario',
    'Semanal': 'Semanal',
    'Mensal': 'Mensal',
    'Trimestral': 'Trimestral',
    'Anual': 'Anual',
  };

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    unidadeSelecionada =
        Provider.of<UnidadeProvider>(context, listen: false).unidadeSelecionada;
    _fetchEquipmentList();
    _loadChecklistItems();
  }

  Future<void> _fetchEquipmentList() async {
    if (unidadeSelecionada == null || unidadeSelecionada!.isEmpty) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Equipamentos')
          .where('unidade', isEqualTo: unidadeSelecionada)
          .get();

      setState(() {
        equipmentList = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'tipoEquipamento':
                data['tipoEquipamento']?.toString() ?? 'Desconhecido',
            'tag': data['tag']?.toString() ?? 'Sem tag',
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar equipamentos: $e')));
    }
  }

  Future<void> _loadChecklistItems() async {
    setState(() {
      isLoading = true;
    });

    if (unidadeSelecionada == null || unidadeSelecionada!.isEmpty) {
      print("Erro: unidadeSelecionada está nula ou vazia.");
      return;
    }

    String collectionName = checklistMapping[selectedChecklistType] ?? 'Diario';
    print(
        'Buscando checklist na coleção: Checklist/$unidadeSelecionada/$collectionName');

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Checklist')
          .doc(unidadeSelecionada) // Seleciona a unidade
          .collection(collectionName) // Acessa a subcoleção do checklist
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        print('Nenhum checklist encontrado para $collectionName');
      }

      setState(() {
        checklistItems = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'item': data['item'] ?? 'Desconhecido',
            'status': data['status'] ?? 'pendente',
            'createdAt': data.containsKey('createdAt')
                ? convertToBrazilTime(data['createdAt'])
                : nowInBrazil(),
            'unidade': data['unidade'] ?? '',
            'equipamento': data['equipamento'] ?? '',
            'tag': data['tag'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar itens do checklist: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _scheduleChecklist() async {
    if (selectedEquipment == null || selectedEquipmentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um equipamento!')));
      return;
    }

    if (checklistItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum item de checklist carregado!')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<DateTime> datesToSchedule = [];
      DateTime currentDate = selectedDate;

      switch (selectedChecklistType) {
        case 'Diário':
          for (int i = 0; i < 365; i++) {
            datesToSchedule.add(currentDate.add(Duration(days: i)));
          }
          break;
        case 'Semanal':
          for (int i = 0; i < 52; i++) {
            datesToSchedule.add(currentDate.add(Duration(days: i * 7)));
          }
          break;
        case 'Mensal':
          for (int i = 0; i < 12; i++) {
            datesToSchedule.add(DateTime(
                currentDate.year, currentDate.month + i, currentDate.day));
          }
          break;
        case 'Trimestral':
          for (int i = 0; i < 4; i++) {
            datesToSchedule.add(DateTime(currentDate.year,
                currentDate.month + (i * 3), currentDate.day));
          }
          break;
        case 'Anual':
          datesToSchedule.add(DateTime(
              currentDate.year + 1, currentDate.month, currentDate.day));
          break;
      }

      for (var date in datesToSchedule) {
        DateTime dateInBrazil = date.subtract(const Duration(hours: 3));

        var existingAgendamento = await FirebaseFirestore.instance
            .collection('Agendamentos')
            .where('equipamento', isEqualTo: selectedEquipment)
            .where('dataAgendada', isEqualTo: Timestamp.fromDate(dateInBrazil))
            .get();

        if (existingAgendamento.docs.isNotEmpty) {
          print(
              'Agendamento já existe para ${selectedEquipment} em $dateInBrazil. Pulando...');
          continue;
        }

        DocumentReference agendamentoRef =
            await FirebaseFirestore.instance.collection('Agendamentos').add({
          'unidade': unidadeSelecionada,
          'equipamento': selectedEquipment,
          'tipoEquipamento': selectedEquipmentType,
          'tag': selectedEquipment,
          'dataAgendada': Timestamp.fromDate(dateInBrazil),
          'status': 'pendente',
          'checklistNome': selectedChecklistType,
        });

        for (var item in checklistItems) {
          await agendamentoRef.collection('Checklist').add({
            'item': item['item'],
            'status': 'pendente',
            'createdAt': DateTime.now(),
            'unidade': unidadeSelecionada,
            'equipamento': selectedEquipment,
            'tag': selectedEquipment,
            'checklistNome': selectedChecklistType,
            'agendamentoId': agendamentoRef.id,
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento realizado com sucesso!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao agendar: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar Atividade',),
       backgroundColor: Colors.teal,
        elevation: 4,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedEquipment,
              hint: const Text('Selecione um equipamento'),
              isExpanded: true,
              onChanged: (value) {
                setState(() {
                  selectedEquipment = value;
                  selectedEquipmentType = equipmentList.firstWhere(
                      (equipment) =>
                          equipment['tag'] == value)?['tipoEquipamento'];
                });
              },
              items: equipmentList.map((equipment) {
                return DropdownMenuItem(
                  value: equipment['tag'],
                  child: Text(
                      '${equipment['tipoEquipamento']} - ${equipment['tag']}'),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedChecklistType,
              isExpanded: true,
              onChanged: (value) {
                setState(() {
                  selectedChecklistType = value!;
                });
                _loadChecklistItems(); // Carrega os itens do checklist atualizado
              },
              items: checklistTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: selectedDate,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  selectedDate = selectedDay;
                });
              },
              locale: 'pt_BR',
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator() // Exibir o loading
                : ElevatedButton(
                    onPressed: _scheduleChecklist,
                    child: const Text('Agendar Atividade'),
                  ),
          ],
        ),
      ),
    );
  }
}
