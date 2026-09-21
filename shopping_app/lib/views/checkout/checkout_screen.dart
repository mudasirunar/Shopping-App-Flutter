import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/phone_validator.dart';
import '../../models/delivery_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../orders/order_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Bilal Ahmed');
  final _phoneController = TextEditingController(text: '03001234567');
  final _addressController = TextEditingController(text: 'House 42, Street 5, Block 4');
  final _cityController = TextEditingController(text: 'Karachi');
  final _provinceController = TextEditingController(text: 'Sindh 75600');

  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  bool get _isPhoneValid => PhoneValidator.isValidPakistanMobile(_phoneController.text);

  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cart = context.read<CartProvider>();
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty!')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    final auth = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    final deliveryInfo = DeliveryInfo(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      streetAddress: _addressController.text.trim(),
      city: _cityController.text.trim(),
      province: _provinceController.text.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Failed to place order'),
          backgroundColor: AppTheme.error,
        ),
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
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
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
              Icon(Icons.location_on_outlined, size: 20, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                'Delivery Information',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Full Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline, size: 20, color: AppTheme.secondary),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter recipient name' : null,
          ),

          const SizedBox(height: 12),

          // Mobile Number with live validation
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Mobile Contact',
              hintText: '03001234567',
              helperText: 'Enter 11-digit Pakistan mobile (e.g. 03001234567)',
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
            decoration: const InputDecoration(
              labelText: 'Street Address',
              hintText: 'House/flat, street, area',
              prefixIcon: Icon(Icons.home_outlined, size: 20, color: AppTheme.secondary),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter address' : null,
          ),

          const SizedBox(height: 12),

          // City and Province Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined, size: 20, color: AppTheme.secondary),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter city' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _provinceController,
                  decoration: const InputDecoration(
                    labelText: 'Province / Postal',
                    prefixIcon: Icon(Icons.map_outlined, size: 20, color: AppTheme.secondary),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter province' : null,
                ),
              ),
            ],
          ),
        ],
      ),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Image.network(
                        item.product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 16),
                      ),
                    ),
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
