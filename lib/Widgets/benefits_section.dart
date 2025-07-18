import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BenefitsSection extends StatelessWidget {
  const BenefitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Por que escolher o Check Util?',
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ).animate().slideY(begin: -1, duration: 800.ms).fadeIn(),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildBenefitsList(context)),
                    const SizedBox(width: 40),
                    Expanded(child: _buildStatsCard(context)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildBenefitsList(context),
                    const SizedBox(height: 40),
                    _buildStatsCard(context),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList(BuildContext context) {
    final benefits = [
      {
        'icon': Icons.speed,
        'title': 'Aumento de Produtividade',
        'description': 'Otimize processos com automação e QR codes',
      },
      {
        'icon': Icons.security,
        'title': 'Maior Controle',
        'description': 'Monitore tudo em tempo real com relatórios detalhados',
      },
      {
        'icon': Icons.trending_down,
        'title': 'Redução de Custos',
        'description': 'Diminua gastos com manutenção preventiva eficiente',
      },
      {
        'icon': Icons.mobile_friendly,
        'title': 'Facilidade de Uso',
        'description': 'Interface intuitiva e moderna para todos os usuários',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benefícios Comprovados',
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ).animate().slideX(begin: -1, duration: 800.ms, delay: 200.ms).fadeIn(),
        const SizedBox(height: 32),
        ...benefits.asMap().entries.map((entry) {
          final index = entry.key;
          final benefit = entry.value;
          final delay = (300 + index * 100).ms;

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    benefit['icon'] as IconData,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        benefit['title'] as String,
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        benefit['description'] as String,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().slideX(begin: -1, duration: 800.ms, delay: delay).fadeIn();
        }).toList(),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Resultados Impressionantes',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          _buildStatItem(context, '85%', 'Redução no tempo de inspeção'),
          _buildStatItem(context, '92%', 'Aumento na eficiência'),
          _buildStatItem(context, '78%', 'Diminuição de falhas'),
          _buildStatItem(context, '90%', 'Satisfação dos usuários'),
        ],
      ),
    ).animate().slideX(begin: 1, duration: 800.ms, delay: 400.ms).fadeIn();
  }

  Widget _buildStatItem(BuildContext context, String percentage, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: Text(
                percentage,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

