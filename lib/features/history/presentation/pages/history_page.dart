import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartquizai/core/theme/app_gradients.dart';
import 'package:smartquizai/core/theme/app_palette.dart';
import 'package:smartquizai/core/services/storage_service.dart';
import 'package:smartquizai/core/utils/app_utils.dart';
import 'package:smartquizai/shared/widgets/app_card.dart';
import 'package:smartquizai/shared/widgets/gradient_background.dart';
import 'package:smartquizai/shared/widgets/glass_container.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _history = StorageService.getQuizHistory();
      _history.sort(
        (a, b) =>
            DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])),
      );
    });
  }

  void _clearHistory() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clear history?',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'This removes all saved quiz results from this device.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppPalette.textPrimary,
                        side: BorderSide(color: Colors.white.withOpacity(0.18)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        StorageService.clearQuizHistory();
                        _loadHistory();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('History cleared')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.error,
                        foregroundColor: AppPalette.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.go('/home');
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppPalette.background,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Quiz History'),
          actions: [
            if (_history.isNotEmpty)
              IconButton(
                onPressed: _clearHistory,
                icon: const Icon(Icons.delete_sweep),
              ),
          ],
        ),
        body: GradientBackground(
          gradient: AppGradients.deepPurpleToBlue,
          child: SafeArea(
            child: _history.isEmpty ? _buildEmptyState() : _buildHistoryList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: AppPalette.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No quiz history yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Take your first quiz to see results here!',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final date = DateTime.parse(item['date']);
        final percentage = item['percentage'] as int;
        final isPassed = percentage >= 60;
        final hiveKey = item['hiveKey'];
        final quizType = (item['quizType'] ?? '').toString();

        final topic = (item['topic'] ?? '').toString();

        return Dismissible(
          key: ValueKey('history_${hiveKey}_${item['date']}'),
          direction: DismissDirection.horizontal,
          background: _SwipeAction(
            alignment: Alignment.centerLeft,
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppPalette.primaryA, AppPalette.primaryB],
            ),
            icon: Icons.refresh,
            label: 'Retake',
          ),
          secondaryBackground: const _SwipeAction(
            alignment: Alignment.centerRight,
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xFF7F1D1D), AppPalette.error],
            ),
            icon: Icons.delete_outline,
            label: 'Delete',
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              final effectiveType = quizType.isNotEmpty
                  ? quizType
                  : (topic == 'Image Quiz'
                      ? 'image'
                      : topic == 'Document Quiz'
                          ? 'document'
                          : 'text');
              context.go(
                effectiveType == 'text'
                    ? '/quiz-setup?type=text&topic=${Uri.encodeQueryComponent(topic)}'
                    : '/quiz-setup?type=$effectiveType',
              );
              return false;
            }

            final confirmed = await showDialog<bool>(
              context: context,
              barrierColor: Colors.black.withOpacity(0.55),
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(20),
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete this record?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'This will remove the quiz result from your device history.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPalette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppPalette.textPrimary,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppPalette.error,
                                foregroundColor: AppPalette.textPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            return confirmed ?? false;
          },
          onDismissed: (direction) async {
            if (direction != DismissDirection.endToStart) return;
            await StorageService.deleteQuizHistoryItem(hiveKey);
            _loadHistory();
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Record deleted')));
          },
          child: AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPassed
                        ? [AppPalette.success, AppPalette.primaryB]
                        : [AppPalette.error, AppPalette.glowPurple],
                  ),
                ),
                child: Center(
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              title: Text(
                item['topic'],
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score: ${item['score']}/${item['totalQuestions']}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.textSecondary,
                    ),
                  ),
                  Text(
                    AppUtils.formatDateTime(date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.textSecondary,
                    ),
                  ),
                ],
              ),
              onTap: () => context.push('/history/detail', extra: item),
              trailing: Icon(
                isPassed ? Icons.check_circle : Icons.cancel,
                color: isPassed ? AppPalette.success : AppPalette.error,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.alignment,
    required this.gradient,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final LinearGradient gradient;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppPalette.textPrimary),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppPalette.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
