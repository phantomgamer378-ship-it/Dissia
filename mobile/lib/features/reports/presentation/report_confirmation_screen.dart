import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/sanket_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/reports_repository.dart';

class ReportConfirmationScreen extends ConsumerStatefulWidget {
  final String reportId;
  const ReportConfirmationScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportConfirmationScreen> createState() => _ReportConfirmationScreenState();
}

class _ReportConfirmationScreenState extends ConsumerState<ReportConfirmationScreen> {
  Map<String, dynamic>? _receipt;
  bool _isLoading = true;
  

  @override
  void initState() {
    super.initState();
    _fetchReceipt();
  }

  Future<void> _fetchReceipt() async {
    setState(() {
      _isLoading = true;
      
    });
    try {
      final res = await ref.read(reportsRepositoryProvider).getReceipt(widget.reportId);
      if (mounted) {
        setState(() {
          _receipt = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report Confirmation'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Report Submitted to SANKET AI',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your report has been received and queued in durable emergency storage.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Receipt ID', style: TextStyle(color: AppColors.textSecondary)),
                                StatusBadge.fromStatus(_receipt?['status'] ?? 'QUEUED'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: widget.reportId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Receipt ID copied to clipboard')),
                                );
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.reportId,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.copy, size: 16, color: AppColors.accent),
                                ],
                              ),
                            ),
                            if (_receipt?['received_at'] != null) ...[
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Received At', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  Text(
                                    _receipt!['received_at'].toString().substring(0, 19).replaceAll('T', ' '),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    SanketButton(
                      text: 'Refresh Status',
                      icon: Icons.refresh,
                      variant: ButtonVariant.secondary,
                      onPressed: _fetchReceipt,
                    ),
                    const SizedBox(height: 12),
                    SanketButton(
                      text: 'View Report Details',
                      onPressed: () => context.go(RoutePaths.reportDetailsFor(widget.reportId)),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go(RoutePaths.home),
                      child: const Text('Return to Dashboard'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
