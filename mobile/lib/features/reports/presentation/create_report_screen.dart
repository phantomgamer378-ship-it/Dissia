import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../offline/draft_store/draft_model.dart';
import '../../../offline/draft_store/draft_repository.dart';
import '../../../shared/widgets/sanket_button.dart';
import '../data/reports_repository.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  int _currentStep = 0;
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  String? _selectedCategory;
  bool _aiConsent = true;
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;
  final List<XFile> _attachments = [];
  final _picker = ImagePicker();

  final _categories = [
    'Flood / Waterlogging',
    'Fire Incident',
    'Medical Emergency',
    'Structural Collapse',
    'Landslide',
    'Hazardous Material',
    'Other / General',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDeviceLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled on device.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission was denied.')),
            );
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (_locCtrl.text.isEmpty) {
          _locCtrl.text = 'GPS: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not obtain location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (img != null) {
        setState(() => _attachments.add(img));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (img != null) {
        setState(() => _attachments.add(img));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')),
        );
      }
    }
  }

  Future<void> _saveAsDraft() async {
    final draft = ReportDraft(
      id: const Uuid().v4(),
      description: _descCtrl.text.trim(),
      location: _locCtrl.text.trim().isEmpty ? null : _locCtrl.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      aiConsent: _aiConsent,
      localAttachmentPaths: _attachments.map((a) => a.path).toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: 'draft',
    );
    await ref.read(draftRepositoryProvider).saveDraft(draft);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved to local drafts.')),
      );
      context.pop();
    }
  }

  Future<void> _handleSubmit() async {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the emergency incident.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final isOnline = ref.read(isOnlineProvider);
    final idempotencyKey = const Uuid().v4();

    if (!isOnline) {
      // Offline: queue draft for sync
      final draft = ReportDraft(
        id: idempotencyKey,
        description: _descCtrl.text.trim(),
        location: _locCtrl.text.trim().isEmpty ? null : _locCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        aiConsent: _aiConsent,
        localAttachmentPaths: _attachments.map((a) => a.path).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: 'pending_sync',
      );
      await ref.read(draftRepositoryProvider).saveDraft(draft);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device is offline. Report queued for automatic synchronization.'),
            backgroundColor: AppColors.warning,
          ),
        );
        if (mounted) context.go(RoutePaths.reportSync);
      }
      return;
    }

    try {
      final res = await ref.read(reportsRepositoryProvider).submitReport(
            description: _descCtrl.text.trim(),
            location: _locCtrl.text.trim().isEmpty ? null : _locCtrl.text.trim(),
            aiConsent: _aiConsent,
            idempotencyKey: idempotencyKey,
          );

      if (mounted && res != null) {
        final receiptId = res['receipt_id'] as String;
        context.go(RoutePaths.reportConfirmationFor(receiptId));
      }
    } catch (e) {
      // If error occurs, offer to save offline
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e. Saving offline draft.'),
            backgroundColor: AppColors.error,
          ),
        );
        final draft = ReportDraft(
          id: idempotencyKey,
          description: _descCtrl.text.trim(),
          location: _locCtrl.text.trim().isEmpty ? null : _locCtrl.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          aiConsent: _aiConsent,
          localAttachmentPaths: _attachments.map((a) => a.path).toList(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          syncStatus: 'failed',
          lastError: e.toString(),
        );
        await ref.read(draftRepositoryProvider).saveDraft(draft);
        if (mounted) context.go(RoutePaths.reportSync);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Emergency Report'),
        actions: [
          TextButton(
            onPressed: _saveAsDraft,
            child: const Text('Save Draft'),
          ),
        ],
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        elevation: 0,
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() => _currentStep += 1);
          } else {
            _handleSubmit();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            context.pop();
          }
        },
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 3;
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                Expanded(
                  child: SanketButton(
                    text: isLast ? 'Submit Report' : 'Continue',
                    icon: isLast ? Icons.send : Icons.arrow_forward,
                    isLoading: _isSubmitting,
                    onPressed: details.onStepContinue,
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: SanketButton(
                      text: 'Back',
                      variant: ButtonVariant.secondary,
                      onPressed: details.onStepCancel,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Incident'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Describe the Emergency',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Provide clear observations of what happened, people involved, and urgent risks.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category (Optional)',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Situation Description *',
                    hintText: 'e.g. Rising flood water near Bridge 4, multiple families trapped on rooftop...',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Location'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Incident Location', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Specify landmarks, building names, cross streets, or acquire device GPS.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _locCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location / Landmark Description',
                    hintText: 'e.g. Sector 12, Main Market Road behind City Hospital',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SanketButton(
                  text: _isGettingLocation ? 'Detecting GPS...' : 'Use Current Device Location',
                  icon: Icons.my_location,
                  variant: ButtonVariant.secondary,
                  isLoading: _isGettingLocation,
                  onPressed: _fetchDeviceLocation,
                ),
                if (_latitude != null && _longitude != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'GPS Coordinates: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Step(
            title: const Text('Evidence'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Supporting Evidence', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Attach images or video captures to aid coordinator verification.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SanketButton(
                        text: 'Take Photo',
                        icon: Icons.camera_alt_outlined,
                        variant: ButtonVariant.secondary,
                        onPressed: _takePhoto,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SanketButton(
                        text: 'Gallery',
                        icon: Icons.photo_library_outlined,
                        variant: ButtonVariant.secondary,
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_attachments.isNotEmpty) ...[
                  Text(
                    'Attached Files (${_attachments.length}):',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _attachments.asMap().entries.map((entry) {
                      final i = entry.key;
                      final file = entry.value;
                      return Chip(
                        label: Text(file.name, overflow: TextOverflow.ellipsis),
                        onDeleted: () => setState(() => _attachments.removeAt(i)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 3,
            state: StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review & Submit', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DESCRIPTION', style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_descCtrl.text.isEmpty ? 'No description' : _descCtrl.text, style: const TextStyle(fontSize: 14)),
                        const Divider(height: 24),
                        const Text('LOCATION', style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_locCtrl.text.isEmpty ? 'Not specified' : _locCtrl.text, style: const TextStyle(fontSize: 14)),
                        if (_attachments.isNotEmpty) ...[
                          const Divider(height: 24),
                          const Text('ATTACHMENTS', style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${_attachments.length} file(s) attached', style: const TextStyle(fontSize: 14)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('AI Assistance Consent'),
                  subtitle: const Text('Allow SANKET AI to extract entities, urgency, and candidate incidents.'),
                  value: _aiConsent,
                  onChanged: (val) => setState(() => _aiConsent = val),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
