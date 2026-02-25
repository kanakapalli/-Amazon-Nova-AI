import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class NovaActScreen extends StatefulWidget {
  const NovaActScreen({super.key});

  @override
  State<NovaActScreen> createState() => _NovaActScreenState();
}

class _NovaActScreenState extends State<NovaActScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _urlController = TextEditingController(
    text: 'https://devpost.com/hackathons',
  );
  final TextEditingController _promptController = TextEditingController(
    text:
        'Find the top 5 hackathons that have a listed prize money of over \$40,000.',
  );

  bool _isLoading = false;

  // Terminal logs state
  final List<String> _terminalLogs = [];
  bool _isExecutingTask = false;
  Map<String, dynamic>? _taskResult;

  @override
  void initState() {
    super.initState();
    // Removed polling timer since we do an on-demand task
  }

  @override
  void dispose() {
    _urlController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _submitTask() async {
    if (_urlController.text.isEmpty || _promptController.text.isEmpty) return;

    setState(() {
      _isExecutingTask = true;
      _taskResult = null;
      _terminalLogs.clear();
      _terminalLogs.add('> Initiating Nova Act Web Agent...');
      _terminalLogs.add('> Target URL: \${_urlController.text}');
      _terminalLogs.add('> Objective: \${_promptController.text}');
      _terminalLogs.add('> Calling AWS Bedrock (amazon.nova-pro-v1:0)...');
    });

    final result = await _apiClient.executeNovaActTask(
      _urlController.text,
      _promptController.text,
    );

    if (!mounted) return;

    setState(() {
      _isExecutingTask = false;
      if (result != null && result.containsKey('answer')) {
        _terminalLogs.add('[SUCCESS] Task completed and results committed.');
        _taskResult = result;
      } else {
        final errorMsg = result?['error'] ?? 'Unknown error';
        _terminalLogs.add('[ERROR] Task failed: $errorMsg');
      }
    });
  }

  void _showRawJsonBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Raw Nova Response Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(_taskResult),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Act Web Agent Command'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _taskResult = null;
                _terminalLogs.clear();
                _isExecutingTask = false;
              });
            },
          ),
        ],
      ),
      body: _buildDashboardLayout(),
    );
  }

  Widget _buildDashboardLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Results Output
          Expanded(flex: 2, child: _buildFleetColumn()),
          const SizedBox(width: 24),
          // Right side: Active Execution Terminal
          Expanded(flex: 3, child: _buildExecutionTerminal()),
        ],
      ),
    );
  }

  Widget _buildExecutionTerminal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dispatch Web Agent Task',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'Target URL',
            hintText: 'e.g., https://devpost.com/hackathons',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promptController,
                decoration: InputDecoration(
                  labelText: 'Agent Objective',
                  hintText: 'e.g., Find the top 5 hackathons...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                onSubmitted: (_) => _submitTask(),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isExecutingTask ? null : _submitTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
              ),
              child: _isExecutingTask
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Execute'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Live Execution Logs',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: ListView.builder(
              itemCount: _terminalLogs.length,
              itemBuilder: (context, index) {
                final log = _terminalLogs[index];
                final isSuccess = log.contains('[SUCCESS]');
                final isError = log.contains('[ERROR]');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: isError
                          ? Colors.redAccent
                          : isSuccess
                          ? Colors.greenAccent
                          : Colors.green.shade200,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFleetColumn() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amazon Nova Act allows you to dispatch reasoning and execution tasks to an independent Web Agent. '
            'Provide a target URL and an objective, and the agent will scrape the page and return the parsed result.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task Output',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_taskResult != null)
                TextButton.icon(
                  onPressed: () => _showRawJsonBottomSheet(),
                  icon: const Icon(Icons.data_object),
                  label: const Text('View Raw JSON'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              color: Colors.black45,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Text(
                    _isExecutingTask
                        ? 'Awaiting task completion...'
                        : _taskResult != null
                        ? _taskResult!['answer'] ?? 'No answer provided.'
                        : 'No task executed yet.',
                    style: TextStyle(
                      color: _isExecutingTask || _taskResult == null
                          ? Colors.grey
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
