import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class NovaEmbeddingsScreen extends StatefulWidget {
  const NovaEmbeddingsScreen({super.key});

  @override
  State<NovaEmbeddingsScreen> createState() => _NovaEmbeddingsScreenState();
}

class _NovaEmbeddingsScreenState extends State<NovaEmbeddingsScreen> {
  final TextEditingController _textController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  List<dynamic>? _embeddings;

  Future<void> _generateEmbeddings() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _embeddings = null;
    });

    final data = await _apiClient.generateNovaEmbeddings(_textController.text);

    setState(() {
      _isLoading = false;
      if (data != null) {
        _embeddings = data['embedding'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Multimodal Embeddings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Amazon Nova Multimodal Embeddings translates text, images, and video into rich vectors. '
              'Enter text (or imagine an image upload here) to generate unified vector embeddings.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Describe an image or concept...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateEmbeddings,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.analytics),
              label: Text(
                _isLoading ? 'Generating Context...' : 'Generate Embedding',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),
            if (_embeddings != null) ...[
              Text(
                'Vector Representation (\${_embeddings?.length} dimensions)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _embeddings!.length,
                  itemBuilder: (context, index) {
                    final double val = _embeddings![index];
                    // Normalize -1 to 1 into 0 to 1 for color
                    final double normalized = (val + 1) / 2;
                    return Container(
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Colors.blue.shade900,
                          Colors.cyanAccent,
                          normalized,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          val.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
