import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_validator.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';

class AddEditAddressDialog extends StatefulWidget {
  final AddressModel? existingAddress;

  const AddEditAddressDialog({super.key, this.existingAddress});

  static Future<AddressModel?> show(BuildContext context, {AddressModel? existingAddress}) {
    return showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditAddressDialog(existingAddress: existingAddress),
    );
  }

  @override
  State<AddEditAddressDialog> createState() => _AddEditAddressDialogState();
}

class _AddEditAddressDialogState extends State<AddEditAddressDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedLabel;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  String? _selectedProvince;
  late bool _isDefault;
  bool _isSaving = false;

  final List<String> _labels = ['Home', 'Work', 'Other'];
  final List<String> _provinces = [
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Islamabad Capital Territory',
    'Azad Jammu & Kashmir',
    'Gilgit-Baltistan',
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.existingAddress;
    _selectedLabel = a?.label ?? 'Home';
    _nameController = TextEditingController(text: a?.recipientName ?? '');
    _phoneController = TextEditingController(text: a?.phoneNumber ?? '');
    _streetController = TextEditingController(text: a?.streetAddress ?? '');
    _cityController = TextEditingController(text: a?.city ?? '');
    _selectedProvince = a?.province;
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedProvince == null) return;

    setState(() => _isSaving = true);
    final provider = context.read<AddressProvider>();

    try {
      if (widget.existingAddress != null) {
        final updated = widget.existingAddress!.copyWith(
          label: _selectedLabel,
          recipientName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          streetAddress: _streetController.text.trim(),
          city: _cityController.text.trim(),
          province: _selectedProvince!,
          isDefault: _isDefault,
        );
        await provider.updateAddress(updated);
        if (mounted) Navigator.pop(context, updated);
      } else {
        final success = await provider.addAddress(
          label: _selectedLabel,
          recipientName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          streetAddress: _streetController.text.trim(),
          city: _cityController.text.trim(),
          province: _selectedProvince!,
          isDefault: _isDefault,
        );

        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Address limit reached (Maximum 3 addresses allowed).'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
          return;
        }

        if (mounted) {
          Navigator.pop(context, provider.selectedAddress);
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAddress != null;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, keyboardPadding + 20),
        child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Address' : 'Add New Address',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.secondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Label Chips (Home, Work, Other)
              Row(
                children: _labels.map((label) {
                  final isSelected = _selectedLabel == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: AppTheme.surfaceContainerLow,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.secondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedLabel = label);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Recipient Name
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Recipient Full Name',
                  hintText: 'e.g. Mudasir Ali',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter recipient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Phone Number (Pakistan 03XXXXXXXXX)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: '03XXXXXXXXX (11 digits)',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  suffixIcon: PhoneValidator.isValidPakistanMobile(_phoneController.text)
                      ? const Icon(Icons.check_circle, color: AppTheme.success, size: 18)
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (!PhoneValidator.isValidPakistanMobile(val)) {
                    return 'Must be an 11-digit Pakistani number starting with 03';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Street Address
              TextFormField(
                controller: _streetController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  hintText: 'House / Apartment, Street, Area',
                  prefixIcon: Icon(Icons.home_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter street address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // City
              TextFormField(
                controller: _cityController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'e.g. Lahore, Karachi, Islamabad',
                  prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Province Dropdown
              DropdownButtonFormField<String>(
                value: _selectedProvince,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary, size: 22),
                dropdownColor: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                elevation: 3,
                hint: const Text(
                  'Select Province',
                  style: TextStyle(fontSize: 14, color: AppTheme.secondary),
                ),
                decoration: const InputDecoration(
                  labelText: 'Province',
                  prefixIcon: Icon(Icons.map_outlined, size: 20),
                ),
                items: _provinces.map((prov) {
                  return DropdownMenuItem(
                    value: prov,
                    child: Text(
                      prov,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primary),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedProvince = val);
                },
                validator: (val) => (val == null || val.isEmpty) ? 'Please select a province' : null,
              ),
              const SizedBox(height: 12),

              // Default Address Switch
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primary,
                  title: const Text('Set as default address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Prefill automatically during checkout', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                  value: _isDefault,
                  onChanged: (val) => setState(() => _isDefault = val),
                ),
              ),
              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEditing ? 'Save Changes' : 'Add Address', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
