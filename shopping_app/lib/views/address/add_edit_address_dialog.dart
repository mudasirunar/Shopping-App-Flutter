import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_validator.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../core/utils/app_snackbar.dart';

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
  late String _selectedLabel;
  late TextEditingController _customLabelController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  String? _selectedProvince;
  late bool _isDefault;
  bool _isSaving = false;

  String? _customLabelError;
  String? _nameError;
  String? _phoneError;
  String? _streetError;
  String? _cityError;
  String? _provinceError;

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
    final existingLabel = a?.label;
    if (existingLabel != null && !_labels.contains(existingLabel)) {
      _selectedLabel = 'Other';
      _customLabelController = TextEditingController(text: existingLabel);
    } else {
      _selectedLabel = existingLabel ?? 'Home';
      _customLabelController = TextEditingController();
    }
    _nameController = TextEditingController(text: a?.recipientName ?? '');
    _phoneController = TextEditingController(text: a?.phoneNumber ?? '');
    _streetController = TextEditingController(text: a?.streetAddress ?? '');
    _cityController = TextEditingController(text: a?.city ?? '');
    _selectedProvince = a?.province;
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _customLabelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final customLabel = _customLabelController.text.trim();

    String? customLabelErr;
    if (_selectedLabel == 'Other') {
      if (customLabel.isEmpty) {
        customLabelErr = 'Please enter address label name';
      }
    }

    String? nameErr;
    if (name.isEmpty) {
      nameErr = 'Please enter recipient name';
    }

    String? phoneErr;
    if (phone.isEmpty) {
      phoneErr = 'Please enter phone number';
    } else {
      phoneErr = PhoneValidator.validate(phone);
    }

    String? streetErr;
    if (street.isEmpty) {
      streetErr = 'Please enter street address';
    }

    String? cityErr;
    if (city.isEmpty) {
      cityErr = 'Please enter city';
    }

    String? provinceErr;
    if (_selectedProvince == null || _selectedProvince!.isEmpty) {
      provinceErr = 'Please select a province';
    }

    if (customLabelErr != null || nameErr != null || phoneErr != null || streetErr != null || cityErr != null || provinceErr != null) {
      setState(() {
        _customLabelError = customLabelErr;
        _nameError = nameErr;
        _phoneError = phoneErr;
        _streetError = streetErr;
        _cityError = cityErr;
        _provinceError = provinceErr;
      });
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<AddressProvider>();
    final isOnlyAddress = widget.existingAddress == null
        ? provider.addresses.isEmpty
        : (provider.addresses.length <= 1 && (widget.existingAddress?.isDefault ?? true));
    final effectiveIsDefault = isOnlyAddress ? true : _isDefault;
    final effectiveLabel = _selectedLabel == 'Other'
        ? (customLabel.isNotEmpty ? customLabel : 'Other')
        : _selectedLabel;

    try {
      if (widget.existingAddress != null) {
        final updated = widget.existingAddress!.copyWith(
          label: effectiveLabel,
          recipientName: name,
          phoneNumber: phone,
          streetAddress: street,
          city: city,
          province: _selectedProvince!,
          isDefault: effectiveIsDefault,
        );
        await provider.updateAddress(updated);
        if (mounted) Navigator.pop(context, updated);
      } else {
        final success = await provider.addAddress(
          label: effectiveLabel,
          recipientName: name,
          phoneNumber: phone,
          streetAddress: street,
          city: city,
          province: _selectedProvince!,
          isDefault: effectiveIsDefault,
        );

        if (!success) {
          if (mounted) {
            AppSnackBar.show(
              context,
              message: 'Address limit reached (Maximum 3 addresses allowed).',
              isError: true,
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
    final addressProvider = context.watch<AddressProvider>();
    final isOnlyAddress = widget.existingAddress == null
        ? addressProvider.addresses.isEmpty
        : (addressProvider.addresses.length <= 1 && (widget.existingAddress?.isDefault ?? true));
    final effectiveDefault = isOnlyAddress ? true : _isDefault;

    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, keyboardPadding + 20),
        child: SingleChildScrollView(
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
                        if (val) {
                          setState(() {
                            _selectedLabel = label;
                            if (label != 'Other') {
                              _customLabelError = null;
                            }
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),

              if (_selectedLabel == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customLabelController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (val) {
                    if (_customLabelError != null) setState(() => _customLabelError = null);
                  },
                  decoration: InputDecoration(
                    labelText: 'Address Label Name',
                    hintText: 'e.g. Studio, Warehouse, Vacation Home',
                    prefixIcon: const Icon(Icons.bookmark_outline, size: 20),
                    errorText: _customLabelError,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Recipient Name
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                onChanged: (val) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
                decoration: InputDecoration(
                  labelText: 'Recipient Full Name',
                  hintText: 'e.g. Ahmed Khan',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  errorText: _nameError,
                ),
              ),
              const SizedBox(height: 12),

              // Phone Number (Flexible Pakistan format)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onChanged: (val) {
                  setState(() {
                    if (_phoneError != null) _phoneError = null;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: '03XXXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  errorText: _phoneError,
                  suffixIcon: PhoneValidator.isValid(_phoneController.text)
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20)
                      : null,
                ),
              ),
              const SizedBox(height: 12),

              // Street Address
              TextFormField(
                controller: _streetController,
                textInputAction: TextInputAction.next,
                onChanged: (val) {
                  if (_streetError != null) setState(() => _streetError = null);
                },
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  hintText: 'House / Apartment, Street, Area',
                  prefixIcon: const Icon(Icons.home_outlined, size: 20),
                  errorText: _streetError,
                ),
              ),
              const SizedBox(height: 12),

              // City
              TextFormField(
                controller: _cityController,
                textInputAction: TextInputAction.next,
                onChanged: (val) {
                  if (_cityError != null) setState(() => _cityError = null);
                },
                decoration: InputDecoration(
                  labelText: 'City',
                  hintText: 'e.g. Karachi',
                  prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                  errorText: _cityError,
                ),
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
                decoration: InputDecoration(
                  labelText: 'Province',
                  prefixIcon: const Icon(Icons.map_outlined, size: 20),
                  errorText: _provinceError,
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
                  setState(() {
                    _selectedProvince = val;
                    if (_provinceError != null) _provinceError = null;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Default Address Switch
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primary,
                  title: Row(
                    children: [
                      const Text(
                        'Set as default address',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      if (isOnlyAddress) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    isOnlyAddress
                        ? 'First address is automatically set as default'
                        : 'Prefill automatically during checkout',
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
                  ),
                  value: effectiveDefault,
                  onChanged: isOnlyAddress ? null : (val) => setState(() => _isDefault = val),
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
    );
  }
}
