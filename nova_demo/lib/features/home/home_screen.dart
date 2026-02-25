import 'package:flutter/material.dart';
import '../nova_lite/nova_lite_screen.dart';
import '../nova_sonic/nova_sonic_screen.dart';
import '../nova_act/nova_act_screen.dart';
import '../nova_embeddings/nova_embeddings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Amazon Nova Demos')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildDemoCard(
            context,
            title: 'Nova 2 Lite',
            description: 'Fast, cost-effective reasoning',
            icon: Icons.chat_bubble_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NovaLiteScreen()),
              );
            },
          ),
          _buildDemoCard(
            context,
            title: 'Nova 2 Sonic',
            description: 'Speech-to-speech conversational AI',
            icon: Icons.mic_none,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NovaSonicScreen()),
              );
            },
          ),
          _buildDemoCard(
            context,
            title: 'Nova Act',
            description: 'Agent fleet for UI workflows',
            icon: Icons.precision_manufacturing,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NovaActScreen()),
              );
            },
          ),
          _buildDemoCard(
            context,
            title: 'Nova Multimodal',
            description: 'Advanced embedding models',
            icon: Icons.compare,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NovaEmbeddingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
