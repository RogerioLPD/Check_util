import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildHeroContent(context)),
                    const SizedBox(width: 40),
                    Expanded(child: _buildHeroImage(context)),
                  ],
                )
              : Column(
                  children: [
                    _buildHeroContent(context),
                    const SizedBox(height: 40),
                    _buildHeroImage(context),
                  ],
                ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestão Completa de Facilities',
          style: Theme.of(context).textTheme.displaySmall!.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ).animate().slideX(begin: -1, duration: 800.ms).fadeIn(),
        const SizedBox(height: 16),
        Text(
          'com QR Code',
          style: Theme.of(context).textTheme.displaySmall!.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ).animate().slideX(begin: -1, duration: 800.ms, delay: 200.ms).fadeIn(),
        const SizedBox(height: 24),
        Text(
          'Gerencie equipamentos, equipes, veículos e locais com eficiência. '
          'Realize inspeções, checklists e auditorias através de QR codes de '
          'forma simples e moderna.',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: Colors.grey[700],
            height: 1.6,
          ),
        ).animate().slideX(begin: -1, duration: 800.ms, delay: 400.ms).fadeIn(),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Começar Agora', style: TextStyle(fontSize: 16)),
            ).animate().slideY(begin: 1, duration: 800.ms, delay: 600.ms).fadeIn(),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Ver Demo', style: TextStyle(fontSize: 16)),
            ).animate().slideY(begin: 1, duration: 800.ms, delay: 700.ms).fadeIn(),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          'https://pixabay.com/get/g1196efdc9991194fd75e4c983f627fef6c349d8de192ffd46c7017d1772eac90220ef20f1e493041ce46090887533f1d545ca935f146d036b7fc00007e4adffe_1280.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.qr_code_scanner,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          },
        ),
      ),
    ).animate().slideX(begin: 1, duration: 800.ms, delay: 300.ms).fadeIn();
  }
}
