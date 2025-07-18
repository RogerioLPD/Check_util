import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CTASection extends StatelessWidget {
  const CTASection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(40),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Pronto para Revolucionar sua Gestão?',
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ).animate().slideY(begin: -1, duration: 800.ms).fadeIn(),
          const SizedBox(height: 16),
          Text(
            'Comece agora mesmo e transforme a forma como você gerencia seus facilities',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ).animate().slideY(begin: -1, duration: 800.ms, delay: 200.ms).fadeIn(),
          const SizedBox(height: 32),

          /// BOTÕES — Responsivo com Wrap
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Começar Gratuitamente',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ).animate().slideY(begin: 1, duration: 800.ms, delay: 400.ms).fadeIn(),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Falar com Especialista',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ).animate().slideY(begin: 1, duration: 800.ms, delay: 500.ms).fadeIn(),
            ],
          ),

          const SizedBox(height: 24),

          /// ÍCONES + TEXTOS — Responsivo com Wrap
          Wrap(
            spacing: 24,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildInfoItem(context, 'Teste gratuito por 30 dias'),
              _buildInfoItem(context, 'Sem compromisso'),
            ],
          ).animate().slideY(begin: 1, duration: 800.ms, delay: 600.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
