// widgets/cards/card_image_dashboard.dart
// Arquivo de definição da tela de card de imagem para o dashboard.
//============================================================================//

import 'package:flutter/material.dart';

class CardImageDashboard extends StatelessWidget {
  final String imagePath;
  final double height;

  const CardImageDashboard({
    super.key,
    this.imagePath = 'assets/construcao2.png',
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          imagePath,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1B3A5C),
                    const Color(0xFF1B3A5C).withOpacity(0.7),
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.construction,
                      size: 60,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Acompanha Obra',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
