import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recursos Principais',
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ).animate().slideY(begin: -1, duration: 800.ms).fadeIn(),
          const SizedBox(height: 16),
          Text(
            'Tudo que você precisa para uma gestão eficiente',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Colors.grey[600],
                ),
          )
              .animate()
              .slideY(begin: -1, duration: 800.ms, delay: 200.ms)
              .fadeIn(),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1000) {
                return Row(
                  children: [
                    Expanded(child: _buildFeatureCard(context, 0)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildFeatureCard(context, 1)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildFeatureCard(context, 2)),
                  ],
                );
              } else if (constraints.maxWidth > 600) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildFeatureCard(context, 0)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildFeatureCard(context, 1)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureCard(context, 2),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildFeatureCard(context, 0),
                    const SizedBox(height: 20),
                    _buildFeatureCard(context, 1),
                    const SizedBox(height: 20),
                    _buildFeatureCard(context, 2),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: List.generate(3, (i) {
              final index = i + 3;
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: _buildFeatureCard(context, index),
              );
            }),
          )
              .animate()
              .slideY(begin: 1, duration: 800.ms, delay: 800.ms)
              .fadeIn(),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, int index) {
    final features = [
      {
        'icon': Icons.qr_code_scanner,
        'title': 'QR Code Scanner',
        'description':
            'Escaneie QR codes para acessar informações instantaneamente',
        'image':
            'https://pixabay.com/get/g1196efdc9991194fd75e4c983f627fef6c349d8de192ffd46c7017d1772eac90220ef20f1e493041ce46090887533f1d545ca935f146d036b7fc00007e4adffe_1280.jpg',
      },
      {
        'icon': Icons.build,
        'title': 'Gestão de Equipamentos',
        'description': 'Controle total sobre seus equipamentos e manutenções',
        'image':
            'https://pixabay.com/get/g5a9786e9de405fc67fdd79a1fc7087c0746cc1b30aefdf2d20fa4f150fbe52be737e3f7faa523abf49281ffb579794b08eff7188508b8e40ce9a9d4f9c2e0ccf_1280.jpg',
      },
      {
        'icon': Icons.directions_car,
        'title': 'Controle de Veículos',
        'description': 'Gerencie sua frota com inspeções e controle de uso',
        'image':
            'https://pixabay.com/get/g5e2499bada0f2f73c9d31c0c908e83dc7f71113e6f8ac4815032ad57b1a5090257a934d479b0a35fe94cb990dd4e10d566c61a340a1b665490563e530df8176d_1280.png',
      },
      {
        'icon': Icons.people,
        'title': 'Gestão de Equipes',
        'description': 'Organize e monitore suas equipes de trabalho',
        'image':
            'https://pixabay.com/get/gf9c82b4cb04eca8f6f20a4eeaf91e637da5e215a4c246f6fc329856e337283753fdb7167350ce22a73907d19da96266a38fb443dae4349b18866e49a59a78f18_1280.jpg',
      },
      {
        'icon': Icons.location_on,
        'title': 'Controle de Locais',
        'description': 'Monitore e gerencie todos os seus locais',
        'image':
            'https://pixabay.com/get/gb4ae2bd4fc6aac1a5bf19e340ba682ee483ac7e83f659190b6437b18e8843fa7990b94a6e7a46269f5ee84744afce960ef9db7f6d6eec949bb0af7693ec111e1_1280.png',
      },
      {
        'icon': Icons.checklist,
        'title': 'Checklists e Auditorias',
        'description': 'Crie e execute checklists personalizados',
        'image':
            'https://pixabay.com/get/g160fd060443d1b147490ec744f6b5d26d34b028107fb8f225a9139e06819b72c45d185aabe60752ddd754d7afbf29b49780e5c494ae74522d7cdef284af695a7_1280.jpg',
      },
    ];

    final feature = features[index];
    final delay = (index * 200).ms;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                feature['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      feature['icon'] as IconData,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'] as String,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    feature['description'] as String,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.grey[600],
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1, duration: 800.ms, delay: delay).fadeIn();
  }
}
