import 'package:flutter/foundation.dart';
import 'package:stocrm_mobile_app/data/api.dart';

class Vehicle {
  Vehicle({
    required this.id,
    required this.plate,
    required this.make,
    required this.model,
    required this.year,
    required this.mileage,
    this.vin,
    this.nextServiceKm,
  });

  final String id;
  final String plate;
  final String make;
  final String model;
  final int year;
  int mileage;
  final String? vin;
  final int? nextServiceKm;

  String get title => '$make $model';
}

class Branch {
  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.hours,
    required this.distanceKm,
    required this.services,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String hours;
  final double distanceKm;
  final List<String> services;
}

class ServiceItem {
  ServiceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priceFrom,
    required this.durationMin,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final int priceFrom;
  final int durationMin;
  final String icon;
}

class Visit {
  Visit({
    required this.id,
    required this.serviceTitle,
    required this.branchName,
    required this.carPlate,
    required this.when,
    required this.status,
    this.amount,
    this.mileage,
    this.works = const [],
    this.parts = const [],
  });

  final String id;
  final String serviceTitle;
  final String branchName;
  final String carPlate;
  final DateTime when;
  String status;
  final int? amount;
  final int? mileage;
  final List<String> works;
  final List<String> parts;
}

class BonusEvent {
  BonusEvent({required this.title, required this.delta, required this.when, this.note});
  final String title;
  final int delta;
  final DateTime when;
  final String? note;
}

class RepairStep {
  RepairStep({required this.title, required this.at, required this.done, this.detail});
  final String title;
  final DateTime at;
  final bool done;
  final String? detail;
}

class Promo {
  Promo({required this.title, required this.subtitle, required this.badge});
  final String title;
  final String subtitle;
  final String badge;
}

class ChatMessage {
  ChatMessage({required this.fromStaff, required this.text});
  final bool fromStaff;
  final String text;
}

class MockStore extends ChangeNotifier {
  bool shortsDone = false;
  bool loggedIn = false;
  String phone = '+7 900 123-45-67';
  String clientName = 'Алексей';
  int bonus = 1840;
  String activeCarId = 'c1';
  final api = ApiClient();
  int? crmContactId;
  bool crmLive = false;
  bool foundInCrm = false;

  final branches = [
    Branch(
      id: 'b1',
      name: 'VAG Market · Московский тракт',
      address: 'ул. Московский тракт, 118/11',
      phone: '+7 345 268-00-11',
      hours: 'Пн–Сб 09:00–21:00',
      distanceKm: 1.8,
      services: ['ТО', 'Диагностика', 'Шиномонтаж', 'Масло'],
    ),
    Branch(
      id: 'b2',
      name: 'VAG Market · Юг',
      address: 'ул. Республики, 158',
      phone: '+7 345 268-00-22',
      hours: 'Ежедневно 08:00–22:00',
      distanceKm: 4.3,
      services: ['ТО', 'Кузов', 'Шиномонтаж'],
    ),
    Branch(
      id: 'b3',
      name: 'VAG Market · Заречный',
      address: 'ул. Мельникайте, 70',
      phone: '+7 345 268-00-33',
      hours: 'Пн–Вс 09:00–20:00',
      distanceKm: 6.1,
      services: ['Диагностика', 'Ходовая', 'Развал'],
    ),
  ];

  final services = [
    ServiceItem(id: 's1', title: 'Техническое обслуживание', subtitle: 'ТО-1 / ТО-2 по регламенту', priceFrom: 4900, durationMin: 120, icon: 'build'),
    ServiceItem(id: 's2', title: 'Диагностика', subtitle: 'Компьютер + осмотр ходовой', priceFrom: 1500, durationMin: 60, icon: 'search'),
    ServiceItem(id: 's3', title: 'Замена масла', subtitle: 'Моторное масло + фильтр', priceFrom: 2900, durationMin: 45, icon: 'oil'),
    ServiceItem(id: 's4', title: 'Шиномонтаж', subtitle: 'Сезонная смена комплекта', priceFrom: 1800, durationMin: 40, icon: 'tire'),
    ServiceItem(id: 's5', title: 'Тормозная система', subtitle: 'Колодки, диски, жидкость', priceFrom: 3500, durationMin: 90, icon: 'brake'),
    ServiceItem(id: 's6', title: 'Кузовной ремонт', subtitle: 'Оценка после осмотра', priceFrom: 0, durationMin: 30, icon: 'body'),
  ];

  late List<Vehicle> cars = [
    Vehicle(
      id: 'c1',
      plate: 'А 123 ВС 72',
      make: 'Volkswagen',
      model: 'Tiguan',
      year: 2019,
      mileage: 86420,
      vin: 'JTNB11HK40K123456',
      nextServiceKm: 90000,
    ),
    Vehicle(
      id: 'c2',
      plate: 'К 777 КК 72',
      make: 'Audi',
      model: 'A4',
      year: 2021,
      mileage: 41200,
      nextServiceKm: 45000,
    ),
  ];

  late List<Visit> visits = [
    Visit(
      id: 'v1',
      serviceTitle: 'Замена масла',
      branchName: 'VAG Market · Московский тракт',
      carPlate: 'А 123 ВС 72',
      when: DateTime.now().add(const Duration(days: 2, hours: 4)),
      status: 'подтверждена',
    ),
    Visit(
      id: 'v2',
      serviceTitle: 'ТО-2 + тормоза',
      branchName: 'VAG Market · Юг',
      carPlate: 'А 123 ВС 72',
      when: DateTime.now().subtract(const Duration(days: 86)),
      status: 'выполнен',
      amount: 24890,
      mileage: 82100,
      works: ['Замена масла 5W-30', 'Фильтр салона', 'Диагностика'],
      parts: ['Колодки передние TRW', 'Фильтр масляный Mann'],
    ),
    Visit(
      id: 'v3',
      serviceTitle: 'Шиномонтаж',
      branchName: 'VAG Market · Московский тракт',
      carPlate: 'К 777 КК 72',
      when: DateTime.now().subtract(const Duration(days: 140)),
      status: 'выполнен',
      amount: 2200,
      mileage: 39800,
      works: ['Смена комплекта R17', 'Балансировка'],
      parts: [],
    ),
  ];

  final repairSteps = [
    RepairStep(title: 'Принят на пост', at: DateTime.now().subtract(const Duration(hours: 5)), done: true, detail: 'Мастер Иван'),
    RepairStep(title: 'Диагностика', at: DateTime.now().subtract(const Duration(hours: 4)), done: true, detail: 'Рекомендована замена колодок'),
    RepairStep(title: 'Ожидание запчастей', at: DateTime.now().subtract(const Duration(hours: 2)), done: true, detail: 'Колодки в пути, STOCRM'),
    RepairStep(title: 'Ремонт', at: DateTime.now().add(const Duration(hours: 1)), done: false, detail: 'Ориентир 17:30'),
    RepairStep(title: 'Готов к выдаче', at: DateTime.now().add(const Duration(hours: 3)), done: false, detail: 'Push: «Ваша машина готова!»'),
  ];

  final bonusLog = [
    BonusEvent(title: 'Начисление 5%', delta: 1244, when: DateTime.now().subtract(const Duration(days: 86)), note: 'ЗН ТО-2 + тормоза'),
    BonusEvent(title: 'Начисление 5%', delta: 110, when: DateTime.now().subtract(const Duration(days: 140)), note: 'Шиномонтаж'),
    BonusEvent(title: 'Списание', delta: -486, when: DateTime.now().subtract(const Duration(days: 20)), note: 'Замена масла'),
  ];

  final promos = [
    Promo(title: '−20% на шиномонтаж', subtitle: 'До конца месяца, любой филиал', badge: 'Акция'),
    Promo(title: 'Бесплатная диагностика', subtitle: 'При записи на ТО через приложение', badge: 'В приложении'),
  ];

  final recommendations = [
    'Пора ТО: через 3 580 км или в октябре',
    'Колодки: рекомендована замена на прошлом визите',
    'Сезон: запись на шиномонтаж открыта',
  ];

  final chat = <ChatMessage>[
    ChatMessage(fromStaff: true, text: 'Здравствуйте! Это Егор, VAG Market. Чем помочь?'),
    ChatMessage(fromStaff: false, text: 'Можно записаться на замену масла завтра утром?'),
    ChatMessage(fromStaff: true, text: 'Егор: да, на Московском тракте свободно 10:00 и 11:30. Подтвердим запись в админке.'),
  ];

  Vehicle? get activeCar {
    if (cars.isEmpty) return null;
    return cars.firstWhere((c) => c.id == activeCarId, orElse: () => cars.first);
  }

  Visit? get nextVisit {
    final upcoming = visits.where((v) => v.when.isAfter(DateTime.now()) && v.status != 'отменена').toList()
      ..sort((a, b) => a.when.compareTo(b.when));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  List<Visit> get upcoming =>
      visits.where((v) => v.status != 'выполнен' && v.status != 'отменена').toList();

  List<Visit> get history => visits.where((v) => v.status == 'выполнен' || v.status == 'отменена').toList();

  void finishShorts() {
    shortsDone = true;
    notifyListeners();
  }

  void sendVinRequest(String vin, String part) {
    chat.add(ChatMessage(fromStaff: false, text: 'VIN $vin · $part'));
    chat.add(ChatMessage(fromStaff: true, text: 'Егор: заявку на подбор получили, уточним наличие и напишем.'));
    notifyListeners();
  }

  void login(String value) {
    loggedIn = true;
    phone = value;
    notifyListeners();
  }

  Future<void> requestOtp(String rawPhone) async {
    await api.post('/v1/auth/otp/request', {'phone': rawPhone});
  }

  Future<void> loginRemote(String rawPhone, String code) async {
    final res = await api.post('/v1/auth/otp/confirm', {'phone': rawPhone, 'code': code});
    api.token = res['token'] as String?;
    final cid = res['contact_id'];
    crmContactId = cid is int ? cid : int.tryParse('$cid');
    foundInCrm = res['found_in_crm'] == true;
    crmLive = api.token != null;
    clientName = (res['name'] as String?) ?? clientName;
    loggedIn = true;
    phone = rawPhone;
    notifyListeners();
    await Future.wait([refreshGarage(), refreshBranches(), refreshVisits()]);
  }

  Future<void> refreshGarage() async {
    if (api.token == null) return;
    try {
      final res = await api.get('/v1/garage');
      final raw = res['cars'];
      final mapped = <Vehicle>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          final id = '${m['id'] ?? m['CAR_PROFILE_ID'] ?? m['ID'] ?? mapped.length}';
          if (id == '0' || id.isEmpty) continue;
          mapped.add(Vehicle(
            id: id,
            plate: '${m['plate'] ?? m['LICENSE_PLATE'] ?? m['title'] ?? m['TITLE'] ?? ''}',
            make: '${m['brand'] ?? m['MARK'] ?? m['BRAND'] ?? ''}',
            model: '${m['model'] ?? m['MODEL'] ?? m['title'] ?? m['TITLE'] ?? 'авто'}',
            year: int.tryParse('${m['year'] ?? m['YEAR'] ?? ''}') ?? 0,
            mileage: int.tryParse('${m['mileage'] ?? m['MILEAGE'] ?? 0}') ?? 0,
            vin: (m['vin'] ?? m['VIN'])?.toString(),
          ));
        }
      }
      cars = mapped;
      activeCarId = mapped.isEmpty ? '' : mapped.first.id;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshBranches() async {
    try {
      final res = await api.get('/v1/branches');
      final raw = res['branches'];
      if (raw is! List || raw.isEmpty) return;
      final mapped = <Branch>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final id = '${m['id'] ?? ''}';
        if (id.isEmpty) continue;
        mapped.add(Branch(
          id: id,
          name: '${m['name'] ?? ''}',
          address: '${m['address'] ?? m['city'] ?? ''}',
          phone: '${m['phone'] ?? ''}',
          hours: '${m['work_time'] ?? ''}',
          distanceKm: 0,
          services: ['${m['city'] ?? 'Тюмень'}'],
        ));
      }
      if (mapped.isNotEmpty) {
        branches
          ..clear()
          ..addAll(mapped);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> refreshVisits() async {
    if (api.token == null) return;
    try {
      final res = await api.get('/v1/visits');
      final raw = res['offers'];
      if (raw is! List) return;
      final mapped = <Visit>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        mapped.add(Visit(
          id: '${m['id'] ?? mapped.length}',
          serviceTitle: '${m['status'] ?? 'Заявка'}',
          branchName: '${m['branch'] ?? ''}',
          carPlate: '${m['car'] ?? ''}',
          when: _parseTs(m['calendar_from'] ?? m['created']),
          status: _visitStatus('${m['status'] ?? ''}'),
          amount: int.tryParse('${m['sum'] ?? m['works_sum'] ?? ''}'),
        ));
      }
      visits = mapped;
      notifyListeners();
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> bookRemote({required String comment, int? carId, String? branchId, String? when}) async {
    if (api.token == null) {
      throw ApiException(401, 'Нет сессии BFF');
    }
    return api.post('/v1/bookings', {
      'comment': comment,
      'car_id': carId,
      'branch_id': branchId,
      'when': when,
    });
  }

  void logout() {
    loggedIn = false;
    crmLive = false;
    foundInCrm = false;
    crmContactId = null;
    api.token = null;
    notifyListeners();
  }

  void setActiveCar(String id) {
    activeCarId = id;
    notifyListeners();
  }

  void addCar(Vehicle car) {
    cars = [...cars, car];
    activeCarId = car.id;
    notifyListeners();
  }

  List<DateTime> slotsFor(DateTime day, {String? branchId}) {
    final weekend = day.weekday >= 6;
    final extra = branchId == 'b1' ? 0 : (branchId == 'b2' ? 1 : 2);
    final count = (weekend ? 5 : 9) - extra;
    final startHour = weekend ? 10 : 9;
    final base = DateTime(day.year, day.month, day.day, startHour);
    return List.generate(count.clamp(4, 10), (i) => base.add(Duration(minutes: 60 * i)));
  }

  void addVisit({
    required String serviceTitle,
    required Branch branch,
    required DateTime when,
    required Vehicle car,
  }) {
    visits = [
      Visit(
        id: 'v${visits.length + 1}',
        serviceTitle: serviceTitle,
        branchName: branch.name,
        carPlate: car.plate,
        when: when,
        status: 'ожидает подтверждения',
      ),
      ...visits,
    ];
    notifyListeners();
  }

  void cancelVisit(String id) {
    for (final v in visits) {
      if (v.id == id && v.status != 'выполнен') {
        v.status = 'отменена';
        notifyListeners();
        return;
      }
    }
  }

  void sendChat(String text) {
    chat.add(ChatMessage(fromStaff: false, text: text));
    chat.add(ChatMessage(
      fromStaff: true,
      text: 'Егор: приняли, ответим в этом чате.',
    ));
    notifyListeners();
  }
}

DateTime _parseTs(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is int) {
    if (v > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.fromMillisecondsSinceEpoch(v * 1000);
  }
  final n = int.tryParse('$v');
  if (n != null) {
    if (n > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(n);
    if (n > 1000000000) return DateTime.fromMillisecondsSinceEpoch(n * 1000);
  }
  return DateTime.tryParse('$v') ?? DateTime.now();
}

String _visitStatus(String name) {
  final n = name.toLowerCase();
  if (n.contains('успешн') || n.contains('выполнен')) return 'выполнен';
  if (n.contains('отказ') || n.contains('мусор')) return 'отменена';
  if (n.isEmpty) return 'ожидает подтверждения';
  return name;
}
