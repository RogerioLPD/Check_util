import 'dart:convert';
import 'dart:io';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Login/login.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? empresaPrincipal;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _imagemBase64;
  final ImagePicker _picker = ImagePicker();
  File? _imagem;

  @override
  void initState() {
    super.initState();
    _carregarDadosEmpresa();
  }

  Future<void> _carregarDadosEmpresa() async {
    if (_user != null) {
      try {
        // Acessando a subcoleção 'principal' sem especificar o documento
        QuerySnapshot empresaSnapshot = await FirebaseFirestore.instance
            .collection('Empresa Principal')
            .doc(_user.uid)
            .collection('principal')
            .get();

        if (empresaSnapshot.docs.isNotEmpty) {
          // Pegamos o primeiro documento, pois só estamos aguardando um
          setState(() {
            empresaPrincipal =
                empresaSnapshot.docs.first.data() as Map<String, dynamic>;
          });
        } else {
          print('Nenhum documento encontrado');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum dado encontrado!')),
          );
        }
      } catch (e) {
        print('Erro ao carregar dados: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage(placa: '', unidade: '', tipoVeiculo: '')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer logout: $e')),
      );
    }
  }

  Future<void> _selecionarImagem() async {
    final XFile? imagemSelecionada =
        await _picker.pickImage(source: ImageSource.gallery);

    if (imagemSelecionada != null) {
      try {
        print("Imagem selecionada: ${imagemSelecionada.path}");
        // Diferencia entre Web e Mobile/Desktop
        if (kIsWeb) {
          final bytes = await imagemSelecionada.readAsBytes();
          setState(() {
            _imagemBase64 =
                base64Encode(bytes); // Salva em base64 (se necessário)
            _imagem = null; // Resetar a imagem local
          });

          // Envia o arquivo para o Firebase Storage (não base64)
          final url = await _uploadImageWeb(imagemSelecionada);
          if (url != null) {
            // Atualiza Firestore com a URL
            await FirebaseFirestore.instance
                .collection('users') // Alterado para 'users'
                .doc(_user!.uid) // Usando o UID do usuário logado
                .update({'logoUrl': url});

            // Atualiza o avatar no perfil
            setState(() {
              _user.updatePhotoURL(url); // Atualiza o avatar do Firebase Auth
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Imagem atualizada com sucesso!')),
            );
          } else {
            print("Falha no upload da imagem.");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao fazer upload da imagem')),
            );
          }
        } else {
          setState(() {
            _imagem = File(imagemSelecionada.path);
            _imagemBase64 = null; // Resetar a imagem base64
          });

          // Faz o upload e obtém a URL da imagem
          final url = await _uploadImage(_imagem!);
          if (url != null) {
            print("URL da imagem: $url");

            // Atualiza o Firestore com a URL da imagem
            await FirebaseFirestore.instance
                .collection('users') // Alterado para 'users'
                .doc(_user!.uid) // Usando o UID do usuário logado
                .update({'logoUrl': url});

            // Atualiza o avatar no perfil
            setState(() {
              _user.updatePhotoURL(url); // Atualiza o avatar do Firebase Auth
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Imagem atualizada com sucesso!')),
            );
          } else {
            print("Falha no upload da imagem.");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao fazer upload da imagem')),
            );
          }
        }
      } catch (e) {
        print("Erro ao selecionar imagem: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    } else {
      print("Nenhuma imagem foi selecionada.");
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      // Nome da imagem com timestamp para evitar conflitos
      String imageName = DateTime.now().millisecondsSinceEpoch.toString();

      // Referência ao Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(
          'logos_usuarios/$imageName'); // Altere para salvar na pasta correta

      print("Iniciando o upload da imagem...");

      // Faz o upload da imagem
      final uploadTask = await storageRef.putFile(image);

      // Retorna a URL da imagem
      String downloadUrl = await uploadTask.ref.getDownloadURL();
      print("Upload concluído, URL da imagem: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

// Função de upload para Web (baseado no código original)
  Future<String?> _uploadImageWeb(XFile imagem) async {
    try {
      String imageName = DateTime.now().millisecondsSinceEpoch.toString();

      final storageRef =
          FirebaseStorage.instance.ref().child('logos_usuarios/$imageName');

      print("Iniciando upload da imagem para Web...");

      // Cria um arquivo a partir do XFile e faz o upload
      final uploadTask = await storageRef.putData(await imagem.readAsBytes());

      String downloadUrl = await uploadTask.ref.getDownloadURL();
      print("Upload para Web concluído, URL da imagem: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem para Web: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      /*appBar: AppBar(
        title: Text(
          'Perfil',
          style: headlineTextStyle,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),*/
      body: empresaPrincipal == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(46, 16, 46, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildEmpresaInfo(),
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return customCardF(
      
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: _user != null && _user.photoURL != null
                      ? NetworkImage(_user.photoURL!)
                      : null,
                  backgroundColor: const Color.fromARGB(255, 6, 41, 70),
                  child: _user != null && _user.photoURL == null
                      ? const Icon(Icons.person, color: Colors.white, size: 40)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _selecionarImagem,
                    child: const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit,
                          color: Color.fromARGB(255, 6, 41, 70), size: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _user?.displayName ?? "Usuário",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _user?.email ?? "Email não disponível",
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpresaInfo() {
    return customCardF(
      
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (empresaPrincipal!['logoUrl'] != null)
              Center(
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: MemoryImage(
                        base64Decode(empresaPrincipal!['logoUrl']),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildInfoRow("Nome", empresaPrincipal!['nome']),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow("Endereço", empresaPrincipal!['endereco']),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow("CNPJ", empresaPrincipal!['cnpj']),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow("CEP", empresaPrincipal!['cep']),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow("Cidade", empresaPrincipal!['cidade']),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow("Telefone", empresaPrincipal!['telefone']),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow("Email", empresaPrincipal!['email']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String? value) {
    return Wrap(
      spacing: 8, // Espaçamento entre os itens
      runSpacing: 4, // Espaçamento entre as linhas
      children: [
        Text("$title:", style: buttonTextStyle),
        ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width *
                  0.7), // Limita a largura do texto
          child: Text(
            value ?? "Não disponível",
            style: subtitleTextStyle,
            overflow: TextOverflow
                .ellipsis, // Adiciona "..." caso o texto ultrapasse o limite
            maxLines: 2, // Limita o texto a no máximo 2 linhas
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: () async {
                await _auth.signOut(); // Realiza o logout do Firebase Auth
                // Redireciona para a página de Login após o logout
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage(placa: '', unidade: '', tipoVeiculo: '')),
                  (Route<dynamic> route) =>
                      false, // Remove todas as rotas anteriores
                );
              },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        "Sair",
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
