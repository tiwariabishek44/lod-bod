enum LoadType { normal, contract }

enum LoadPostStatus { draft, submitted }

enum LoadTimeWindow { morning, afternoon, evening, fullDay }

extension LoadTimeWindowPresentation on LoadTimeWindow {
  String get label => switch (this) {
    LoadTimeWindow.morning => 'Morning',
    LoadTimeWindow.afternoon => 'Afternoon',
    LoadTimeWindow.evening => 'Evening',
    LoadTimeWindow.fullDay => 'Full day',
  };

  String get hours => switch (this) {
    LoadTimeWindow.morning => '06–12',
    LoadTimeWindow.afternoon => '12–18',
    LoadTimeWindow.evening => '15–20',
    LoadTimeWindow.fullDay => '06–20',
  };

  int get startHour => switch (this) {
    LoadTimeWindow.morning || LoadTimeWindow.fullDay => 6,
    LoadTimeWindow.afternoon => 12,
    LoadTimeWindow.evening => 15,
  };

  int get endHour => switch (this) {
    LoadTimeWindow.morning => 12,
    LoadTimeWindow.afternoon => 18,
    LoadTimeWindow.evening || LoadTimeWindow.fullDay => 20,
  };

  DateTime atStartOf(DateTime date) =>
      DateTime(date.year, date.month, date.day, startHour);

  DateTime atEndOf(DateTime date) =>
      DateTime(date.year, date.month, date.day, endHour);
}

enum TruckVehicleType { open, closed, trailer, container, tipper, tanker }

extension TruckVehicleTypePresentation on TruckVehicleType {
  String get label => switch (this) {
    TruckVehicleType.open => 'Open',
    TruckVehicleType.closed => 'Closed',
    TruckVehicleType.trailer => 'Trailer',
    TruckVehicleType.container => 'Cont.',
    TruckVehicleType.tipper => 'Tipper',
    TruckVehicleType.tanker => 'Tanker',
  };
}

enum TruckWheelClass { tenW, twelveW, fourteenW }

extension TruckWheelClassPresentation on TruckWheelClass {
  String get label => switch (this) {
    TruckWheelClass.tenW => '10W',
    TruckWheelClass.twelveW => '12W',
    TruckWheelClass.fourteenW => '14W',
  };
}

enum CapacityMatch { exact, orAbove }

extension CapacityMatchPresentation on CapacityMatch {
  String get label => switch (this) {
    CapacityMatch.exact => 'Exact',
    CapacityMatch.orAbove => 'Or above',
  };
}

enum TruckBillingType { vat, nonVat }

extension TruckBillingTypePresentation on TruckBillingType {
  String get label => switch (this) {
    TruckBillingType.vat => 'VAT bill',
    TruckBillingType.nonVat => 'Non-VAT',
  };
}

class LoadLocation {
  const LoadLocation({
    required this.name,
    this.address,
    this.region,
    this.country = 'Nepal',
    this.latitude,
    this.longitude,
  });

  final String name;
  final String? address;
  final String? region;
  final String country;
  final double? latitude;
  final double? longitude;

  Map<String, Object?> toJson() => {
    'name': name,
    'address': address,
    'region': region,
    'country': country,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory LoadLocation.fromJson(Map<String, dynamic> json) => LoadLocation(
    name: json['name'] as String,
    address: json['address'] as String?,
    region: json['region'] as String?,
    country: json['country'] as String? ?? 'Nepal',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}

class LoadContactRef {
  const LoadContactRef({
    this.savedContactId,
    required this.name,
    required this.phone,
  });

  final String? savedContactId;
  final String name;
  final String phone;

  String get displayLabel => '$name · $phone';

  Map<String, Object?> toJson() => {
    'savedContactId': savedContactId,
    'name': name,
    'phone': phone,
  };

  factory LoadContactRef.fromJson(Map<String, dynamic> json) => LoadContactRef(
    savedContactId: json['savedContactId'] as String?,
    name: json['name'] as String,
    phone: json['phone'] as String,
  );
}

class LoadCargoDetails {
  LoadCargoDetails({
    required this.material,
    required List<String> natureAttributes,
    this.description,
    this.weight,
    this.weightUnit,
  }) : natureAttributes = List.unmodifiable(natureAttributes);

  final String material;
  final List<String> natureAttributes;
  final String? description;
  final double? weight;
  final String? weightUnit;

  String get summary => [material, ...natureAttributes].join(' · ');

  Map<String, Object?> toJson() => {
    'material': material,
    'natureAttributes': natureAttributes,
    'description': description,
    'weight': weight,
    'weightUnit': weightUnit,
  };

  factory LoadCargoDetails.fromJson(Map<String, dynamic> json) =>
      LoadCargoDetails(
        material: json['material'] as String,
        natureAttributes: (json['natureAttributes'] as List? ?? const [])
            .cast<String>(),
        description: json['description'] as String?,
        weight: (json['weight'] as num?)?.toDouble(),
        weightUnit: json['weightUnit'] as String?,
      );
}

class LoadStop {
  const LoadStop({
    required this.isPickup,
    required this.location,
    required this.quantity,
    this.contact = '',
  });
  final bool isPickup;
  final String location;
  final double quantity;
  final String contact;
  Map<String, Object?> toJson() => {
    'isPickup': isPickup,
    'location': location,
    'quantity': quantity,
    'contact': contact,
  };
  factory LoadStop.fromJson(Map<String, dynamic> json) => LoadStop(
    isPickup: json['isPickup'] as bool,
    location: json['location'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    contact: json['contact'] as String? ?? '',
  );
}

/// Aggregate planning amounts in tonnes; stop order is not validated.
class TruckLoadSummary {
  const TruckLoadSummary({
    required this.initialPickup,
    required this.finalDelivery,
  });
  final double initialPickup;
  final double finalDelivery;
}

TruckLoadSummary? calculateTruckLoad(
  double capacity,
  double? totalLoad,
  Iterable<LoadStop> stops,
) {
  if (!capacity.isFinite ||
      capacity <= 0 ||
      totalLoad == null ||
      !totalLoad.isFinite ||
      totalLoad <= 0 ||
      totalLoad > capacity + 0.000000001) {
    return null;
  }
  var pickups = 0.0;
  var drops = 0.0;
  for (final stop in stops) {
    if (!stop.quantity.isFinite || stop.quantity <= 0) return null;
    if (stop.isPickup) {
      pickups += stop.quantity;
    } else {
      drops += stop.quantity;
    }
  }
  if (pickups > totalLoad + 0.000000001 || drops > totalLoad + 0.000000001) {
    return null;
  }
  return TruckLoadSummary(
    initialPickup: (totalLoad - pickups).clamp(0.0, totalLoad),
    finalDelivery: (totalLoad - drops).clamp(0.0, totalLoad),
  );
}

/// Compatibility wrapper; [startingLoad] represents total journey load.
double? finalTruckLoad(
  double capacity,
  Iterable<LoadStop> stops, {
  double? startingLoad,
}) => calculateTruckLoad(capacity, startingLoad, stops)?.finalDelivery;

class TruckPlan {
  TruckPlan({
    required this.id,
    required this.truckNumber,
    required this.vehicleType,
    required this.wheelClass,
    this.capacityMatch,
    required this.capacityTons,
    this.loadWeightTons,
    this.loadWeightAutoFilled = false,
    this.loadWeightIsTotal = true,
    this.billingType,
    this.consignmentValueNpr,
    this.stops = const [],
  });

  final String id;
  final int truckNumber;
  final TruckVehicleType vehicleType;
  final TruckWheelClass wheelClass;
  final CapacityMatch? capacityMatch;
  final double capacityTons;
  final double? loadWeightTons;
  final bool loadWeightAutoFilled;

  /// False for records created before load weight meant total journey cargo.
  final bool loadWeightIsTotal;
  final TruckBillingType? billingType;
  final int? consignmentValueNpr;
  final List<LoadStop> stops;
  Map<String, Object?> toJson() => {
    'id': id,
    'truckNumber': truckNumber,
    'vehicleType': vehicleType.name,
    'wheelClass': wheelClass.name,
    'capacityMatch': capacityMatch?.name,
    'capacityTons': capacityTons,
    'loadWeightTons': loadWeightTons,
    'loadWeightAutoFilled': loadWeightAutoFilled,
    'loadWeightMeaning': loadWeightIsTotal ? 'journeyTotal' : 'startingLoad',
    'billingType': billingType?.name,
    'consignmentValueNpr': consignmentValueNpr,
    'stops': [for (final stop in stops) stop.toJson()],
  };

  factory TruckPlan.fromJson(Map<String, dynamic> json) => TruckPlan(
    id: json['id'] as String,
    truckNumber: json['truckNumber'] as int,
    vehicleType: TruckVehicleType.values.byName(json['vehicleType'] as String),
    wheelClass: TruckWheelClass.values.byName(json['wheelClass'] as String),
    capacityMatch: json['capacityMatch'] == null
        ? null
        : CapacityMatch.values.byName(json['capacityMatch'] as String),
    capacityTons: (json['capacityTons'] as num).toDouble(),
    loadWeightTons: (json['loadWeightTons'] as num?)?.toDouble(),
    loadWeightAutoFilled: json['loadWeightAutoFilled'] as bool? ?? false,
    loadWeightIsTotal: json['loadWeightMeaning'] == 'journeyTotal',
    billingType: json['billingType'] == null
        ? null
        : TruckBillingType.values.byName(json['billingType'] as String),
    consignmentValueNpr: json['consignmentValueNpr'] as int?,
    stops: [
      for (final stop in (json['stops'] as List? ?? const []))
        LoadStop.fromJson(Map<String, dynamic>.from(stop as Map)),
    ],
  );
}

class LoadPost {
  LoadPost({
    required this.id,
    required this.shipperCompanyId,
    this.createdByUserId,
    required this.loadType,
    required this.status,
    this.routeOrigin,
    this.routeDestination,
    this.pickupDate,
    this.pickupWindow,
    this.deliveryDate,
    this.deliveryWindow,
    this.cargo,
    this.pickupContact,
    this.deliveryContact,
    this.totalConsignmentValueNpr,
    required List<TruckPlan> trucks,
    required this.currentStep,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
  }) : trucks = List.unmodifiable(trucks);

  final String id;
  final String shipperCompanyId;
  final String? createdByUserId;
  final LoadType loadType;
  final LoadPostStatus status;
  final LoadLocation? routeOrigin;
  final LoadLocation? routeDestination;
  final DateTime? pickupDate;
  final LoadTimeWindow? pickupWindow;
  final DateTime? deliveryDate;
  final LoadTimeWindow? deliveryWindow;
  final LoadCargoDetails? cargo;
  final LoadContactRef? pickupContact;
  final LoadContactRef? deliveryContact;
  final int? totalConsignmentValueNpr;
  final List<TruckPlan> trucks;
  final int currentStep;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;

  LoadPost copyWith({
    LoadPostStatus? status,
    int? currentStep,
    DateTime? updatedAt,
    DateTime? submittedAt,
  }) => LoadPost(
    id: id,
    shipperCompanyId: shipperCompanyId,
    createdByUserId: createdByUserId,
    loadType: loadType,
    status: status ?? this.status,
    routeOrigin: routeOrigin,
    routeDestination: routeDestination,
    pickupDate: pickupDate,
    pickupWindow: pickupWindow,
    deliveryDate: deliveryDate,
    deliveryWindow: deliveryWindow,
    cargo: cargo,
    pickupContact: pickupContact,
    deliveryContact: deliveryContact,
    totalConsignmentValueNpr: totalConsignmentValueNpr,
    trucks: trucks,
    currentStep: currentStep ?? this.currentStep,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    submittedAt: submittedAt ?? this.submittedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'shipperCompanyId': shipperCompanyId,
    'createdByUserId': createdByUserId,
    'loadType': loadType.name,
    'status': status.name,
    'routeOrigin': routeOrigin?.toJson(),
    'routeDestination': routeDestination?.toJson(),
    'pickupDate': pickupDate?.toIso8601String(),
    'pickupWindow': pickupWindow?.name,
    'deliveryDate': deliveryDate?.toIso8601String(),
    'deliveryWindow': deliveryWindow?.name,
    'cargo': cargo?.toJson(),
    'pickupContact': pickupContact?.toJson(),
    'deliveryContact': deliveryContact?.toJson(),
    'totalConsignmentValueNpr': totalConsignmentValueNpr,
    'trucks': [for (final truck in trucks) truck.toJson()],
    'currentStep': currentStep,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'submittedAt': submittedAt?.toIso8601String(),
  };

  factory LoadPost.fromJson(Map<String, dynamic> json) => LoadPost(
    id: json['id'] as String,
    shipperCompanyId: json['shipperCompanyId'] as String,
    createdByUserId: json['createdByUserId'] as String?,
    loadType: LoadType.values.byName(json['loadType'] as String),
    status: LoadPostStatus.values.byName(json['status'] as String),
    routeOrigin: json['routeOrigin'] == null
        ? null
        : LoadLocation.fromJson(
            Map<String, dynamic>.from(json['routeOrigin'] as Map),
          ),
    routeDestination: json['routeDestination'] == null
        ? null
        : LoadLocation.fromJson(
            Map<String, dynamic>.from(json['routeDestination'] as Map),
          ),
    pickupDate: json['pickupDate'] == null
        ? null
        : DateTime.parse(json['pickupDate'] as String),
    pickupWindow: json['pickupWindow'] == null
        ? null
        : LoadTimeWindow.values.byName(json['pickupWindow'] as String),
    deliveryDate: json['deliveryDate'] == null
        ? null
        : DateTime.parse(json['deliveryDate'] as String),
    deliveryWindow: json['deliveryWindow'] == null
        ? null
        : LoadTimeWindow.values.byName(json['deliveryWindow'] as String),
    cargo: json['cargo'] == null
        ? null
        : LoadCargoDetails.fromJson(
            Map<String, dynamic>.from(json['cargo'] as Map),
          ),
    pickupContact: json['pickupContact'] == null
        ? null
        : LoadContactRef.fromJson(
            Map<String, dynamic>.from(json['pickupContact'] as Map),
          ),
    deliveryContact: json['deliveryContact'] == null
        ? null
        : LoadContactRef.fromJson(
            Map<String, dynamic>.from(json['deliveryContact'] as Map),
          ),
    totalConsignmentValueNpr: json['totalConsignmentValueNpr'] as int?,
    trucks: [
      for (final rawTruck in (json['trucks'] as List? ?? const []))
        TruckPlan.fromJson(Map<String, dynamic>.from(rawTruck as Map)),
    ],
    currentStep: (json['currentStep'] as int?) ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    submittedAt: json['submittedAt'] == null
        ? null
        : DateTime.parse(json['submittedAt'] as String),
  );
}
