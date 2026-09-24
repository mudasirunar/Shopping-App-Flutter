import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/address.dart';
import '../../models/delivery_info.dart';
import '../../models/order.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/order_provider.dart';
import '../address/add_edit_address_screen.dart';
import '../main_shell.dart';
import '../orders/order_details_screen.dart';
import '../../widgets/app_network_image.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  AddressModel? _selectedAddress;
  DeliveryInfo? _oneTimeDeliveryInfo;
  bool _hasAddressValidationError = false;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      final addressProvider = context.read<AddressProvider>();
      addressProvider.loadAddresses(user?.uid).then((_) {
        if (mounted && addressProvider.addresses.isNotEmpty) {
          if (_selectedAddress == null && _oneTimeDeliveryInfo == null) {
            setState(() {
              _selectedAddress = addressProvider.selectedAddress ??
                  addressProvider.defaultAddress ??
                  addressProvider.addresses.first;
            });
          }
        }
      });
    });
  }

  Future<void> _handlePlaceOrder() async {
    if (_selectedAddress == null && _oneTimeDeliveryInfo == null) {
      setState(() => _hasAddressValidationError = true);
      AppSnackBar.show(
        context,
        message: 'Please select or add a delivery address to place your order',
        isError: true,
      );
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
    final orderProvider = context.read<OrderProvider>();

    final DeliveryInfo deliveryInfo = _selectedAddress != null
        ? _selectedAddress!.toDeliveryInfo()
        : _oneTimeDeliveryInfo!;

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
      _showSuccessDialog(newOrder);
    } else if (mounted) {
      AppSnackBar.show(
        context,
        message: orderProvider.errorMessage ?? 'Failed to place order',
        isError: true,
      );
    }
  }

  void _showSuccessDialog(OrderModel order) {
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
              'Order #${order.orderId} has been placed successfully.',
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
                        CurrencyFormatter.formatPaisa(order.totalPaisa),
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              onPressed: () {
                Navigator.pop(ctx); // dismiss dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
                );
              },
              label: const Text(
                'Track Order',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<NavigationProvider>().switchTab(0);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0)),
                  (route) => false,
                );
              },
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddAddress(BuildContext context) async {
    final result = await AddEditAddressScreen.open(context, isFromCheckout: true);
    if (!mounted) return;
    if (result is AddressModel) {
      setState(() {
        _selectedAddress = result;
        _oneTimeDeliveryInfo = null;
        _hasAddressValidationError = false;
      });
    } else if (result is DeliveryInfo) {
      setState(() {
        _oneTimeDeliveryInfo = result;
        _selectedAddress = null;
        _hasAddressValidationError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final addressProvider = context.watch<AddressProvider>();

    // Synchronize selected address with addressProvider state
    if (_selectedAddress == null && _oneTimeDeliveryInfo == null && addressProvider.addresses.isNotEmpty) {
      _selectedAddress = addressProvider.selectedAddress ??
          addressProvider.defaultAddress ??
          addressProvider.addresses.first;
    } else if (_selectedAddress != null && addressProvider.addresses.isNotEmpty) {
      final match = addressProvider.addresses.where((a) => a.id == _selectedAddress!.id).firstOrNull;
      if (match != null) {
        _selectedAddress = match;
      } else if (_oneTimeDeliveryInfo == null) {
        _selectedAddress = addressProvider.selectedAddress ??
            addressProvider.defaultAddress ??
            addressProvider.addresses.first;
      }
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: AppTheme.surface,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 116 + bottomInset),
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
            _buildDeliverySection(addressProvider),

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

  Widget _buildDeliverySection(AddressProvider addressProvider) {
    if (_selectedAddress != null) {
      return _buildSelectedAddressCard(_selectedAddress!, addressProvider);
    } else if (_oneTimeDeliveryInfo != null) {
      return _buildOneTimeDeliveryCard(_oneTimeDeliveryInfo!, addressProvider);
    } else {
      return _buildEmptyAddressCard();
    }
  }

  Widget _buildSelectedAddressCard(AddressModel address, AddressProvider addressProvider) {
    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
                    const Icon(Icons.location_on_outlined, size: 20, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Delivery Address',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppTheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.swap_horiz, size: 16, color: AppTheme.primary),
                  label: const Text(
                    'Change',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                  onPressed: () => _showAddressSelectionSheet(context, addressProvider),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.surfaceContainerHigh),
                        ),
                        child: Text(
                          address.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.success,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    address.recipientName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppTheme.secondary),
                      const SizedBox(width: 6),
                      Text(
                        address.phoneNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${address.streetAddress}, ${address.city}, ${address.province}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneTimeDeliveryCard(DeliveryInfo info, AddressProvider addressProvider) {
    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
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
                      'Delivery Address',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppTheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.swap_horiz, size: 16, color: AppTheme.primary),
                  label: const Text(
                    'Change',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                  onPressed: () => _showAddressSelectionSheet(context, addressProvider),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ONE-TIME DELIVERY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE65100),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    info.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppTheme.secondary),
                      const SizedBox(width: 6),
                      Text(
                        info.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${info.streetAddress}, ${info.city}, ${info.province}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAddressCard() {
    return Material(
      color: _hasAddressValidationError ? const Color(0xFFFFF8F8) : AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hasAddressValidationError ? AppTheme.error : AppTheme.surfaceContainerHigh,
            width: _hasAddressValidationError ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: const [
                Icon(Icons.location_on_outlined, size: 20, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Delivery Address',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_location_alt_outlined,
                color: AppTheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Delivery Address Selected',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Please add or choose where you want your items delivered.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openAddAddress(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Add Delivery Address',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressSelectionSheet(BuildContext context, AddressProvider addressProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outline.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Sheet Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Delivery Address',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${addressProvider.count} / ${AddressProvider.maxAddresses} Saved',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Address list
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            for (final addr in addressProvider.addresses)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    addressProvider.selectAddress(addr);
                                    setState(() {
                                      _selectedAddress = addr;
                                      _oneTimeDeliveryInfo = null;
                                      _hasAddressValidationError = false;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedAddress?.id == addr.id && _oneTimeDeliveryInfo == null
                                          ? AppTheme.surfaceContainerLow.withOpacity(0.6)
                                          : Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: AppTheme.surfaceContainerHigh.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Radio<String>(
                                          value: addr.id,
                                          groupValue: _oneTimeDeliveryInfo == null ? _selectedAddress?.id : null,
                                          activeColor: AppTheme.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          onChanged: (val) {
                                            addressProvider.selectAddress(addr);
                                            setState(() {
                                              _selectedAddress = addr;
                                              _oneTimeDeliveryInfo = null;
                                              _hasAddressValidationError = false;
                                            });
                                            Navigator.pop(ctx);
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    addr.label,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 13,
                                                      color: AppTheme.primary,
                                                    ),
                                                  ),
                                                  if (addr.isDefault) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFE8F5E9),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Text(
                                                        'Default',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w700,
                                                          color: AppTheme.success,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${addr.recipientName} • ${addr.phoneNumber}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${addr.streetAddress}, ${addr.city}',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppTheme.secondary,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: AppTheme.secondary,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          tooltip: 'Edit address',
                                          onPressed: () async {
                                            Navigator.pop(ctx);
                                            final updated = await AddEditAddressScreen.open(
                                              context,
                                              existingAddress: addr,
                                            );
                                            if (updated is AddressModel && mounted) {
                                              setState(() {
                                                _selectedAddress = updated;
                                                _oneTimeDeliveryInfo = null;
                                                _hasAddressValidationError = false;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Option to deliver to a temporary address (One-Time)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  final result = await AddEditAddressScreen.open(
                                    context,
                                    isFromCheckout: true,
                                    isOneTimeOnly: true,
                                  );
                                  if (!mounted) return;
                                  if (result is DeliveryInfo) {
                                    setState(() {
                                      _oneTimeDeliveryInfo = result;
                                      _selectedAddress = null;
                                      _hasAddressValidationError = false;
                                    });
                                  } else if (result is AddressModel) {
                                    setState(() {
                                      _selectedAddress = result;
                                      _oneTimeDeliveryInfo = null;
                                      _hasAddressValidationError = false;
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF3E0),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.local_shipping_outlined,
                                          size: 20,
                                          color: Color(0xFFE65100),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Deliver to a temporary address',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'One-time delivery without saving to your account',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.secondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_oneTimeDeliveryInfo != null)
                                        const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
                                      else
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.outline),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Option to add fresh new address
                            if (addressProvider.canAddMore)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    final result = await AddEditAddressScreen.open(
                                      context,
                                      isFromCheckout: true,
                                    );
                                    if (!mounted) return;
                                    if (result is AddressModel) {
                                      setState(() {
                                        _selectedAddress = result;
                                        _oneTimeDeliveryInfo = null;
                                        _hasAddressValidationError = false;
                                      });
                                    } else if (result is DeliveryInfo) {
                                      setState(() {
                                        _oneTimeDeliveryInfo = result;
                                        _selectedAddress = null;
                                        _hasAddressValidationError = false;
                                      });
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceContainerLow,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.add_rounded,
                                            size: 20,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Add New Address (${addressProvider.count}/${AddressProvider.maxAddresses})',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'Save a permanent delivery location',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.secondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.outline),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
