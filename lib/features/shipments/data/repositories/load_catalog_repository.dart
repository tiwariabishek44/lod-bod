import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/mock/mock_delay.dart';
import '../../../../core/config/api_endpoints.dart';

class LoadCatalog {
  const LoadCatalog({
    required this.locations,
    required this.materials,
    required this.characteristics,
    required this.contacts,
  });
  final List<String> locations, materials, characteristics, contacts;
}

abstract interface class LoadCatalogRepository {
  Future<LoadCatalog> fetch();
  Future<String> saveContact(String name, String phone);
}

class MockLoadCatalogRepository implements LoadCatalogRepository {
  MockLoadCatalogRepository(this.preferences, this.ownerId);
  final SharedPreferences preferences;
  final String ownerId;
  String get _key => 'loadboard.contacts.v1.$ownerId';
  static const defaults = [
    'Ram Shrestha · 9841000001',
    'Sita Thapa · 9841000002',
    'Ramesh Yadav · 9857000002',
  ];
  @override
  Future<LoadCatalog> fetch() async {
    await waitForMockRepository();
    return _readCatalog();
  }

  LoadCatalog _readCatalog() => LoadCatalog(
    locations: const ['Kathmandu', 'Chitwan', 'Pokhara', 'Birgunj', 'Hetauda'],
    materials: const [
      'Cement',
      'Steel',
      'Electronics',
      'Gravel & Sand',
      'FMCG',
      'Other',
    ],
    characteristics: const [
      'Stackable',
      'Fragile',
      'Hazardous',
      'Perishable',
      'Liquid',
      'Oversized',
    ],
    contacts: preferences.getStringList(_key) ?? List.of(defaults),
  );
  @override
  Future<String> saveContact(String name, String phone) async {
    await waitForMockRepository();
    final item = '${name.trim()} · ${phone.trim()}';
    final contacts = _readCatalog().contacts.toList();
    if (!contacts.contains(item)) contacts.add(item);
    if (!await preferences.setStringList(_key, contacts)) {
      throw StateError('Could not save contact.');
    }
    return item;
  }
}

/// Provisional contract; adapt the payload when the backend is defined.
class ApiLoadCatalogRepository implements LoadCatalogRepository {
  ApiLoadCatalogRepository(this.client);
  final ApiClient client;
  @override
  Future<LoadCatalog> fetch() async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.loadPostOptions,
    );
    final data = Map<String, dynamic>.from(
      (response['data'] as Map?) ?? response,
    );
    List<String> list(String key) => (data[key] as List).cast<String>();
    return LoadCatalog(
      locations: list('locations'),
      materials: list('materials'),
      characteristics: list('characteristics'),
      contacts: list('contacts'),
    );
  }

  @override
  Future<String> saveContact(String name, String phone) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.contacts,
      data: {'name': name, 'phone': phone},
    );
    final data = Map<String, dynamic>.from(
      (response['data'] as Map?) ?? response,
    );
    return '${data['name']} · ${data['phone']}';
  }
}
