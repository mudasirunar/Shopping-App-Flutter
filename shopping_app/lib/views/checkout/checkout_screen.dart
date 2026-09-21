import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/phone_validator.dart';
import '../../models/address.dart';
import '../../models/delivery_info.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../address/add_edit_address_dialog.dart';
import '../orders/order_history_screen.dart';
import '../../widgets/app_network_image.dart';
import '../../core/utils/app_snackbar.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedProvince;

  bool _isPlacingOrder = false;
  bool _saveAddressForFuture = true;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      final addressProvider = context.read<AddressProvider>();
      addressProvider.loadAddresses(user?.uid).then((_) {
        if (mounted && addressProvider.addresses.isNotEmpty) {
          final def = addressProvider.selectedAddress ?? addressProvider.defaultAddress;
          if (def != null) {
            _populateFromAddress(def);
          }
        }
      });
    });
  }

  void _populateFromAddress(AddressModel address) {
    setState(() {
      _nameController.text = address.recipientName;
      _phoneController.text = address.phoneNumber;
      _addressController.text = address.streetAddress;
      _cityController.text = address.city;
      _selectedProvince = _provinces.contains(address.province) ? address.province : null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool get _isPhoneValid => PhoneValidator.isValidPakistanMobile(_phoneController.text);

  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate() || _selectedProvince == null) {
      return;
    }

    final cart = context.read<CartProvider>();
    if (cart.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Your cart is empty!',
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    final auth = context.read<AuthProvider>();
    final addressProvider = context.read<AddressProvider>();
    final orderProvider = context.read<OrderProvider>();

    // Auto-save address if requested or if first address
    if ((addressProvider.addresses.isEmpty || _saveAddressForFuture) && addressProvider.canAddMore) {
      final alreadyExists = addressProvider.addresses.any(
        (a) =>
            a.streetAddress.trim().toLowerCase() == _addressController.text.trim().toLowerCase() &&
            a.city.trim().toLowerCase() == _cityController.text.trim().toLowerCase(),
      );
      if (!alreadyExists) {
        await addressProvider.addAddress(
          label: 'Home',
          recipientName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          streetAddress: _addressController.text.trim(),
          city: _cityController.text.trim(),
          province: _selectedProvince!,
          isDefault: addressProvider.addresses.isEmpty,
        );
      }
    }

    final deliveryInfo = DeliveryInfo(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      streetAddress: _addressController.text.trim(),
      city: _cityController.text.trim(),
      province: _selectedProvince!,
    );

    final newOrder = await orderProvider.placeOrder(
      userId: auth.currentUser?.uid,
      items: cart.items,
      deliveryInfo: deliveryInfo,
      subtotalPaisa: cart.subtotalPaisa,
      deliveryFeePaisa: cart.deliveryFeePaisa,
      totalPaisa: cart.totalPaisa,
    );

    setState(() => _isPlacingOrder = false);

    if (newOrder != null && mounted) {
      await cart.clearCart();
      _showSuccessDialog(newOrder.id, newOrder.totalPaisa);
    } else if (mounted) {
      AppSnackBar.show(
        context,
        message: orderProvider.errorMessage ?? 'Failed to place order',
        isError: true,
      );
    }
  }

  void _showSuccessDialog(String orderId, int totalPaisa) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.emeraldContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppTheme.emeraldSuccess,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Confirmed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Order #$orderId has been placed successfully.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.secondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Payment Mode:', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                      Text('Cash on Delivery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Due on Arrival:', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                      Text(
                        CurrencyFormatter.formatPaisa(totalPaisa),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx); // dismiss dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
              },
              child: const Text('View Order History'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // back to catalog
              },
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Stepper Tracker
              _buildStepper(),

              const SizedBox(height: 12),

              // Payment Notice Banner
              _buildPaymentNoticeBanner(),

              const SizedBox(height: 16),

              // Delivery Information Card
              _buildDeliveryForm(),

              const SizedBox(height: 16),

              // Payment Method Section
              _buildPaymentMethod(),

              const SizedBox(height: 16),

              // Compact Order Summary Card
              _buildOrderSummary(cart),

              const SizedBox(height: 16),

              // Trust Seals
              _buildTrustSeals(),
            ],
          ),
        ),
      ),

      // Sticky Bottom Footer
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount Due on Arrival:',
                  style: TextStyle(fontSize: 12, color: AppTheme.secondary),
                ),
                Text(
                  CurrencyFormatter.formatPaisa(cart.totalPaisa),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
              child: _isPlacingOrder
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.local_shipping_outlined, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Place Order · Cash on Delivery',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle, size: 16, color: AppTheme.emeraldSuccess),
              SizedBox(width: 4),
              Text(
                'Cart',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondary),
              ),
            ],
          ),
          Container(width: 24, height: 1, color: AppTheme.surfaceContainerHighest),
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('2', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Delivery & Pay',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
              ),
            ],
          ),
          Container(width: 24, height: 1, color: AppTheme.surfaceContainerHighest),
          Row(
            children: const [
              Icon(Icons.radio_button_unchecked, size: 16, color: AppTheme.outline),
              SizedBox(width: 4),
              Text(
                'Confirmed',
                style: TextStyle(fontSize: 12, color: AppTheme.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.verified_user_outlined, size: 20, color: AppTheme.primary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash on Delivery',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
                SizedBox(height: 2),
                Text(
                  'Pay securely with cash upon delivery of your parcel at your doorstep.',
                  style: TextStyle(fontSize: 11, color: AppTheme.secondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryForm() {
    final addressProvider = context.watch<AddressProvider>();
    final addresses = addressProvider.addresses;
    final selected = addressProvider.selectedAddress;

    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.02),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.location_on_outlined, size: 20, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Delivery Information',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                  ),
                ],
              ),
              if (addresses.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.swap_horiz, size: 16, color: AppTheme.primary),
                  label: Text('Addresses (${addresses.length}/3)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  onPressed: () => _showAddressPicker(context, addressProvider),
                ),
            ],
          ),

          // If addresses exist, show quick-select chips bar
          if (addresses.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final addr in addresses)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: selected?.id == addr.id,
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.surfaceContainerLow,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              addr.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected?.id == addr.id ? FontWeight.w700 : FontWeight.w500,
                                color: selected?.id == addr.id ? Colors.white : AppTheme.secondary,
                              ),
                            ),
                            if (addr.isDefault) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.star,
                                size: 12,
                                color: selected?.id == addr.id ? Colors.amberAccent : AppTheme.primary,
                              ),
                            ],
                          ],
                        ),
                        onSelected: (val) {
                          if (val) {
                            addressProvider.selectAddress(addr);
                            _populateFromAddress(addr);
                          }
                        },
                      ),
                    ),
                  if (addressProvider.canAddMore)
                    ActionChip(
                      backgroundColor: AppTheme.surfaceContainerLowest,
                      side: const BorderSide(color: AppTheme.primary, width: 1),
                      avatar: const Icon(Icons.add, size: 14, color: AppTheme.primary),
                      label: const Text('+ New', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                      onPressed: () async {
                        final newAddr = await AddEditAddressDialog.show(context);
                        if (newAddr != null) {
                          _populateFromAddress(newAddr);
                        }
                      },
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Full Name
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Recipient Full Name',
              hintText: 'Enter recipient name',
              prefixIcon: Icon(Icons.person_outline, size: 20, color: AppTheme.secondary),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter recipient name' : null,
          ),

          const SizedBox(height: 12),

          // Mobile Number with live Pakistan validation
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Mobile Contact',
              hintText: '03001234567',
              helperText: '11-digit Pakistan mobile starting with 03',
              helperStyle: const TextStyle(fontSize: 11, color: AppTheme.secondary),
              prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppTheme.secondary),
              suffixIcon: _isPhoneValid
                  ? const Icon(Icons.check_circle, color: AppTheme.emeraldSuccess, size: 20)
                  : null,
            ),
            validator: (val) => PhoneValidator.validate(val),
          ),

          const SizedBox(height: 12),

          // Street Address
          TextFormField(
            controller: _addressController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Street Address',
              hintText: 'House / Flat, Street, Area',
              prefixIcon: Icon(Icons.home_outlined, size: 20, color: AppTheme.secondary),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter address' : null,
          ),

          const SizedBox(height: 12),

          // City
          TextFormField(
            controller: _cityController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'City',
              hintText: 'e.g. Lahore, Karachi, Islamabad',
              prefixIcon: Icon(Icons.location_city_outlined, size: 20, color: AppTheme.secondary),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter city' : null,
          ),

          const SizedBox(height: 12),

          // Province Dropdown (Full width, isExpanded to prevent any overflow)
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
              prefixIcon: Icon(Icons.map_outlined, size: 20, color: AppTheme.secondary),
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
              setState(() => _selectedProvince = val);
            },
            validator: (val) => (val == null || val.isEmpty) ? 'Please select a province' : null,
          ),

          // Save address checkbox if user can add more
          if (addressProvider.canAddMore) ...[
            const SizedBox(height: 8),
            Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primary,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Save this delivery address for future orders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                value: _saveAddressForFuture,
                onChanged: (val) => setState(() => _saveAddressForFuture = val ?? true),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  void _showAddressPicker(BuildContext context, AddressProvider addressProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Delivery Address',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                        Text('${addressProvider.count} / 3 Saved', style: const TextStyle(fontSize: 12, color: AppTheme.secondary)),
                      ],
                    ),
                  ),
                  for (final addr in addressProvider.addresses)
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: Icon(
                          addr.isDefault ? Icons.star : Icons.location_on_outlined,
                          color: addr.isDefault ? Colors.amber[700] : AppTheme.primary,
                        ),
                        title: Row(
                          children: [
                            Text(addr.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            if (addr.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.success)),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text('${addr.recipientName} • ${addr.streetAddress}, ${addr.city}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: addressProvider.selectedAddress?.id == addr.id
                            ? const Icon(Icons.check, color: AppTheme.primary)
                            : null,
                        onTap: () {
                          addressProvider.selectAddress(addr);
                          _populateFromAddress(addr);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  if (addressProvider.canAddMore) ...[
                    const Divider(),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                        title: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final newAddr = await AddEditAddressDialog.show(context);
                          if (newAddr != null) {
                            _populateFromAddress(newAddr);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.payments_outlined, size: 20, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                'Payment Method',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active Cash on Delivery Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryContainer, width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.circle, size: 8, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cash on Delivery',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'No Surcharge',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pay in cash upon package arrival at your doorstep. Please keep exact change ready.',
                        style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Disabled Card Gateway Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.credit_card_off_outlined, size: 20, color: AppTheme.outline),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debit / Credit Card Gateway',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondary),
                      ),
                      Text(
                        'Service not available',
                        style: TextStyle(fontSize: 10, color: AppTheme.outline),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.lock_outline, size: 16, color: AppTheme.outline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
              ),
              Text(
                '${cart.items.length} ${cart.items.length == 1 ? 'item' : 'items'}',
                style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Item preview rows
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  AppNetworkImage(
                    imageUrl: item.product.image,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(6),
                    category: item.product.category,
                    iconSize: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'x${item.quantity}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    CurrencyFormatter.formatPaisa(item.subtotalPaisa),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),

          // Calculations
          _calcRow('Subtotal', CurrencyFormatter.formatPaisa(cart.subtotalPaisa)),
          const SizedBox(height: 6),
          _calcRow(
            'Shipping',
            cart.isFreeDeliveryUnlocked ? 'Free' : CurrencyFormatter.formatPaisa(cart.deliveryFeePaisa),
            isHighlighted: cart.isFreeDeliveryUnlocked,
          ),
          const SizedBox(height: 6),
          _calcRow('Payment Surcharge', CurrencyFormatter.formatPaisa(0)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                CurrencyFormatter.formatPaisa(cart.totalPaisa),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calcRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.secondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isHighlighted ? AppTheme.emeraldSuccess : AppTheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTrustSeals() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _Seal(icon: Icons.shield_outlined, title: 'Protected Checkout'),
          _Seal(icon: Icons.autorenew, title: '7-Day Returns'),
          _Seal(icon: Icons.support_agent_outlined, title: 'Live Courier Track'),
        ],
      ),
    );
  }
}

class _Seal extends StatelessWidget {
  final IconData icon;
  final String title;

  const _Seal({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: AppTheme.secondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
