import 'package:checkutil/Services/equipamentos.dart';
import 'package:checkutil/Services/naoconforme_veiculos.dart';
import 'package:checkutil/Services/veiculo_finalizado_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DashboardVeiculosMobile extends StatefulWidget {
  const DashboardVeiculosMobile({super.key});

  @override
  State<DashboardVeiculosMobile> createState() =>
      _DashboardVeiculosMobileState();
}

class _DashboardVeiculosMobileState extends State<DashboardVeiculosMobile> {
  bool _dadosCarregados = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final unidade = Provider.of<UnidadeProvider>(context).unidadeSelecionada;

    if (!_dadosCarregados && unidade != null && unidade.isNotEmpty) {
      _dadosCarregados = true;
      Provider.of<VeiculoFinalizadoProvider>(context, listen: false)
          .carregarVeiculosDoDia(unidade);
      Provider.of<ItensNaoConformesVeiculos>(context, listen: false)
          .setUnidadeSelecionada(unidade);
    }
  }

  @override
  Widget build(BuildContext context) {
    final veiculoProvider = Provider.of<VeiculoFinalizadoProvider>(context);
    final naoConformesProvider =
        Provider.of<ItensNaoConformesVeiculos>(context);
    final listaNaoConformes = naoConformesProvider.itensNaoConformes;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dashboard Veículos",
          style: TextStyle(
              fontSize: 20.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
      ),
      body: veiculoProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600.w),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Veículos em uso',
                            style: TextStyle(
                                fontSize: 18.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12.h),
                        ...veiculoProvider.veiculos.map((veiculo) {
                          final dataFormatada = DateFormat('dd/MM/yyyy – HH:mm')
                              .format(veiculo.dataFinalizacao);

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9.r)),
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Placa: ${veiculo.placa}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.sp)),
                                  SizedBox(height: 8.h),
                                  Text(
                                      'Usuário: ${veiculo.usuarioNome} (${veiculo.usuarioEmail})',
                                      style: TextStyle(fontSize: 14.sp)),
                                  Text('Finalizado em: $dataFormatada',
                                      style: TextStyle(fontSize: 14.sp)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 24.h),
                        Text('Itens Não Conformes',
                            style: TextStyle(
                                fontSize: 18.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12.h),
                        if (listaNaoConformes.isEmpty)
                          Text('Nenhum item não conforme encontrado.',
                              style: TextStyle(fontSize: 10.sp)),
                        ...listaNaoConformes.map((item) {
                          final dataFormatada = item['dataFinalizacao'] != null
                              ? DateFormat('dd/MM/yyyy – HH:mm').format(
                                  (item['dataFinalizacao'] as Timestamp)
                                      .toDate())
                              : '';

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                            color: Colors.red[50],
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9.r)),
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.warning,
                                          color: Colors.red, size: 20.sp),
                                      SizedBox(width: 8.w),
                                      Text('Item Não Conforme',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18.sp)),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text('Item: ${item['item']}',
                                      style: TextStyle(fontSize: 14.sp)),
                                  Text('Comentário: ${item['comentario']}',
                                      style: TextStyle(fontSize: 14.sp)),
                                  Text('Placa: ${item['placa']}',
                                      style: TextStyle(fontSize: 14.sp)),
                                  Text('Data: $dataFormatada',
                                      style: TextStyle(fontSize: 14.sp)),
                                  Text('Usuário: ${item['usuario']['nome']}',
                                      style: TextStyle(fontSize: 14.sp)),
                                  SizedBox(height: 8.h),
                                  if (item['imagem'] != null &&
                                      (item['imagem'] as String).isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Image.network(
                                        item['imagem'],
                                        height: 150.h,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
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
                ),
              ),
            ),
    );
  }
}
