import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_app/models/address.dart';
import 'package:shopping_app/providers/address_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AddressModel Tests', () {
    test('Serializes to JSON and deserializes correctly', () {
      const address = AddressModel(
        id: 'addr-1',
        label: 'Home',
        recipientName: 'Ali Khan',
        phoneNumber: '03001234567',
        streetAddress: 'House 12, Street 4',
        city: 'Lahore',
        province: 'Punjab',
        isDefault: true,
      );

      final json = address.toJson();
      final deserialized = AddressModel.fromJson(json);

      expect(deserialized.id, 'addr-1');
      expect(deserialized.label, 'Home');
      expect(deserialized.recipientName, 'Ali Khan');
      expect(deserialized.phoneNumber, '03001234567');
      expect(deserialized.streetAddress, 'House 12, Street 4');
      expect(deserialized.city, 'Lahore');
      expect(deserialized.province, 'Punjab');
      expect(deserialized.isDefault, true);
    });

    test('Converts correctly to DeliveryInfo', () {
      const address = AddressModel(
        id: 'addr-2',
        label: 'Office',
        recipientName: 'Sara Ahmed',
        phoneNumber: '03219876543',
        streetAddress: 'Floor 3, Tech Hub',
        city: 'Islamabad',
        province: 'Islamabad Capital Territory',
        isDefault: false,
      );

      final deliveryInfo = address.toDeliveryInfo();
      expect(deliveryInfo.fullName, 'Sara Ahmed');
      expect(deliveryInfo.phone, '03219876543');
      expect(deliveryInfo.streetAddress, 'Floor 3, Tech Hub');
      expect(deliveryInfo.city, 'Islamabad');
      expect(deliveryInfo.province, 'Islamabad Capital Territory');
    });
  });

  group('AddressProvider Tests', () {
    test('First address automatically becomes default', () async {
      final provider = AddressProvider();

      final added = await provider.addAddress(
        label: 'Home',
        recipientName: 'Ali Khan',
        phoneNumber: '03001234567',
        streetAddress: 'House 1, Street 1',
        city: 'Lahore',
        province: 'Punjab',
        isDefault: false, // passed false, but should be forced true
      );

      expect(added, true);
      expect(provider.count, 1);
      expect(provider.addresses.first.isDefault, true);
      expect(provider.defaultAddress?.id, provider.addresses.first.id);
    });

    test('Strictly enforces maximum 3 addresses limit', () async {
      final provider = AddressProvider();

      // Add 1
      await provider.addAddress(
        label: 'Home',
        recipientName: 'Person 1',
        phoneNumber: '03001111111',
        streetAddress: 'Street 1',
        city: 'Lahore',
        province: 'Punjab',
      );

      // Add 2
      await provider.addAddress(
        label: 'Work',
        recipientName: 'Person 2',
        phoneNumber: '03002222222',
        streetAddress: 'Street 2',
        city: 'Karachi',
        province: 'Sindh',
      );

      // Add 3
      await provider.addAddress(
        label: 'Other',
        recipientName: 'Person 3',
        phoneNumber: '03003333333',
        streetAddress: 'Street 3',
        city: 'Islamabad',
        province: 'Islamabad Capital Territory',
      );

      expect(provider.count, 3);
      expect(provider.canAddMore, false);

      // Attempt Add 4 -> should reject
      final rejected = await provider.addAddress(
        label: 'Warehouse',
        recipientName: 'Person 4',
        phoneNumber: '03004444444',
        streetAddress: 'Street 4',
        city: 'Multan',
        province: 'Punjab',
      );

      expect(rejected, false);
      expect(provider.count, 3);
    });

    test('Changing default address unsets previous default', () async {
      final provider = AddressProvider();

      await provider.addAddress(
        label: 'Home',
        recipientName: 'Person 1',
        phoneNumber: '03001111111',
        streetAddress: 'Street 1',
        city: 'Lahore',
        province: 'Punjab',
      );

      await provider.addAddress(
        label: 'Work',
        recipientName: 'Person 2',
        phoneNumber: '03002222222',
        streetAddress: 'Street 2',
        city: 'Karachi',
        province: 'Sindh',
      );

      final secondId = provider.addresses[1].id;
      await provider.setDefaultAddress(secondId);

      expect(provider.addresses[0].isDefault, false);
      expect(provider.addresses[1].isDefault, true);
      expect(provider.defaultAddress?.id, secondId);
    });

    test('Deleting default address promotes remaining address to default', () async {
      final provider = AddressProvider();

      await provider.addAddress(
        label: 'Home',
        recipientName: 'Person 1',
        phoneNumber: '03001111111',
        streetAddress: 'Street 1',
        city: 'Lahore',
        province: 'Punjab',
      );

      await provider.addAddress(
        label: 'Work',
        recipientName: 'Person 2',
        phoneNumber: '03002222222',
        streetAddress: 'Street 2',
        city: 'Karachi',
        province: 'Sindh',
      );

      final firstId = provider.addresses[0].id;
      await provider.deleteAddress(firstId);

      expect(provider.count, 1);
      expect(provider.addresses.first.isDefault, true);
    });
  });
}
