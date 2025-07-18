import 'package:checkutil/Services/agendamentos_provider.dart';
import 'package:checkutil/Services/date_utils.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
            'Dashboard',
            style: TextStyle(fontSize: 12.sp),
          ),
          backgroundColor: Colors.teal,
        ),
        body: Padding(
          padding: EdgeInsets.all(6.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        'Atividades do Dia - ${dateFormatter.format(now)}',
                        style: TextStyle(
                          fontSize: 7.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      agendamentosHoje.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhuma atividade para hoje',
                                style: TextStyle(
                                    fontSize: 5.sp, color: Colors.black54),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final larguraDisponivel = constraints.maxWidth;
                                final crossAxisCount =
                                    larguraDisponivel < 1000 ? 1 : 2;

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: agendamentosHoje.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        MediaQuery.of(context).size.width < 1000
                                            ? 1
                                            : 2,
                                    childAspectRatio: 1.2,
                                    mainAxisSpacing: 4.h,
                                    crossAxisSpacing: 4.w,
                                  ),
                                  itemBuilder: (context, index) {
                                    final agendamento = agendamentosHoje[index];
                                    final checklistItems = agendamentoProvider
                                                .agendamentosComChecklist[
                                            agendamento['id']] ??
                                        [];
                                    final DateTime dataAgendada =
                                        (agendamento['dataAgendada']
                                                as Timestamp)
                                            .toDate()
                                            .toLocal();
                                    final Duration diferenca =
                                        dataAgendada.difference(DateTime.now());
                                    final bool pertoDoPrazo =
                                        diferenca.inHours <= 1 &&
                                            diferenca.inMinutes > 0;

                                    return GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                'Itens do Checklist',
                                                style:
                                                    TextStyle(fontSize: 18.sp),
                                              ),
                                              content: SingleChildScrollView(
                                                child: ListBody(
                                                  children: checklistItems
                                                      .map((item) {
                                                    return Text(
                                                      '• ${item['item']} - ${item['status']}',
                                                      style: TextStyle(
                                                          fontSize: 13.sp),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: Text(
                                                    'Fechar',
                                                    style: TextStyle(
                                                        fontSize: 14.sp),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20.r),
                                          gradient: LinearGradient(
                                            colors: [
                                              getPrazoColor(dataAgendada)
                                                  .withOpacity(0.95),
                                              getPrazoColor(dataAgendada)
                                                  .withOpacity(0.75),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 10.r,
                                              offset: Offset(4.w, 4.h),
                                            ),
                                          ],
                                        ),
                                        padding: EdgeInsets.all(3.w),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (pertoDoPrazo)
                                              Row(
                                                children: [
                                                  Icon(Icons.access_time_filled,
                                                      color: Colors.deepOrange,
                                                      size: 5.sp),
                                                  SizedBox(width: 1.w),
                                                  Expanded(
                                                    child: Text(
                                                      'Vence em 1 hora!',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.deepOrange,
                                                        fontSize: 5.sp,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            SizedBox(height: 1.h),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Equipamento',
                                                    style: TextStyle(
                                                      fontSize: 3.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${agendamento['tipoEquipamento']} - ${agendamento['equipamento']}',
                                                    style: TextStyle(
                                                      fontSize: 6.sp,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.black,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 1.h),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .assignment_turned_in,
                                                        size: 5.sp,
                                                        color: Colors.black),
                                                    SizedBox(width: 1.w),
                                                    Text(
                                                      'Inspeção:',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 5.sp,
                                                      ),
                                                    ),
                                                    SizedBox(width: 1.w),
                                                    Text(
                                                      agendamento[
                                                          'checklistNome'],
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 5.sp,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 1.h),
                                                Row(
                                                  children: [
                                                    Icon(Icons.verified_user,
                                                        size: 5.sp,
                                                        color: Colors.black),
                                                    SizedBox(width: 1.w),
                                                    Text(
                                                      'Status:',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 5.sp,
                                                      ),
                                                    ),
                                                    SizedBox(width: 1.w),
                                                    Text(
                                                      agendamento['status'],
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 5.sp,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.report_problem,
                              color: Colors.orange, size: 7.sp),
                          SizedBox(width: 1.w),
                          Text(
                            'Itens Não Conformes',
                            style: TextStyle(
                              fontSize: 7.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      itensNaoConformes.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhum item encontrado.',
                                style: TextStyle(
                                    fontSize: 5.sp, color: Colors.black54),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: itensNaoConformes.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width > 800
                                        ? 1
                                        : 1,
                                childAspectRatio: 1.2,
                                mainAxisSpacing: 12.h,
                                crossAxisSpacing: 12.w,
                              ),
                              itemBuilder: (context, index) {
                                final item = itensNaoConformes[index];
                                final String agendamentoId =
                                    item['agendamentoId'] ?? '';
                                final String itemNome = item['item'] ?? '';
                                final String itemTag = item['tag'] ?? '';
                                final String dataFinalizacao =
                                    (item['dataFinalizacao'] is Timestamp)
                                        ? (item['dataFinalizacao'] as Timestamp)
                                            .toDate()
                                            .toIso8601String()
                                        : item['dataFinalizacao'].toString();

                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(item['item'],
                                              style:
                                                  TextStyle(fontSize: 18.sp)),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Status: ${item['status']}',
                                                  style: TextStyle(
                                                      fontSize: 14.sp)),
                                              if ((item['comentario'] ?? '')
                                                  .isNotEmpty)
                                                Text(
                                                    'Comentário: ${item['comentario']}',
                                                    style: TextStyle(
                                                        fontSize: 14.sp)),
                                              if ((item['imagem'] ?? '')
                                                  .isNotEmpty)
                                                Column(
                                                  children: [
                                                    SizedBox(height: 8.h),
                                                    Image.network(
                                                      item['imagem'],
                                                      height: 150.h,
                                                      width: 150.w,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: Text('Fechar',
                                                  style: TextStyle(
                                                      fontSize: 14.sp)),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Card(
                                    color: Colors.red,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(3.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 12.h),
                                          Row(
                                            children: [
                                              Icon(Icons.warning,
                                                  size: 8.sp,
                                                  color: Colors.white),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: Text(
                                                  item['item'],
                                                  style: TextStyle(
                                                    fontSize: 6.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            'Equipamento',
                                            style: TextStyle(
                                              fontSize: 3.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Text(
                                            '$itemTag  ',
                                            style: TextStyle(
                                              fontSize: 5.sp,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 1.h),
                                          Row(
                                            children: [
                                              Icon(Icons.verified,
                                                  size: 5.sp,
                                                  color: Colors.black),
                                              SizedBox(width: 1.w),
                                              Text(
                                                'Status:',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 5.sp,
                                                ),
                                              ),
                                              SizedBox(width: 1.w),
                                              Expanded(
                                                child: Text(
                                                  item['status'],
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 5.sp,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 1.h),
                                          if ((item['comentario'] ?? '')
                                              .isNotEmpty)
                                            Row(
                                              children: [
                                                Icon(Icons.comment,
                                                    size: 5.sp,
                                                    color: Colors.black),
                                                SizedBox(width: 1.w),
                                                Text(
                                                  'Comentário:',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 5.sp,
                                                  ),
                                                ),
                                                SizedBox(width: 1.w),
                                                Expanded(
                                                  child: Text(
                                                    item['comentario'],
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 5.sp),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          SizedBox(height: 1.h),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.white,
                                                  size: 5.sp),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    title: Text(
                                                        "Confirmar remoção",
                                                        style: TextStyle(
                                                            fontSize: 16.sp)),
                                                    content: Text(
                                                        "Deseja realmente remover este item não conforme?",
                                                        style: TextStyle(
                                                            fontSize: 14.sp)),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: Text("Cancelar",
                                                            style: TextStyle(
                                                                fontSize:
                                                                    14.sp)),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          Navigator.pop(
                                                              context);
                                                          await Provider.of<
                                                              AgendamentosProvider>(
                                                            context,
                                                            listen: false,
                                                          ).removerItemNaoConforme(
                                                            agendamentoId:
                                                                agendamentoId,
                                                            itemNome: itemNome,
                                                            dataFinalizacao:
                                                                dataFinalizacao,
                                                          );
                                                        },
                                                        child: Text("Remover",
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                                fontSize:
                                                                    14.sp)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 7.sp),
                            SizedBox(width: 1.w),
                            Text(
                              'Atividades Atrasadas ',
                              style: TextStyle(
                                fontSize: 7.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${DateFormat('MM/yyyy').format(now)}',
                          style: TextStyle(
                            fontSize: 7.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        agendamentoProvider.atividadesAtrasadas.isEmpty
                            ? Center(
                                child: Text(
                                  'Nenhuma atividade atrasada ',
                                  style: TextStyle(
                                      fontSize: 5.sp, color: Colors.black54),
                                ),
                              )
                            : Card(
                                color: Colors.red.shade100,
                                elevation: 5,
                                margin: EdgeInsets.symmetric(vertical: 2.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(0),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(2.w),
                                  child: Column(
                                    children: agendamentoProvider
                                        .atividadesAtrasadas
                                        .map((agendamento) {
                                      final DateTime dataAgendada =
                                          (agendamento['dataAgendada']
                                                  as Timestamp)
                                              .toDate()
                                              .toLocal();
                                      return Card(
                                        color: Colors.red.shade300,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                        ),
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.white,
                                            size: 5.sp,
                                          ),
                                          contentPadding: EdgeInsets.all(3.w),
                                          title: Text(
                                            '${agendamento['tipoEquipamento']} - ${agendamento['equipamento']}',
                                            style: TextStyle(
                                              fontSize: 5.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Tipo de Inspeção: ${agendamento['checklistNome']}',
                                                style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 5.sp),
                                              ),
                                              Text(
                                                'Data Agendada: ${DateFormat('dd/MM/yyyy HH:mm').format(dataAgendada)}',
                                                style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 5.sp),
                                              ),
                                            ],
                                          ),
                                          tileColor: Colors.red.shade700,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Color getPrazoColor(DateTime dataAgendada) {
    DateTime now = DateTime.now();
    return now.isBefore(dataAgendada)
        ? Colors.yellow.shade200
        : Colors.red.shade200;
  }
}


//
