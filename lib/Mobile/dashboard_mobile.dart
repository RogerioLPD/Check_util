import 'package:checkutil/Services/agendamentos_provider.dart';
import 'package:checkutil/Services/date_utils.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


  class DashboardMobileScreen extends StatefulWidget {
  @override
  _DashboardMobileScreenState createState() => _DashboardMobileScreenState();
}

class _DashboardMobileScreenState extends State<DashboardMobileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final agendamentoProvider =
          Provider.of<AgendamentosProvider>(context, listen: false);
      agendamentoProvider.setSelectedDate(DateTime.now());
      agendamentoProvider.fetchAgendamentos();
      agendamentoProvider.buscarAtividadesAtrasadas();

      final unidade = Provider.of<UnidadeProvider>(context, listen: false)
          .unidadeSelecionada;

      if (unidade != null) {
        agendamentoProvider.listarItensNaoConformes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unidadeSelecionada =
        Provider.of<UnidadeProvider>(context).unidadeSelecionada;
    final agendamentoProvider = Provider.of<AgendamentosProvider>(context);
    final itensNaoConformes = agendamentoProvider.itensNaoConformes;
    final DateTime now = DateTime.now();
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (unidadeSelecionada != null &&
          unidadeSelecionada != agendamentoProvider.unidadeSelecionada) {
        agendamentoProvider.setUnidadeSelecionada(unidadeSelecionada);
      }
    });

    final agendamentosHoje =
        agendamentoProvider.agendamentos.where((agendamento) {
      if (agendamento['dataAgendada'] is Timestamp) {
        final DateTime dataAgendada =
            (agendamento['dataAgendada'] as Timestamp).toDate().toLocal();
        return now.year == dataAgendada.year &&
            now.month == dataAgendada.month &&
            now.day == dataAgendada.day;
      }
      return false;
    }).toList();
   return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard Inspeções ',
          style: TextStyle(fontSize: 20.sp, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: EdgeInsets.all(6.w),
        child: ListView(
          children: [
            // Atividades do Dia
            Text(
              'Atividades do Dia - ${DateFormat('dd/MM/yyyy').format(now)}',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            if (agendamentosHoje.isEmpty)
              Center(
                child: Text(
                  'Nenhuma atividade para hoje',
                  style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                ),
              )
            else
              ...agendamentosHoje.map((agendamento) {
                final checklistItems = agendamentoProvider.agendamentosComChecklist[agendamento['id']] ?? [];
                final dataAgendada = (agendamento['dataAgendada'] as Timestamp).toDate().toLocal();
                final diferenca = dataAgendada.difference(DateTime.now());
                final pertoDoPrazo = diferenca.inHours <= 1 && diferenca.inMinutes > 0;

                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Itens do Checklist', style: TextStyle(fontSize: 18.sp)),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: checklistItems.map((item) => Text(
                              '• ${item['item']} - ${item['status']}',
                              style: TextStyle(fontSize: 13.sp),
                            )).toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Fechar', style: TextStyle(fontSize: 14.sp)),
                          )
                        ],
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9.r),
                      gradient: LinearGradient(
                        colors: [
                          getPrazoColor(dataAgendada).withOpacity(0.95),
                          getPrazoColor(dataAgendada).withOpacity(0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10.r,
                          offset: Offset(4.w, 4.h),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(6.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pertoDoPrazo)
                          Row(
                            children: [
                              Icon(Icons.access_time_filled, color: Colors.deepOrange, size: 16.sp),
                              SizedBox(width: 1.w),
                              Text('Vence em 1 hora!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                    fontSize: 16.sp,
                                  )),
                            ],
                          ),
                        SizedBox(height: 1.h),
                        Text('Equipamento',
                            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700)),
                        Text('${agendamento['tipoEquipamento']} - ${agendamento['equipamento']}',
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
                        SizedBox(height: 1.h),
                        Text('Inspeção: ${agendamento['checklistNome']}',
                            style: TextStyle(fontSize: 12.sp)),
                        Text('Status: ${agendamento['status']}',
                            style: TextStyle(fontSize: 12.sp)),
                      ],
                    ),
                  ),
                );
              }),

            // Itens Não Conformes
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.report_problem, color: Colors.orange, size: 18.sp),
                SizedBox(width: 1.w),
                Text('Itens Não Conformes',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 14.h),
            if (itensNaoConformes.isEmpty)
              Center(
                child: Text('Nenhum item encontrado.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
              )
            else
              ...itensNaoConformes.map((item) => Card(
                    color: Colors.red,
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9.r)),
                    margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                    child: ListTile(
                      title: Text(item['item'],
                          style: TextStyle(fontSize: 16.sp, color: Colors.white)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${item['status']}',
                              style: TextStyle(fontSize: 12.sp, color: Colors.white70)),
                          if ((item['comentario'] ?? '').isNotEmpty)
                            Text('Comentário: ${item['comentario']}',
                                style: TextStyle(fontSize: 12.sp, color: Colors.white70)),
                        ],
                      ),
                    ),
                  )),

            // Atividades Atrasadas
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 18.sp),
                SizedBox(width: 1.w),
                Text('Atividades Atrasadas',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 2.h),
            if (agendamentoProvider.atividadesAtrasadas.isEmpty)
              Center(
                child: Text('Nenhuma atividade atrasada',
                    style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
              )
            else
              ...agendamentoProvider.atividadesAtrasadas.map((agendamento) {
                final dataAgendada = (agendamento['dataAgendada'] as Timestamp).toDate().toLocal();
                return Card(
                  color: Colors.red.shade300,
                  margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  child: ListTile(
                    leading: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22.sp),
                    title: Text('${agendamento['tipoEquipamento']} - ${agendamento['equipamento']}',
                        style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tipo de Inspeção: ${agendamento['checklistNome']}',
                            style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                        Text('Data Agendada: ${DateFormat('dd/MM/yyyy HH:mm').format(dataAgendada)}',
                            style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }


 Color getPrazoColor(DateTime dataAgendada) {
    DateTime now = DateTime.now();
    return now.isBefore(dataAgendada)
        ? Colors.yellow.shade200
        : Colors.red.shade200;
  }

}
//
