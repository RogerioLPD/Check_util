import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Ocorrencias/Novaocorrencia/home_nova.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:checkutil/Services/ocorrencia_estado.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:signature/signature.dart';

class NovaOcorrenciaMobile extends StatefulWidget {
  const NovaOcorrenciaMobile({super.key});

  @override
  State<NovaOcorrenciaMobile> createState() => _NovaOcorrenciaMobileState();
}

class _NovaOcorrenciaMobileState extends State<NovaOcorrenciaMobile> {
  final _formKey = GlobalKey<FormState>();
  final _ocorrenciaController = TextEditingController();
  final _nomeController = TextEditingController();
  File? _imagem; // Para Mobile
  String? _imagemBase64; // Para Web

  final ImagePicker _picker = ImagePicker();

  List unidades = [];
  List locais = []; // Lista para armazenar os locais
  String? unidadeSelecionada;
  String? localSelecionado; // Local selecionado
  String? statusSelecionado;
  String? userUid;
  int _vendaNumero = 1;
  String _observacoes = '';
  final SignatureController _signatureController =
      SignatureController(penStrokeWidth: 3, penColor: Colors.black);
  bool _exibirBotaoSalvar = false;
  bool ocorrenciaEmEquipamento = false;
  String? statusEquipamento;
  final List<String> opcoesEquipamento = [
    'Equipamento em funcionamento',
    'Equipamento parado'
  ];

  @override
  void initState() {
    super.initState();
    unidadeSelecionada =
        Provider.of<UnidadeProvider>(context, listen: false).unidadeSelecionada;
    if (unidadeSelecionada != null) {
      _fetchLocais();
      _initializeUser();
      _initializeVendaNumero();
    }
  }

  Future<void> _initializeVendaNumero() async {
    // Obtenha o provedor de UnidadeProvider
    final unidadeProvider =
        Provider.of<UnidadeProvider>(context, listen: false);

    // Certifique-se de que uma unidade está selecionada
    if (unidadeProvider.unidadeSelecionada == null) {
      print("Nenhuma unidade selecionada.");
      return;
    }

    // Busque o último número de venda através do provider
    await unidadeProvider.buscarUltimoNumeroVenda();

    setState(() {
      // Adicione 1 ao último número de venda obtido
      _vendaNumero = (unidadeProvider.ultimoNumeroVenda ?? 0) + 1;
    });

    print("Próximo número de venda: $_vendaNumero");
  }

  Future<void> _initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userUid = user.uid;
      });
    }
  }

  void _incrementarVendaNumero() {
    setState(() {
      _vendaNumero++;
      _exibirBotaoSalvar = true;
    });

    // Exibindo um SnackBar ao incrementar o número da venda
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Ocorrência cadastrada com sucesso! Não esqueça de salvar!",
                style: titleDrawerTextStyle,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _fetchLocais() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        throw Exception('Usuário não autenticado.');
      }

      if (unidadeSelecionada == null || unidadeSelecionada!.isEmpty) {
        return; // Não faz nada se a unidade não estiver selecionada
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('Local_lista')
          .doc(userId)
          .collection('local')
          .where('unidade', isEqualTo: unidadeSelecionada)
          .get();

      setState(() {
        locais =
            querySnapshot.docs.map((doc) => doc['nome'] as String).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar Locais: $e')),
      );
    }
  }

  // Função para buscar os locais da coleção 'rooms'

  Future<void> _selecionarImagem() async {
    final XFile? imagemSelecionada =
        await _picker.pickImage(source: ImageSource.gallery);
    if (imagemSelecionada != null) {
      if (kIsWeb) {
        final bytes = await imagemSelecionada.readAsBytes();
        setState(() {
          _imagemBase64 = base64Encode(bytes);
        });
      } else {
        setState(() {
          _imagem = File(imagemSelecionada.path);
        });
      }
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      String imageName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('checklist_images')
          .child(imageName);
      final uploadTask = await storageRef.putFile(image);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  Future<String?> _convertSignatureToBase64() async {
    final signatureBytes = await _signatureController.toPngBytes();
    if (signatureBytes == null) return null;
    return base64Encode(signatureBytes);
  }

  Future<void> _salvarOcorrencia() async {
    String ocorrencia = _ocorrenciaController.text;
    String nome = _nomeController.text;

    final unidadeProvider =
        Provider.of<UnidadeProvider>(context, listen: false);

    if (unidadeProvider.unidadeSelecionada == null) {
      print("Nenhuma unidade selecionada.");
      return;
    }

    await unidadeProvider.buscarUltimoNumeroVenda();
    final ultimoNumero = unidadeProvider.ultimoNumeroVenda ?? 0;

    setState(() {
      _vendaNumero = ultimoNumero + 1;
    });

    String? unidade =
        Provider.of<UnidadeProvider>(context, listen: false).unidadeSelecionada;
    final ocorrenciaState =
        Provider.of<OcorrenciaEstado>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      String? imagemUrl;
      String? assinaturaBase64 = await _convertSignatureToBase64();

      try {
        if (_imagem != null) {
          imagemUrl = await _uploadImage(_imagem!);
        }

        if (_imagemBase64 != null) {
          final bytes = base64Decode(_imagemBase64!);
          String imageName = DateTime.now().millisecondsSinceEpoch.toString();
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('checklist_images')
              .child(imageName);
          final uploadTask = await storageRef.putData(bytes);
          imagemUrl = await uploadTask.ref.getDownloadURL();
        }

        // Verifica se já existe ocorrência com o mesmo número
        QuerySnapshot existingVenda = await FirebaseFirestore.instance
            .collection('Ocorrencias') // <-- Sem .doc(userId)
            .where('_vendaNumero', isEqualTo: _vendaNumero)
            .get();

        if (existingVenda.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Já existe um equipamento com o número de venda $_vendaNumero.',
              ),
            ),
          );
          return;
        }

        // Salva globalmente, sem userId
        await FirebaseFirestore.instance.collection('Ocorrencias').add({
          'ocorrencia': ocorrencia,
          'unidade': unidade,
          '_vendaNumero': _generateVendaNumero(_vendaNumero),
          'status': statusSelecionado,
          'imageUrl': imagemUrl,
          'nomeUsuario': nome,
          'assinatura': assinaturaBase64,
          "observacoes": _observacoes,
          'dataInicio':
              "${ocorrenciaState.dataInicio.year}-${ocorrenciaState.dataInicio.month.toString().padLeft(2, '0')}-${ocorrenciaState.dataInicio.day.toString().padLeft(2, '0')}",
          'horaInicio':
              "${ocorrenciaState.horaInicio.hour.toString().padLeft(2, '0')}:${ocorrenciaState.horaInicio.minute.toString().padLeft(2, '0')}",
          'dataTermino':
              "${ocorrenciaState.dataTermino.year}-${ocorrenciaState.dataTermino.month.toString().padLeft(2, '0')}-${ocorrenciaState.dataTermino.day.toString().padLeft(2, '0')}",
          'horaTermino':
              "${ocorrenciaState.horaTermino.hour.toString().padLeft(2, '0')}:${ocorrenciaState.horaTermino.minute.toString().padLeft(2, '0')}",
          'ocorrenciaEmEquipamento': ocorrenciaEmEquipamento,
          'statusEquipamento':
              ocorrenciaEmEquipamento ? statusEquipamento : null,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocorrência cadastrada com sucesso!')),
        );

        // Limpar campos e estados
        _ocorrenciaController.clear();
        setState(() {
          unidadeSelecionada = null;
          localSelecionado = null;
          _imagem = null;
          _imagemBase64 = null;
        });

        // Navegar para nova tela
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeNovaOcorrencias(),
          ),
        );
      } on FirebaseException catch (firebaseError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro do Firebase: $firebaseError')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar ocorrência: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final ocorrenciaState = context.read<OcorrenciaEstado>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? ocorrenciaState.dataInicio
          : ocorrenciaState.dataTermino,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: textSecondary,
              onPrimary: Colors.white,
              onSurface: textSecondary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: textSecondary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStartDate) {
        ocorrenciaState.setDataInicio(picked);
      } else {
        ocorrenciaState.setDataTermino(picked);
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final ocorrenciaState = context.read<OcorrenciaEstado>();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? ocorrenciaState.horaInicio
          : ocorrenciaState.horaTermino,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: textSecondary,
              onPrimary: Colors.white,
              onSurface: textSecondary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: textSecondary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStartTime) {
        ocorrenciaState.setHoraInicio(picked);
      } else {
        ocorrenciaState.setHoraTermino(picked);
      }
    }
  }

  String _generateVendaNumero(int number) {
    return number.toString().padLeft(4, '0'); // Gera o número no formato 0001
  }

  @override
  Widget build(BuildContext context) {
    // Obtém a unidadeSelecionada do Provider
    unidadeSelecionada = context.watch<UnidadeProvider>().unidadeSelecionada ??
        'Nenhuma Unidade Selecionada';

    // Chama _fetchLocais() sempre que a unidadeSelecionada mudar

    // Aqui você pega o último número de venda diretamente do provider
    final ultimoNumero =
        context.watch<UnidadeProvider>().ultimoNumeroVenda ?? 0;
    final vendaNumero = ultimoNumero + 1; // Calcula o próximo número

    final ocorrenciaState = context.watch<OcorrenciaEstado>();
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140.h), // Altura responsiva da AppBar
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundMobileButton,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double availableHeight = constraints.maxHeight;

                return Padding(
                  padding: EdgeInsets.only(
                      left: 16.w, right: 16.w, top: availableHeight * 0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.arrow_back, color: textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Spacer(), // Empurra o título para a parte inferior do espaço disponível
                      Text(
                        'Nova Ocorrência',
                        style: mobileTextStyle.copyWith(
                          fontSize: 28.sp,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 60.h),
                  customCardMobile(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                            _ocorrenciaController, 'Título da Ocorrência'),
                        SizedBox(height: 10.h),
                        Center(
                          child: SizedBox(
                            width: 110.w, // Definindo largura fixa
                            height: 170.h,
                            child: GestureDetector(
                              onTap: _selecionarImagem,
                              child: Container(
                                width: 110.w,
                                height: 170.h,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(143, 55, 71, 79),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: const Color(0xFF37474F),
                                  ),
                                ),
                                child: _imagem == null && _imagemBase64 == null
                                    ? Icon(Icons.camera_alt,
                                        color: const Color(0xFF37474F),
                                        size: 50.sp)
                                    : (kIsWeb && _imagemBase64 != null)
                                        ? Image.memory(
                                            base64Decode(_imagemBase64!),
                                            width: 100.w,
                                            height: 100.h,
                                          )
                                        : (_imagem != null)
                                            ? Image.file(
                                                _imagem!,
                                                width: 100.w,
                                                height: 100.h,
                                              )
                                            : Icon(Icons.camera_alt,
                                                color: const Color(0xFF37474F),
                                                size: 50.sp),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.w),
                        Text(
                          'Clique no botão para selecionar a imagem da Ocorrência',
                          style: drawerStyle.copyWith(
                              fontSize: 14.sp,
                              color: textButton,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'A foto deve estar nítida e o problema bem visivel',
                          style: drawerStyle.copyWith(
                              fontSize: 12.sp, color: drawerTextColor),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  customCardMobile(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title:
                              const Text('A ocorrência é em um equipamento?'),
                          value: ocorrenciaEmEquipamento,
                          onChanged: (value) {
                            setState(() {
                              ocorrenciaEmEquipamento = value;
                              if (!value) {
                                statusEquipamento =
                                    null; // Resetar dropdown se for "Não"
                              }
                            });
                          },
                        ),
                        if (ocorrenciaEmEquipamento)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Status do Equipamento',
                                border: OutlineInputBorder(),
                              ),
                              value: statusEquipamento,
                              onChanged: (String? newValue) {
                                setState(() {
                                  statusEquipamento = newValue;
                                });
                              },
                              items: opcoesEquipamento.map((String opcao) {
                                return DropdownMenuItem<String>(
                                  value: opcao,
                                  child: Text(opcao),
                                );
                              }).toList(),
                            ),
                          ),
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color.fromARGB(255, 216, 216, 216),
                                width: 1),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          alignment: Alignment.centerLeft,
                          height: 58.h,
                          child: Text(
                            "Ocorrência nº: ${_generateVendaNumero(vendaNumero)}",
                            style: bodyTextStyle.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  customCardMobile(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          height: 58.h,
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color.fromARGB(255, 216, 216, 216),
                                width: 1),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          child: Text(
                            "Unidade: ${unidadeSelecionada ?? 'Nenhuma Unidade Selecionada'}",
                            style: bodyTextStyle.copyWith(fontSize: 12.sp),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        const Divider(),
                        SizedBox(height: 10.h),
                        DropdownButtonFormField<String>(
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF37474F)),
                          decoration: buildInputDecoration('Status'),
                          value: statusSelecionado,
                          items: ['Pendente', 'Realizado', 'Analisado']
                              .map<DropdownMenuItem<String>>((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              statusSelecionado = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor, selecione o status.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  customCardMobile(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data de início:'),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color.fromARGB(255, 216, 216, 216),
                                width: 1),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          alignment: Alignment.centerLeft,
                          height: 58.h,
                          child: Row(
                            children: [
                              Text(
                                '${ocorrenciaState.dataInicio.day.toString().padLeft(2, '0')}/'
                                '${ocorrenciaState.dataInicio.month.toString().padLeft(2, '0')}/'
                                '${ocorrenciaState.dataInicio.year}',
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () {
                                  _selectDate(context,
                                      true); // Selecionar data de início
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text('Hora de início:'),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.sp),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color.fromARGB(255, 216, 216, 216),
                                width: 1),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          alignment: Alignment.centerLeft,
                          height: 58.h,
                          child: Row(
                            children: [
                              Text(
                                '${ocorrenciaState.horaInicio.hour.toString().padLeft(2, '0')}:'
                                '${ocorrenciaState.horaInicio.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.access_time),
                                onPressed: () {
                                  _selectTime(context,
                                      true); // Selecionar hora de início
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  customCardMobile(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data de término:'),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.sp),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color.fromARGB(255, 216, 216, 216),
                                width: 1),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          alignment: Alignment.centerLeft,
                          height: 58.h,
                          child: Row(
                            children: [
                              Text(
                                '${ocorrenciaState.dataTermino.day.toString().padLeft(2, '0')}/'
                                '${ocorrenciaState.dataTermino.month.toString().padLeft(2, '0')}/'
                                '${ocorrenciaState.dataTermino.year}',
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () {
                                  _selectDate(context,
                                      false); // Selecionar data de término
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text('Hora de término:'),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.sp),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color.fromARGB(255, 216, 216, 216),
                                width: 1),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          alignment: Alignment.centerLeft,
                          height: 58.h,
                          child: Row(
                            children: [
                              Text(
                                '${ocorrenciaState.horaTermino.hour.toString().padLeft(2, '0')}:'
                                '${ocorrenciaState.horaTermino.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.access_time),
                                onPressed: () {
                                  _selectTime(context,
                                      false); // Selecionar hora de término
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  customCardMobile(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Observações:',
                          style: cardTitleTextStyle..copyWith(fontSize: 12.sp),
                        ),
                        SizedBox(height: 10.h),
                        TextField(
                          maxLines: 6,
                          onChanged: (value) {
                            setState(() {
                              _observacoes = value;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Insira as observações aqui',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  customCardMobile(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nome:',
                          style: cardTitleTextStyle.copyWith(fontSize: 12.sp),
                        ),
                        SizedBox(height: 5.h),
                        TextField(
                          controller: _nomeController,
                          decoration: InputDecoration(
                            hintText: 'Digite seu nome',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 15,
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          'Assinatura:',
                          style: cardTitleTextStyle.copyWith(fontSize: 12.sp),
                        ),
                        SizedBox(height: 10.h),
                        Signature(
                          controller: _signatureController,
                          width: double.infinity,
                          height: 150,
                          backgroundColor: Colors.grey[200]!,
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            customElevatedButton(
                              onPressed: () {
                                _signatureController.clear();
                                _nomeController.clear();
                              },
                              label: "Limpar",
                              labelStyle:
                                  buttonTextStyle.copyWith(fontSize: 14.sp),
                              icon: Icons.cancel,
                              iconColor: const Color.fromARGB(255, 6, 41, 70),
                              backgroundColor:
                                  const Color.fromARGB(193, 195, 204, 218),
                            ),
                            customElevatedButton(
                              onPressed: () async {
                                final signatureImage =
                                    await _signatureController.toPngBytes();
                                final String nome = _nomeController.text.trim();
                                if (nome.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Por favor, preencha o nome antes de salvar."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (signatureImage != null) {
                                  // Salvar assinatura no banco de dados ou fazer upload
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline,
                                            color: Colors.white),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Assinatura salva com sucesso! ",
                                            style: titleDrawerTextStyle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
                              label: "Salvar",
                              labelStyle:
                                  buttonTextStyle.copyWith(fontSize: 14.sp),
                              icon: Icons.check,
                              iconColor: const Color.fromARGB(255, 6, 41, 70),
                              backgroundColor: Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Align(
                    alignment: Alignment.center,
                    child: customMobileElevatedButton(
                      onPressed: () {
                        _incrementarVendaNumero();
                      },
                      label: 'Finalizar Ocorrência',
                      labelStyle:
                          buttonMobileTextStyle.copyWith(fontSize: 14.sp),
                      icon: Icons.check,
                      iconColor: textPrimary,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  if (_exibirBotaoSalvar)
                    Center(
                      child: customMobileElevatedButton(
                        onPressed: _salvarOcorrencia,
                        label: 'Salvar Ocorrência',
                        labelStyle:
                            buttonMobileTextStyle.copyWith(fontSize: 14.sp),
                        icon: Icons.check,
                        iconColor: backgroundAppBarMobile,
                      ),
                    ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildTextField(TextEditingController controller, String label) {
  return Column(
    children: [
      const SizedBox(height: 10),
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: bodyTextStyle,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(
                color: Color.fromARGB(255, 216, 216, 216)), // Cor correta
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(
                color: Color(0xFF37474F), width: 2), // Cor ao focar
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, insira $label.';
          }
          return null;
        },
      ),
    ],
  );
}
