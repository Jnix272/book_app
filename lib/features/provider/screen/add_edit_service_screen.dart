import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_theme.dart';
import '../../../domain/models/models.dart';
import '../../../providers/provider_dashboard_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/auth_widgets.dart';

class AddEditServiceScreen extends ConsumerStatefulWidget {
  final ServiceItem? service;
  const AddEditServiceScreen({super.key, this.service});

  @override
  ConsumerState<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends ConsumerState<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?.name ?? '');
    _descCtrl = TextEditingController(text: widget.service?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.service?.price.toStringAsFixed(0) ?? '',
    );
    _durationCtrl = TextEditingController(
      text: widget.service?.durationMin.toString() ?? '30',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final providerId = ref.read(currentProviderIdProvider);
      if (providerId == null) throw Exception("User not authenticated.");

      final finalPrice = double.tryParse(_priceCtrl.text) ?? 0.0;
      final finalDuration = int.tryParse(_durationCtrl.text) ?? 30;

      final payload = {
        'provider_id': providerId,
        'service_name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': finalPrice,
        'duration_minutes': finalDuration,
      };

      if (widget.service == null) {
        // Create
        await ref.read(providerRepositoryProvider).addService(payload);
      } else {
        // Update
        await ref.read(providerRepositoryProvider).updateService(widget.service!.id, payload);
      }

      if (mounted) {
        Navigator.pop(context, true); // Signal success to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save service: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.service != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Service' : 'New Service',
          style: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        shape: const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthTextField(
                controller: _nameCtrl,
                focusNode: FocusNode(),
                label: 'Service Name',
                hint: 'e.g. Deep Cut',
                validator: Validators.required('Service Name'),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                controller: _descCtrl,
                label: 'Description (Optional)',
                hint: 'Describe what this service includes...',
                textInputAction: TextInputAction.newline,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      controller: _priceCtrl,
                      focusNode: FocusNode(),
                      label: 'Price (\$)',
                      hint: '0',
                      validator: Validators.required('Price'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AuthTextField(
                      controller: _durationCtrl,
                      focusNode: FocusNode(),
                      label: 'Duration (Min)',
                      hint: '30',
                      validator: Validators.required('Duration'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              AuthButton(
                isEditing ? 'Save Changes' : 'Create Service',
                onTap: _saveService,
                isLoading: _isSaving,
                color: AppColors.sage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
