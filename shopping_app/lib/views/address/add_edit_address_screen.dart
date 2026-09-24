import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/phone_validator.dart';
import '../../models/address.dart';
import '../../models/delivery_info.dart';
import '../../providers/address_provider.dart';

/// Full-screen view for adding or editing saved addresses or configuring
/// one-time delivery destinations.
class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? existingAddress;
  final bool isFromCheckout;
  final bool isOneTimeOnly;

  const AddEditAddressScreen({
    super.key,
    this.existingAddress,
    this.isFromCheckout = false,
    this.isOneTimeOnly = false,
  });

  /// Helper static route runner
  static Future<dynamic> open(
    BuildContext context, {
    AddressModel? existingAddress,
    bool isFromCheckout = false,
    bool isOneTimeOnly = false,
  }) {
    return Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditAddressScreen(
          existingAddress: existingAddress,
          isFromCheckout: isFromCheckout,
          isOneTimeOnly: isOneTimeOnly,
        ),
      ),
    );
  }

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  late String _selectedLabel;
  late TextEditingController _customLabelController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  String? _selectedProvince;
  late bool _isDefault;
  late bool _saveForFuture;
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

    _saveForFuture = widget.isOneTimeOnly ? false : true;

    // Check if this will be the user's only saved address
    final provider = context.read<AddressProvider>();
    final isOnlyAddress = widget.existingAddress == null
        ? provider.count == 0
        : (widget.existingAddress!.isDefault && provider.count <= 1);

    _isDefault = isOnlyAddress || (a?.isDefault ?? false);
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

  bool get _isPhoneValid => PhoneValidator.isValid(_phoneController.text);

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final customLabel = _customLabelController.text.trim();

    String? customLabelErr;
    if (_saveForFuture && _selectedLabel == 'Other') {
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

    setState(() {
      _customLabelError = customLabelErr;
      _nameError = nameErr;
      _phoneError = phoneErr;
      _streetError = streetErr;
      _cityError = cityErr;
      _provinceError = provinceErr;
    });

    if (customLabelErr != null ||
        nameErr != null ||
        phoneErr != null ||
        streetErr != null ||
        cityErr != null ||
        provinceErr != null) {
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<AddressProvider>();

    try {
      if (!_saveForFuture) {
        // One-Time Delivery Mode
        final deliveryInfo = DeliveryInfo(
          fullName: name,
          phone: phone,
          streetAddress: street,
          city: city,
          province: _selectedProvince!,
        );
        if (mounted) {
          Navigator.pop(context, deliveryInfo);
        }
        return;
      }

      final labelName = _selectedLabel == 'Other' ? customLabel : _selectedLabel;
      final isOnlyAddress = widget.existingAddress == null
          ? provider.count == 0
          : (widget.existingAddress!.isDefault && provider.count <= 1);
      final finalDefault = isOnlyAddress || _isDefault;

      if (widget.existingAddress != null) {
        // Update existing address
        final updated = widget.existingAddress!.copyWith(
          label: labelName,
          recipientName: name,
          phoneNumber: phone,
          streetAddress: street,
          city: city,
          province: _selectedProvince!,
          isDefault: finalDefault,
        );

        await provider.updateAddress(updated);
        if (mounted) {
          AppSnackBar.show(context, message: 'Address updated successfully');
          Navigator.pop(context, updated);
        }
      } else {
        // Add fresh address
        final success = await provider.addAddress(
          label: labelName,
          recipientName: name,
          phoneNumber: phone,
          streetAddress: street,
          city: city,
          province: _selectedProvince!,
          isDefault: finalDefault,
        );

        if (mounted) {
          if (success) {
            AppSnackBar.show(context, message: 'Address added successfully');
            Navigator.pop(context, provider.selectedAddress);
          } else {
            AppSnackBar.show(
              context,
              message: 'Maximum limit of ${AddressProvider.maxAddresses} addresses reached',
              isError: true,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, message: 'Failed to save address: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddressProvider>();
    final isEditing = widget.existingAddress != null;
    final isOnlyAddress = !isEditing
        ? provider.count == 0
        : (widget.existingAddress!.isDefault && provider.count <= 1);

    String pageTitle;
    if (isEditing) {
      pageTitle = 'Edit Address';
    } else if (widget.isOneTimeOnly) {
      pageTitle = 'One-Time Delivery';
    } else {
      pageTitle = 'Add New Address';
    }

    String submitButtonLabel;
    if (!_saveForFuture) {
      submitButtonLabel = 'Confirm Delivery Address';
    } else if (widget.isFromCheckout) {
      submitButtonLabel = 'Save & Deliver to this Address';
    } else {
      submitButtonLabel = isEditing ? 'Save Changes' : 'Save Address';
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Optional checkout delivery mode toggle (Save vs One-Time)
                    if (widget.isFromCheckout && !isEditing) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _saveForFuture ? AppTheme.primary.withOpacity(0.3) : AppTheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _saveForFuture,
                              activeColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setState(() {
                                  _saveForFuture = val ?? true;
                                });
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Save address for future orders',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _saveForFuture
                                        ? 'Saved to your account address book (${provider.count}/${AddressProvider.maxAddresses})'
                                        : 'One-time delivery without consuming an address slot',
                                    style: const TextStyle(fontSize: 11.5, color: AppTheme.secondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Address Label Choice Chips (Only shown when saving to account)
                    if (_saveForFuture) ...[
                      const Text(
                        'Address Label',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                                fontSize: 13,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  HapticFeedback.selectionClick();
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

                      // Dynamic extra field for 'Other' custom label
                      if (_selectedLabel == 'Other') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customLabelController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (val) {
                            if (_customLabelError != null) {
                              setState(() => _customLabelError = null);
                            }
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
                    ],

                    const Text(
                      'Contact & Delivery Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 10),

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
                    const SizedBox(height: 14),

                    // Phone Number with live checkmark
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
                        helperText: 'e.g. 03001234567, 021XXXXXXX, or +92...',
                        helperStyle: const TextStyle(fontSize: 11, color: AppTheme.secondary),
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        errorText: _phoneError,
                        suffixIcon: _isPhoneValid
                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldSuccess, size: 20)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),

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
                    const SizedBox(height: 14),

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
                    const SizedBox(height: 14),

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
                        return DropdownMenuItem<String>(
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

                    const SizedBox(height: 18),

                    // "Set as default address" switch with forced logic
                    if (_saveForFuture) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.surfaceContainerHigh),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isOnlyAddress ? Icons.lock_outline_rounded : Icons.check_circle_outline,
                                      size: 18,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Set as default address',
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: isOnlyAddress ? true : _isDefault,
                                  activeColor: AppTheme.primary,
                                  onChanged: isOnlyAddress
                                      ? null // Locked ON if it's the only address
                                      : (val) => setState(() => _isDefault = val),
                                ),
                              ],
                            ),
                            if (isOnlyAddress) ...[
                              const SizedBox(height: 2),
                              const Text(
                                'This will be your default delivery address.',
                                style: TextStyle(fontSize: 11.5, color: AppTheme.secondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Persistent bottom action bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        submitButtonLabel,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
