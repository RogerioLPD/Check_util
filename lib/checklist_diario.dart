import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DailyInspectionScreen extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const DailyInspectionScreen({required this.userId, required this.selectedDate, Key? key}) : super(key: key);

  @override
  _DailyInspectionScreenState createState() => _DailyInspectionScreenState();
}

class _DailyInspectionScreenState extends State<DailyInspectionScreen> {
  final List<Map<String, dynamic>> _inspectionItems = [
    {'title': 'Verificação do nível de óleo lubrificante', 'status': 'pendente'},
    {'title': 'Inspeção visual de vazamentos de óleo, combustível e líquido de arrefecimento', 'status': 'pendente'},
    {'title': 'Conferência do painel de controle quanto a alertas e mensagens de erro', 'status': 'pendente'},
    {'title': 'Avaliação da tensão e frequência da bateria de partida', 'status': 'pendente'},
  ];

  Future<void> _saveChecklist() async {
    await FirebaseFirestore.instance.collection('checklists').add({
      'tipo': 'Inspeção Diária',
      'data': widget.selectedDate.toIso8601String(),
      'usuario': widget.userId,
      'status': 'pendente',
      'itens': _inspectionItems,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist de Inspeção Diária')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _inspectionItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_inspectionItems[index]['title']),
                  trailing: DropdownButton<String>(
                    value: _inspectionItems[index]['status'],
                    onChanged: (newStatus) {
                      setState(() {
                        _inspectionItems[index]['status'] = newStatus!;
                      });
                    },
                    items: ['pendente', 'concluído', 'não conforme']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _saveChecklist,
              child: const Text('Salvar Checklist'),
            ),
          ),
        ],
      ),
    );
  }
}
