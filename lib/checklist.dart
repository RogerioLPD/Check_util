import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChecklistScreen extends StatefulWidget {
  final String checklistTipo;
  final String userId;

  const ChecklistScreen({required this.checklistTipo, required this.userId, Key? key}) : super(key: key);

  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  List<Map<String, dynamic>> checklistItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('checklists')
        .where('tipo', isEqualTo: widget.checklistTipo)
        .where('data_inicio', isLessThanOrEqualTo: today)
        .where('data_fim', isGreaterThanOrEqualTo: today)
        .where('usuario', isEqualTo: widget.userId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        checklistItems = List<Map<String, dynamic>>.from(querySnapshot.docs.first.get('itens'));
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateItemStatus(int index) async {
    setState(() {
      checklistItems[index]['status'] = 'concluído';
    });

    await FirebaseFirestore.instance.collection('checklists').doc(widget.userId).update({
      'itens': checklistItems,
    });
  }

  Future<void> _finalizeChecklist() async {
    await FirebaseFirestore.instance.collection('checklists').doc(widget.userId).update({
      'status': 'concluído',
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.checklistTipo} - Checklist')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : checklistItems.isEmpty
              ? const Center(child: Text('Nenhum checklist disponível.'))
              : ListView.builder(
                  itemCount: checklistItems.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(checklistItems[index]['titulo']),
                      trailing: Checkbox(
                        value: checklistItems[index]['status'] == 'concluído',
                        onChanged: (value) => _updateItemStatus(index),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _finalizeChecklist,
        child: const Icon(Icons.check),
        tooltip: 'Finalizar Checklist',
      ),
    );
  }
}
