import 'dart:convert';
import 'dart:io';

import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Ocorrencias/Novaocorrencia/home_nova.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:checkutil/Services/ocorrencia_estado.dart';
import 'package:checkutil/Web/Cadastros/add_equipamento.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:signature/signature.dart';

class CadastrarOcorrenciaScreen extends StatefulWidget {
  const CadastrarOcorrenciaScreen({super.key});

  @override
  State<CadastrarOcorrenciaScreen> createState() =>
      _CadastrarOcorrenciaScreenState();
}

class _CadastrarOcorrenciaScreenState extends State<CadastrarOcorrenciaScreen> {
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
    _initializeUser();
    _initializeVendaNumero();
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

  final unidadeProvider = Provider.of<UnidadeProvider>(context, listen: false);

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
  final ocorrenciaState = Provider.of<OcorrenciaEstado>(context, listen: false);

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
        'statusEquipamento': ocorrenciaEmEquipamento ? statusEquipamento : null,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (unidadeSelecionada != null) {
        _fetchLocais();
      }
    });

    // Aqui você pega o último número de venda diretamente do provider
    final ultimoNumero =
        context.watch<UnidadeProvider>().ultimoNumeroVenda ?? 0;
    final vendaNumero = ultimoNumero + 1; // Calcula o próximo número

    final ocorrenciaState = context.watch<OcorrenciaEstado>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_exibirBotaoSalvar)
            customElevatedButton(
              onPressed: _salvarOcorrencia,
              label: 'Salvar Ocorrência',
              labelStyle: buttonTextStyle,
              icon: Icons.check,
              iconColor: const Color.fromARGB(255, 6, 41, 70),
              backgroundColor: backgroundButton,
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.zero, // Garantindo que não há margem extra
                  padding: EdgeInsets.zero,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: Color.fromARGB(255, 216, 216, 216),
                          width: 1.0), // Borda no topo
                      right: BorderSide(
                          color: Color.fromARGB(255, 216, 216, 216),
                          width: 1.0), // Borda na direita
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(45, 20, 40, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Nova Ocorrência',
                          style: headTextStyle,
                        ),
                        const SizedBox(height: 40),
                        _buildTextField(
                            _ocorrenciaController, 'Título da Ocorrência'),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 110, // Definindo largura fixa
                              child: GestureDetector(
                                onTap: _selecionarImagem,
                                child: Container(
                                  width: 110,
                                  height: 105,
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(143, 55, 71, 79),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF37474F),
                                    ),
                                  ),
                                  child:
                                      _imagem == null && _imagemBase64 == null
                                          ? const Icon(Icons.camera_alt,
                                              color: Color(0xFF37474F),
                                              size: 50)
                                          : (kIsWeb && _imagemBase64 != null)
                                              ? Image.memory(
                                                  base64Decode(_imagemBase64!),
                                                  width: 100,
                                                  height: 100,
                                                )
                                              : (_imagem != null)
                                                  ? Image.file(
                                                      _imagem!,
                                                      width: 100,
                                                      height: 100,
                                                    )
                                                  : const Icon(Icons.camera_alt,
                                                      color: Color(0xFF37474F),
                                                      size: 50),
                                ),
                              ),
                            ),
                            const SizedBox(
                                width:
                                    20), // Espaço ajustado para evitar overflow
                            Expanded(
                              // Envolvendo os widgets para evitar erro de overflow
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SwitchListTile(
                                    title: const Text(
                                        'A ocorrência é em um equipamento?'),
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
                                        items: opcoesEquipamento
                                            .map((String opcao) {
                                          return DropdownMenuItem<String>(
                                            value: opcao,
                                            child: Text(opcao),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color.fromARGB(255, 216, 216, 216),
                                width: 1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.centerLeft,
                          height: 48,
                          child: Text(
                            "Ocorrência nº: ${_generateVendaNumero(vendaNumero)}",
                            style: bodyTextStyle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color.fromARGB(255, 216, 216, 216),
                                width: 1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.centerLeft,
                          height: 48,
                          child: Text(
                            "Unidade: ${unidadeSelecionada ?? 'Nenhuma Unidade Selecionada'}",
                            style: bodyTextStyle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
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

                        // Segunda coluna de 4 elementos

                        Text('Data de início:'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color.fromARGB(255, 216, 216, 216),
                                width: 1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.centerLeft,
                          height: 48,
                          child: Row(
                            children: [
                              Text(
                                '${ocorrenciaState.dataInicio.day.toString().padLeft(2, '0')}/'
                                '${ocorrenciaState.dataInicio.month.toString().padLeft(2, '0')}/'
                                '${ocorrenciaState.dataInicio.year}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
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
                        const SizedBox(height: 10),
                        Text('Hora de início:'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color.fromARGB(255, 216, 216, 216),
                                width: 1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.centerLeft,
                          height: 48,
                          child: Row(
                            children: [
                              Text(
                                '${ocorrenciaState.horaInicio.hour.toString().padLeft(2, '0')}:'
                                '${ocorrenciaState.horaInicio.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
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
                        const SizedBox(height: 10),
                        Text('Data de término:'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color.fromARGB(255, 216, 216, 216),
                                width: 1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.centerLeft,
                          height: 48,
                          child: Row(
                            children: [
                              Text(
                                '${ocorrenciaState.dataTermino.day.toString().padLeft(2, '0')}/'
                                '${ocorrenciaState.dataTermino.month.toString().padLeft(2, '0')}/'
                                '${ocorrenciaState.dataTermino.year}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
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
                        const SizedBox(height: 10),
                        Text('Hora de término:'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color.fromARGB(255, 216, 216, 216),
                                width: 1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.centerLeft,
                          height: 48,
                          child: Row(
                            children: [
                              Text(
                                '${ocorrenciaState.horaTermino.hour.toString().padLeft(2, '0')}:'
                                '${ocorrenciaState.horaTermino.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
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
                        const SizedBox(height: 10),
                        customCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Observações:',
                                  style: cardTitleTextStyle,
                                ),
                                const SizedBox(height: 10),
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
                        ),
                        const SizedBox(height: 20),
                        customCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nome:', style: cardTitleTextStyle),
                                const SizedBox(height: 5),
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
                                const SizedBox(height: 20),
                                Text('Assinatura:', style: cardTitleTextStyle),
                                const SizedBox(height: 10),
                                Signature(
                                  controller: _signatureController,
                                  width: double.infinity,
                                  height: 150,
                                  backgroundColor: Colors.grey[200]!,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    customElevatedButton(
                                      onPressed: () {
                                        _signatureController.clear();
                                        _nomeController.clear();
                                      },
                                      label: "Limpar",
                                      labelStyle: buttonTextStyle,
                                      icon: Icons.cancel,
                                      iconColor:
                                          const Color.fromARGB(255, 6, 41, 70),
                                      backgroundColor: const Color.fromARGB(
                                          193, 195, 204, 218),
                                    ),
                                    customElevatedButton(
                                      onPressed: () async {
                                        final signatureImage =
                                            await _signatureController
                                                .toPngBytes();
                                        final String nome =
                                            _nomeController.text.trim();
                                        if (nome.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(
                                                    Icons.check_circle_outline,
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            duration:
                                                const Duration(seconds: 4),
                                          ),
                                        );
                                      },
                                      label: "Salvar",
                                      labelStyle: buttonTextStyle,
                                      icon: Icons.check,
                                      iconColor:
                                          const Color.fromARGB(255, 6, 41, 70),
                                      backgroundColor: Colors.orange,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: customElevatedButton(
                    onPressed: () {
                      _incrementarVendaNumero();
                    },
                    label: 'Finalizar Ocorrência',
                    labelStyle: buttonTextStyle,
                    icon: Icons.check,
                    iconColor: const Color.fromARGB(255, 6, 41, 70),
                    backgroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
              ],
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
