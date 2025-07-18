import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AgendamentosProvider extends ChangeNotifier {
  List<Map<String, dynamic>> agendamentos = [];
  List<Map<String, dynamic>> atividadesAtrasadas = [];
  List<Map<String, dynamic>> itensNaoConformes = [];
  Map<String, List<Map<String, dynamic>>> agendamentosComChecklist = {};
  String? unidadeSelecionada;
  DateTime selectedDate = DateTime.now();

  Future<void> fetchAgendamentos() async {
    if (unidadeSelecionada == null || unidadeSelecionada!.isEmpty) return;

    try {
      final startOfDay =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await FirebaseFirestore.instance
          .collection('Agendamentos')
          .where('unidade', isEqualTo: unidadeSelecionada)
          .where('dataAgendada',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dataAgendada', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      agendamentos =
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

      agendamentosComChecklist.clear();
      for (var agendamento in agendamentos) {
        await fetchChecklistItems(agendamento);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao buscar agendamentos: $e');
    }
  }

  Future<void> buscarAtividadesAtrasadas() async {
    if (unidadeSelecionada == null || unidadeSelecionada!.isEmpty) return;

    try {
      DateTime now = DateTime.now();

      final snapshot = await FirebaseFirestore.instance
          .collection('Agendamentos')
          .where('unidade', isEqualTo: unidadeSelecionada)
          .where('dataAgendada',
              isLessThan:
                  Timestamp.fromDate(now)) // Somente atividades passadas
          .get();

      atividadesAtrasadas = snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .where((agendamento) => agendamento['status'] != 'Concluído')
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao buscar atividades atrasadas: $e');
    }
  }

  Future<void> fetchChecklistItems(Map<String, dynamic> agendamento) async {
    try {
      final agendamentoId = agendamento['id'] ?? '';
      if (agendamentoId.isEmpty) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('Agendamentos')
          .doc(agendamentoId)
          .collection('Checklist')
          .get();

      agendamentosComChecklist[agendamentoId] = snapshot.docs.map((doc) {
        return {
          'item': doc['item'],
          'status': doc['status'],
          'createdAt': (doc['createdAt'] as Timestamp).toDate(),
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar checklist para o agendamento: $e');
    }
  }

  Future<void> fetchChecklistItemsPorTag(
      String tag, String agendamentoIdSelecionado) async {
    try {
      final checklistSnapshot = await FirebaseFirestore.instance
          .collection('Agendamentos')
          .doc(agendamentoIdSelecionado)
          .collection('Checklist')
          .where('tag', isEqualTo: tag)
          .get();

      agendamentosComChecklist[agendamentoIdSelecionado] =
          checklistSnapshot.docs.map((checklistDoc) {
        return {
          'item': checklistDoc['item'],
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao buscar checklists por tag e agendamento: $e');
    }
  }

  Future<void> buscarAgendamentosPorTag(String tag) async {
    try {
      final startOfDay =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      print('Buscando agendamentos com a tag: $tag');

      final snapshotDia = await FirebaseFirestore.instance
          .collection('Agendamentos')
          .where('tag', isEqualTo: tag)
          .where('dataAgendada',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dataAgendada', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      DateTime now = DateTime.now();
      final snapshotAtrasadas = await FirebaseFirestore.instance
          .collection('Agendamentos')
          .where('tag', isEqualTo: tag)
          .where('dataAgendada', isLessThan: Timestamp.fromDate(now))
          .where('status', isNotEqualTo: 'Concluído')
          .get();

      final atividadesDia =
          snapshotDia.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      final atividadesAtrasadas = snapshotAtrasadas.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      agendamentos = [...atividadesDia, ...atividadesAtrasadas];

      if (agendamentos.isEmpty) {
        print('Nenhuma atividade encontrada para a tag: $tag');
      }

      print('Agendamentos encontrados: ${agendamentos.length}');

      agendamentosComChecklist.clear();
      for (var agendamento in agendamentos) {
        await fetchChecklistItems(agendamento);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao buscar agendamentos por tag: $e');
    }
  }

  Future<void> removerAgendamento(String agendamentoId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Agendamentos')
          .doc(agendamentoId)
          .delete();

      agendamentos
          .removeWhere((agendamento) => agendamento['id'] == agendamentoId);
      agendamentosComChecklist.remove(agendamentoId);

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao remover agendamento: $e');
    }
  }

  Future<void> listarItensNaoConformes() async {
    itensNaoConformes.clear();

    if (unidadeSelecionada == null || unidadeSelecionada!.isEmpty) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Checklist_finalizados')
          .where('unidade', isEqualTo: unidadeSelecionada)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final itens = List.from(data['itens'] ?? []);

        for (var item in itens) {
          if (item is Map<String, dynamic>) {
            final status = item['status']
                ?.toString()
                .trim()
                .toLowerCase(); // Tratar maiúsculas/minúsculas
            final unidadeItem =
                item['unidade']; // Verificando se existe unidade dentro do item

            // Debug: Verificar se o campo unidade está dentro do item ou fora
            print("Unidade dentro do item: $unidadeItem");

            if (status == 'não conforme') {
              if (unidadeItem == null) {
                // Se unidadeItem for null, vamos tentar pegar a unidade do documento
                print(
                    "Unidade não encontrada no item, buscando no documento...");
                final unidadeDocumento =
                    data['unidade']; // Pega a unidade no nível do documento
                print("Unidade no documento: $unidadeDocumento");

                if (unidadeDocumento == unidadeSelecionada) {
                  itensNaoConformes.add({
                    'agendamentoId': data['agendamentoId'],
                    'item': item['item'],
                    'status': item['status'],
                    'comentario': item['comentario'],
                    'imagem': item['imagem'],
                    'usuario': data['usuario'],
                    'dataFinalizacao': data['dataFinalizacao'],
                    'tag': item['tag'] ?? data['tag'],
                  });
                }
              } else if (unidadeItem == unidadeSelecionada) {
                itensNaoConformes.add({
                  'agendamentoId': data['agendamentoId'],
                  'item': item['item'],
                  'status': item['status'],
                  'comentario': item['comentario'],
                  'imagem': item['imagem'],
                  'usuario': data['usuario'],
                  'dataFinalizacao': data['dataFinalizacao'],
                  'tag': item['tag'] ?? data['tag'],
                });
              }
            }
          }
        }
      }

      print("Itens não conformes encontrados: ${itensNaoConformes.length}");
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao listar itens não conformes: $e');
    }
  }

  Future<void> removerItemNaoConforme({
    required String agendamentoId,
    required String itemNome,
    required String dataFinalizacao,
  }) async {
    try {
      // Buscar o documento correspondente
      final snapshot = await FirebaseFirestore.instance
          .collection('Checklist_finalizados')
          .where('agendamentoId', isEqualTo: agendamentoId)
          .where('dataFinalizacao', isEqualTo: dataFinalizacao)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final itens = List<Map<String, dynamic>>.from(data['itens'] ?? []);

        bool atualizado = false;

        // Atualizar o status do item específico
        for (var item in itens) {
          if (item['item'] == itemNome &&
              item['status'].toString().toLowerCase() == 'não conforme') {
            item['status'] = 'Conforme';
            atualizado = true;
            break;
          }
        }

        if (atualizado) {
          // Atualizar o documento no Firestore
          await FirebaseFirestore.instance
              .collection('Checklist_finalizados')
              .doc(doc.id)
              .update({'itens': itens});

          // Atualizar lista local e notificar
          await listarItensNaoConformes(); // Recarrega os itens não conformes
          notifyListeners();
          debugPrint('Item "$itemNome" atualizado para Conforme.');
        } else {
          debugPrint(
              'Item "$itemNome" não foi encontrado ou já está Conforme.');
        }
      }
    } catch (e) {
      debugPrint('Erro ao remover item não conforme: $e');
    }
  }

  void setSelectedDate(DateTime date) {
    if (!isSameDay(selectedDate, date)) {
      selectedDate = date;
      fetchAgendamentos();
      notifyListeners();
    }
  }

  void setUnidadeSelecionada(String unidade) {
    if (unidadeSelecionada != unidade) {
      unidadeSelecionada = unidade;
      fetchAgendamentos();
      buscarAtividadesAtrasadas();
      notifyListeners();
      listarItensNaoConformes();
    }
  }

  Future<void> carregarAgendamentos() async {
    await fetchAgendamentos();
    await buscarAtividadesAtrasadas();
  }
}
