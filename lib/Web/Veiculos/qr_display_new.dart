import 'package:flutter/material.dart';

class CheckUtilScreen extends StatelessWidget {
  const CheckUtilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.circle, size: 20, color: Colors.black),
            SizedBox(width: 8),
            Text(
              'Check Util',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          TextButton(onPressed: () {}, child: const Text('Início')),
          TextButton(onPressed: () {}, child: const Text('Recursos')),
          TextButton(onPressed: () {}, child: const Text('Preços')),
          TextButton(onPressed: () {}, child: const Text('Contato')),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF0C7FF2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Começar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 400,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://portalpos2.vteximg.com.br/arquivos/ids/182384/1211_Gestao-de-Facilities_M.jpg?v=638207273323370000',
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black54,
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Otimize sua Gestão de Instalações',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'O Check Util oferece soluções completas para gerenciar suas instalações com eficiência. De manutenção à alocação de recursos, temos tudo que você precisa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C7FF2),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Começar'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Escolha seu Plano',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildPlanCard('Básico', 'Grátis', ['Recursos básicos', 'Suporte limitado']),
                  _buildPlanCard('Padrão', '\$29/mês', ['Todos os recursos do Básico', 'Suporte prioritário', 'Relatórios avançados'], recommended: true),
                  _buildPlanCard('Premium', '\$99/mês', ['Todos os recursos do Padrão', 'Suporte 24/7', 'Integrações personalizadas']),
                  _buildPlanCard('Empresarial', 'Personalizado', ['Funcionalidades customizadas', 'Gerente de conta dedicado', 'Treinamento presencial'], isContact: true),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                'Pronto para transformar sua gestão de instalações?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C7FF2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Começar'),
                ),
              ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(onPressed: () {}, child: const Text('Política de Privacidade')),
                  TextButton(onPressed: () {}, child: const Text('Termos de Serviço')),
                ],
              ),
              const SizedBox(height: 10),
              const Text('@2024 Check Util. Todos os direitos reservados.', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(String title, String price, List<String> features, {bool recommended = false, bool isContact = false}) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCEDBE8)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0C7FF2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Recomendado',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE7EDF4),
              foregroundColor: Colors.black,
            ),
            child: Text(isContact ? 'Fale Conosco' : 'Começar'),
          ),
          const SizedBox(height: 8),
          ...features.map(
            (feature) => Row(
              children: [
                const Icon(Icons.check, size: 16, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(child: Text(feature, style: const TextStyle(fontSize: 13))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
