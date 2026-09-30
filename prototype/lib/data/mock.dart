import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    this.mapsUrl,
    this.yandexUrl,
    this.lat,
    this.lng,
    this.precise = false,
    this.city = '',
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String hours;
  final double distanceKm;
  final List<String> services;
  final String? mapsUrl;
  final String? yandexUrl;
  final double? lat;
  final double? lng;
  final bool precise;
  final String city;

  bool get hasPoint => lat != null && lng != null;

  String get distanceLabel => distanceKm > 0 ? '${distanceKm.toStringAsFixed(1)} км' : '';

  Branch copyWith({double? distanceKm}) => Branch(
        id: id,
        name: name,
        address: address,
        phone: phone,
        hours: hours,
        distanceKm: distanceKm ?? this.distanceKm,
        services: services,
        mapsUrl: mapsUrl,
        yandexUrl: yandexUrl,
        lat: lat,
        lng: lng,
        precise: precise,
        city: city,
      );
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
    this.statusId,
    this.stage = '',
    this.isReady = false,
    this.isHistory = false,
    this.successful = false,
    this.steps = const [],
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
  final int? statusId;
  final String stage;
  final bool isReady;
  bool isHistory;
  final bool successful;
  final List<RepairStep> steps;
}

class BonusEvent {
  BonusEvent({required this.title, required this.delta, required this.when, this.note, this.expired = false});
  final String title;
  final int delta;
  final DateTime when;
  final String? note;
  final bool expired;
}

class RepairStep {
  RepairStep({required this.title, required this.at, required this.done, this.detail});
  final String title;
  final DateTime at;
  final bool done;
  final String? detail;
}

class AppNote {
  AppNote({required this.id, required this.title, required this.body, this.offerId, this.read = false, this.kind});
  final String id;
  final String title;
  final String body;
  final String? offerId;
  final String? kind;
  bool read;
}

class SlotOption {
  SlotOption({required this.at, required this.label, this.free = 1});
  final DateTime at;
  final String label;
  final int free;
}

class RepairRec {
  RepairRec({required this.title, this.subtitle = '', this.car = '', this.plate = '', this.carId = ''});
  final String title;
  final String subtitle;
  final String car;
  final String plate;
  final String carId;
}

class AppTicket {
  AppTicket({required this.id, required this.kind, required this.title, this.subtitle = '', this.status = 'new'});
  final String id;
  final String kind;
  final String title;
  final String subtitle;
  final String status;
}

class Promo {
  Promo({required this.title, required this.subtitle, required this.badge, this.imageUrl});
  final String title;
  final String subtitle;
  final String badge;
  final String? imageUrl;
}

class ChatMessage {
  ChatMessage({required this.fromStaff, required this.text, this.staffName, this.kind, this.created = 0});
  final bool fromStaff;
  final String text;
  final String? staffName;
  final String? kind;
  final int created;
}

class MockStore extends ChangeNotifier {
  bool shortsDone = false;
  bool loggedIn = false;
  String phone = '+7 900 123-45-67';
  String email = '';
  String clientName = 'Алексей';
  int bonus = 1840;
  int bonusAccrued = 1840;
  List<BonusEvent> bonusLog = [
    BonusEvent(title: 'Начисление 5%', delta: 1244, when: DateTime.now().subtract(const Duration(days: 86)), note: 'ЗН ТО-2 + тормоза'),
    BonusEvent(title: 'Начисление 5%', delta: 110, when: DateTime.now().subtract(const Duration(days: 140)), note: 'Шиномонтаж'),
    BonusEvent(title: 'Списание', delta: -486, when: DateTime.now().subtract(const Duration(days: 20)), note: 'Замена масла'),
  ];
  List<RepairRec> recommendations = [
    RepairRec(title: 'Пора ТО: через 3 580 км или в октябре', car: 'Volkswagen Tiguan', plate: 'А 123 ВС 72'),
    RepairRec(title: 'Колодки: рекомендована замена на прошлом визите', car: 'Volkswagen Tiguan', plate: 'А 123 ВС 72'),
  ];
  List<AppTicket> tickets = [];
  String staffName = 'Менеджер';
  int lastChatRead = 0;
  String activeCarId = 'c1';
  final api = ApiClient();
  int? crmContactId;
  bool crmLive = false;
  bool foundInCrm = false;
  Timer? _poller;
  List<AppNote> notes = [];
  String? pendingReadyAlert;

  final branches = [
    Branch(
      id: '2113',
      name: 'Московский',
      address: 'Тюмень, ул. Московский тракт, 118/11',
      phone: '+7 904 495-09-80',
      hours: 'Пн–Пт 09:00–20:00, Сб–Вс 09:00–18:00',
      distanceKm: 0,
      lat: 57.125783,
      lng: 65.468036,
      precise: true,
      city: 'Тюмень',
      services: ['ТО', 'Диагностика', 'Шиномонтаж'],
      mapsUrl: 'https://2gis.ru/geo/65.468036,57.125783',
      yandexUrl: 'https://yandex.ru/maps/?pt=65.468036,57.125783&z=16&l=map',
    ),
    Branch(
      id: '3550',
      name: 'Эрвье',
      address: 'Тюмень, ул. Эрвье',
      phone: '+7 345 257-98-88',
      hours: '09:00–20:00',
      distanceKm: 0,
      city: 'Тюмень',
      services: ['ТО', 'Диагностика'],
    ),
    Branch(
      id: '2109',
      name: 'Республика',
      address: 'Тюмень, ул. Республики',
      phone: '+7 345 257-98-88',
      hours: '10:00–22:00',
      distanceKm: 0,
      city: 'Тюмень',
      services: ['ТО', 'Сервис'],
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
      isHistory: true,
      successful: true,
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
      isHistory: true,
      successful: true,
    ),
  ];

  final repairSteps = [
    RepairStep(title: 'Принят на пост', at: DateTime.now().subtract(const Duration(hours: 5)), done: true, detail: 'Мастер Иван'),
    RepairStep(title: 'Диагностика', at: DateTime.now().subtract(const Duration(hours: 4)), done: true, detail: 'Рекомендована замена колодок'),
    RepairStep(title: 'Ожидание запчастей', at: DateTime.now().subtract(const Duration(hours: 2)), done: true, detail: 'Колодки в пути, STOCRM'),
    RepairStep(title: 'Ремонт', at: DateTime.now().add(const Duration(hours: 1)), done: false, detail: 'Ориентир 17:30'),
    RepairStep(title: 'Готов к выдаче', at: DateTime.now().add(const Duration(hours: 3)), done: false, detail: 'Push: «Ваша машина готова!»'),
  ];

  List<Promo> promos = [
    Promo(title: 'Замена масла', subtitle: 'Масло + фильтр + работа', badge: 'от 4 990 ₽'),
    Promo(title: 'Тормозные колодки', subtitle: '', badge: 'от 6 900 ₽'),
    Promo(title: 'Замена ГРМ', subtitle: '', badge: 'от 14 900 ₽'),
  ];
  String? pendingScreen;
  static const _widgetCh = MethodChannel('vagmarket/widget');

  List<ChatMessage> chat = <ChatMessage>[
    ChatMessage(fromStaff: true, text: 'Здравствуйте! Чем помочь?'),
    ChatMessage(fromStaff: false, text: 'Можно записаться на замену масла завтра утром?'),
    ChatMessage(fromStaff: true, text: 'Да, на Московском свободно 10:00 и 11:30. Подтвердим запись.'),
  ];

  Vehicle? get activeCar {
    if (cars.isEmpty) return null;
    return cars.firstWhere((c) => c.id == activeCarId, orElse: () => cars.first);
  }

  Visit? get nextVisit {
    final open = visits.where((v) => !v.isHistory && v.status != 'отменена').toList()
      ..sort((a, b) {
        if (a.isReady != b.isReady) return a.isReady ? -1 : 1;
        return a.when.compareTo(b.when);
      });
    return open.isEmpty ? null : open.first;
  }

  List<Visit> get upcoming => visits.where((v) => !v.isHistory && v.status != 'отменена').toList();

  List<Visit> get history => visits.where((v) => v.successful).toList();

  List<AppNote> get unreadNotes => notes.where((n) => !n.read).toList();

  int get unreadChat => chat.where((m) => m.fromStaff && m.created > lastChatRead).length;

  int get vinTicketCount => tickets.where((t) => t.kind == 'vin').length;

  void finishShorts() {
    shortsDone = true;
    notifyListeners();
    _persist();
  }

  void sendVinRequest(String vin, String part) {
    tickets = [
      AppTicket(id: 't${tickets.length + 1}', kind: 'vin', title: vin.toUpperCase(), subtitle: part),
      ...tickets,
    ];
    notifyListeners();
  }

  Future<void> sendVinRemote(String vin, String part) async {
    if (api.token == null) {
      sendVinRequest(vin, part);
      return;
    }
    await api.post('/v1/vin', {'vin': vin, 'part': part});
    await refreshTickets();
  }

  Future<void> refreshChat() async {
    if (api.token == null) return;
    try {
      final res = await api.get('/v1/chat');
      final sn = (res['staff_name'] as String?)?.trim();
      if (sn != null && sn.isNotEmpty) staffName = sn;
      final raw = res['messages'];
      if (raw is! List) return;
      chat = [
        for (final item in raw)
          if (item is Map)
            ChatMessage(
              fromStaff: item['from_staff'] == true,
              text: '${item['text'] ?? ''}',
              staffName: item['staff_name']?.toString(),
              kind: item['kind']?.toString(),
              created: _toInt(item['created']),
            ),
      ];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> sendChatRemote(String text) async {
    if (api.token == null) {
      sendChat(text);
      return;
    }
    await api.post('/v1/chat', {'text': text});
    await refreshChat();
  }

  Future<void> refreshBonuses() async {
    if (api.token == null) return;
    try {
      final res = await api.get('/v1/bonuses');
      final raw = res['events'];
      bonusLog = [
        for (final item in raw is List ? raw : const [])
          if (item is Map)
              BonusEvent(
                title: '${item['title'] ?? ''}',
                delta: _toInt(item['remaining'] ?? item['delta']),
                when: _parseTs(item['when']),
                note: item['note']?.toString(),
                expired: item['expired'] == true,
              ),
      ];
      if (raw is List) {
        bonus = bonusLog.fold<int>(0, (sum, e) => sum + (e.expired ? 0 : e.delta));
      } else {
        bonus = _toInt(res['balance']);
      }
      bonusAccrued = _toInt(res['accrued']);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshRecommendations() async {
    if (api.token == null) return;
    try {
      final res = await api.get('/v1/recommendations');
      final raw = res['items'];
      if (raw is! List) return;
      recommendations = [
        for (final item in raw)
          if (item is Map)
            RepairRec(
              title: '${item['title'] ?? ''}',
              subtitle: '${item['subtitle'] ?? ''}',
              car: '${item['car'] ?? ''}',
              plate: '${item['plate'] ?? ''}',
              carId: '${item['car_id'] ?? ''}',
            ),
      ].where((s) => s.title.isNotEmpty).toList();
      notifyListeners();
    } catch (_) {}
  }

  void login(String value) {
    loggedIn = true;
    phone = value;
    notifyListeners();
  }

  Future<Map<String, dynamic>> lookupAuth(String rawPhone) async {
    return api.post('/v1/auth/lookup', {'phone': rawPhone});
  }

  Future<Map<String, dynamic>> requestOtp(String rawPhone, {String? email}) async {
    return api.post('/v1/auth/otp/request', {
      'phone': rawPhone,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    });
  }

  Future<void> loginRemote(String rawPhone, String code, {String? email}) async {
    final res = await api.post('/v1/auth/otp/confirm', {
      'phone': rawPhone,
      'code': code,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    });
    api.token = res['token'] as String?;
    final cid = res['contact_id'];
    crmContactId = cid is int ? cid : int.tryParse('$cid');
    foundInCrm = res['found_in_crm'] == true;
    crmLive = api.token != null;
    clientName = (res['name'] as String?) ?? clientName;
    this.email = '${res['email'] ?? email ?? this.email}';
    loggedIn = true;
    phone = rawPhone;
    bonus = 0;
    bonusAccrued = 0;
    bonusLog = [];
    notifyListeners();
    await _persist();
    startPolling();
    await Future.wait([
      refreshGarage(),
      refreshBranches(),
      refreshVisits(),
      refreshNotes(),
      refreshChat(),
      refreshBonuses(),
      refreshRecommendations(),
      refreshPromos(),
      refreshTickets(),
      registerPush(),
    ]);
    await syncWidget();
    await consumeWidgetLaunch();
  }

  Future<void> registerPush() async {
    if (api.token == null || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await api.post('/v1/devices', {'fcm_token': token});
      }
      messaging.onTokenRefresh.listen((next) {
        if (api.token == null || next.isEmpty) return;
        api.post('/v1/devices', {'fcm_token': next});
      });
    } catch (_) {}
  }

  void startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 90), (_) => pollNow());
  }

  Future<void> pollNow() async {
    if (api.token == null) return;
    final prev = {for (final v in visits) v.id: (v.status, v.isReady)};
    final prevStaff = chat.where((m) => m.fromStaff).length;
    await Future.wait([refreshVisits(), refreshNotes(), refreshChat(), refreshBonuses(), refreshRecommendations(), refreshPromos(), refreshTickets()]);
    await syncWidget();
    for (final v in visits) {
      final old = prev[v.id];
      if (old != null && !old.$2 && v.isReady) {
        pendingReadyAlert = 'Ваша машина готова!';
      }
    }
    if (unreadNotes.any((n) => n.title.contains('готова'))) {
      pendingReadyAlert ??= 'Ваша машина готова!';
    }
    if (chat.where((m) => m.fromStaff).length > prevStaff) {
      pendingReadyAlert ??= 'Новое сообщение от $staffName';
    }
    notifyListeners();
  }

  void clearReadyAlert() {
    pendingReadyAlert = null;
  }

  Future<void> refreshNotes() async {
    if (api.token == null) return;
    try {
      final res = await api.get('/v1/notifications');
      final raw = res['items'];
      if (raw is! List) return;
      notes = [
        for (final item in raw)
          if (item is Map)
            AppNote(
              id: '${item['id'] ?? ''}',
              title: '${item['title'] ?? ''}',
              body: '${item['body'] ?? ''}',
              offerId: item['offer_id']?.toString(),
              read: item['read'] == true,
              kind: item['kind']?.toString(),
            ),
      ];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markNoteRead(String id) async {
    try {
      await api.post('/v1/notifications/$id/read', {});
    } catch (_) {}
    for (final n in notes) {
      if (n.id == id) n.read = true;
    }
    notifyListeners();
  }

  Future<void> testReadyPush() async {
    await api.post('/v1/notifications/test', {});
    await refreshNotes();
    pendingReadyAlert = 'Ваша машина готова!';
    notifyListeners();
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
          city: '${m['city'] ?? ''}',
          lat: _coord(m['lat']),
          lng: _coord(m['lng']),
          precise: m['precise'] == true,
          services: [
            if ('${m['city'] ?? ''}'.trim().isNotEmpty) '${m['city']}',
          ],
          mapsUrl: (m['maps_url'] as String?)?.isNotEmpty == true ? '${m['maps_url']}' : null,
          yandexUrl: (m['yandex_url'] as String?)?.isNotEmpty == true ? '${m['yandex_url']}' : null,
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

  double? _coord(dynamic raw) {
    if (raw == null) return null;
    return double.tryParse('$raw');
  }

  Future<Branch?> locateNearest() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
      );
      applyUserLocation(pos.latitude, pos.longitude);
      final withDist = branches.where((b) => b.distanceKm > 0).toList();
      if (withDist.isEmpty) return null;
      withDist.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return withDist.first;
    } catch (_) {
      return null;
    }
  }

  void applyUserLocation(double lat, double lng) {
    for (var i = 0; i < branches.length; i++) {
      final b = branches[i];
      if (!b.hasPoint) continue;
      final meters = Geolocator.distanceBetween(lat, lng, b.lat!, b.lng!);
      branches[i] = b.copyWith(distanceKm: meters / 1000);
    }
    branches.sort((a, b) {
      if (a.distanceKm <= 0 && b.distanceKm <= 0) return a.name.compareTo(b.name);
      if (a.distanceKm <= 0) return 1;
      if (b.distanceKm <= 0) return -1;
      return a.distanceKm.compareTo(b.distanceKm);
    });
    notifyListeners();
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
        final works = [
          if (m['works'] is List)
            for (final w in m['works'] as List) '$w',
        ];
        mapped.add(Visit(
          id: '${m['id'] ?? mapped.length}',
          serviceTitle: works.isNotEmpty ? works.first : '${m['status'] ?? 'Заказ-наряд'}',
          branchName: '${m['branch'] ?? ''}',
          carPlate: '${m['car'] ?? ''}',
          when: _parseTs(m['calendar_from'] ?? m['created']),
          status: _visitStatus('${m['status'] ?? ''}'),
          amount: int.tryParse('${m['sum'] ?? m['works_sum'] ?? ''}'),
          works: works,
          parts: [
            if (m['parts'] is List)
              for (final w in m['parts'] as List) '$w',
          ],
          statusId: int.tryParse('${m['status_id'] ?? ''}'),
          stage: '${m['stage'] ?? ''}',
          isReady: m['is_ready'] == true,
          isHistory: m['is_history'] == true || m['successful'] == true,
          successful: m['successful'] == true,
          steps: [
            if (m['steps'] is List)
              for (final s in m['steps'] as List)
                if (s is Map)
                  RepairStep(
                    title: '${s['title'] ?? ''}',
                    at: DateTime.now(),
                    done: s['done'] == true,
                    detail: s['detail']?.toString(),
                  ),
          ],
        ));
      }
      visits = mapped;
      notifyListeners();
      await syncWidget();
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

  String get privacyUrl {
    final b = api.base;
    if (b.isEmpty) return 'http://45.81.33.7/privacy.html';
    return '$b/privacy.html';
  }

  Future<void> refreshPromos() async {
    try {
      final res = await api.get('/v1/promos');
      final raw = res['items'];
      if (raw is! List || raw.isEmpty) return;
      final mapped = <Promo>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final title = '${item['title'] ?? ''}';
        if (title.isEmpty) continue;
        mapped.add(Promo(
          title: title,
          subtitle: '${item['subtitle'] ?? item['body'] ?? ''}',
          badge: '${item['badge'] ?? 'Акция'}',
          imageUrl: () {
            final raw = '${item['image_url'] ?? ''}';
            if (raw.isEmpty) return null;
            if (raw.startsWith('http')) return raw;
            return '${api.base}$raw';
          }(),
        ));
      }
      if (mapped.isNotEmpty) {
        promos = mapped;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> syncWidget() async {
    if (kIsWeb) return;
    Map<String, dynamic> payload = {
      'state': 'ok',
      'title': 'Всё в порядке',
      'subtitle': 'VAG Market',
      'screen': 'book',
    };
    try {
      if (api.token != null) {
        payload = Map<String, dynamic>.from(await api.get('/v1/widget'));
      } else {
        final vis = nextVisit;
        final car = activeCar;
        if (vis != null && vis.isReady) {
          payload = {'state': 'ready', 'title': 'Машина готова', 'subtitle': vis.status, 'screen': 'status'};
        } else if (vis != null) {
          payload = {'state': 'service', 'title': 'Авто в сервисе', 'subtitle': vis.status, 'screen': 'status'};
        } else if (recommendations.isNotEmpty) {
          payload = {
            'state': 'recs',
            'title': 'Есть рекомендации',
            'subtitle': '${recommendations.length} активных',
            'screen': 'recommendations',
          };
        } else if (car != null && car.nextServiceKm != null && car.mileage >= car.nextServiceKm!) {
          payload = {'state': 'due', 'title': 'Пора на ТО', 'subtitle': car.title, 'screen': 'recommendations'};
        }
      }
      await _widgetCh.invokeMethod('update', payload);
    } catch (_) {}
  }

  Future<void> consumeWidgetLaunch() async {
    if (kIsWeb) return;
    try {
      final screen = await _widgetCh.invokeMethod<String>('launchScreen');
      if (screen != null && screen.isNotEmpty) {
        pendingScreen = screen;
        notifyListeners();
      }
    } catch (_) {}
  }

  void clearPendingScreen() {
    pendingScreen = null;
  }

  void logout() {
    _poller?.cancel();
    _poller = null;
    final token = api.token;
    loggedIn = false;
    crmLive = false;
    foundInCrm = false;
    crmContactId = null;
    email = '';
    api.token = null;
    notes = [];
    tickets = [];
    pendingReadyAlert = null;
    notifyListeners();
    if (token != null) {
      api.post('/v1/auth/logout', {});
    }
    _clearPersist();
  }

  Future<void> bootstrap() async {
    final p = await SharedPreferences.getInstance();
    shortsDone = p.getBool('shortsDone') ?? false;
    lastChatRead = p.getInt('lastChatRead') ?? 0;
    final token = p.getString('token');
    if (token == null || token.isEmpty) {
      notifyListeners();
      return;
    }
    api.token = token;
    try {
      final me = await api.get('/v1/me');
      loggedIn = true;
      crmLive = true;
      phone = '${me['phone'] ?? p.getString('phone') ?? phone}';
      email = '${me['email'] ?? ''}';
      clientName = '${me['name'] ?? clientName}';
      final cid = me['contact_id'];
      crmContactId = cid is int ? cid : int.tryParse('$cid');
      foundInCrm = crmContactId != null;
      notifyListeners();
      startPolling();
      await Future.wait([
        refreshGarage(),
        refreshBranches(),
        refreshVisits(),
        refreshNotes(),
        refreshChat(),
        refreshBonuses(),
        refreshRecommendations(),
        refreshPromos(),
        refreshTickets(),
        registerPush(),
      ]);
      await syncWidget();
    } catch (_) {
      api.token = null;
      loggedIn = false;
      await p.remove('token');
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('shortsDone', shortsDone);
    await p.setInt('lastChatRead', lastChatRead);
    if (api.token != null) {
      await p.setString('token', api.token!);
      await p.setString('phone', phone);
    }
  }

  Future<void> _clearPersist() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
  }

  void markChatRead() {
    final maxTs = chat.fold<int>(0, (m, e) => e.created > m ? e.created : m);
    final next = maxTs == 0 ? DateTime.now().millisecondsSinceEpoch ~/ 1000 : maxTs;
    if (next <= lastChatRead && maxTs > 0) return;
    if (next == lastChatRead) return;
    lastChatRead = next;
    notifyListeners();
    _persist();
  }

  Future<void> refreshTickets() async {
    if (api.token == null) return;
    try {
      final res = await api.get('/v1/tickets');
      final raw = res['items'];
      if (raw is! List) return;
      tickets = [
        for (final item in raw)
          if (item is Map)
            AppTicket(
              id: '${item['id'] ?? ''}',
              kind: '${item['kind'] ?? 'vin'}',
              title: '${item['vin'] ?? item['branch'] ?? item['when'] ?? 'Заявка'}',
              subtitle: '${item['part'] ?? item['comment'] ?? item['when'] ?? ''}',
              status: '${item['status'] ?? 'new'}',
            ),
      ];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> shareVisitPdf(Visit visit) async {
    if (api.token == null) throw ApiException(401, 'Нет сессии');
    final bytes = await api.getBytes('/v1/visits/${visit.id}/pdf');
    await Share.shareXFiles([
      XFile.fromData(Uint8List.fromList(bytes), mimeType: 'application/pdf', name: 'ZN-${visit.id}.pdf'),
    ], text: 'Заказ-наряд № ${visit.id}');
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
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

  Future<void> addCarRemote({
    required String plate,
    required String make,
    required String model,
    int year = 2020,
    int mileage = 0,
    String? vin,
  }) async {
    if (api.token == null) {
      addCar(Vehicle(
        id: 'c${cars.length + 1}',
        plate: plate,
        make: make,
        model: model,
        year: year,
        mileage: mileage,
        vin: vin,
        nextServiceKm: mileage + 10000,
      ));
      return;
    }
    await api.post('/v1/garage', {
      'plate': plate,
      'make': make,
      'model': model,
      'year': year,
      'mileage': mileage,
      if (vin != null && vin.isNotEmpty) 'vin': vin,
    });
    await refreshGarage();
  }

  Future<void> deleteCarRemote(String id) async {
    if (api.token != null) {
      await api.delete('/v1/garage/$id');
      await refreshGarage();
      return;
    }
    cars = cars.where((c) => c.id != id).toList();
    if (activeCarId == id) {
      activeCarId = cars.isEmpty ? '' : cars.first.id;
    }
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

  Future<List<SlotOption>> fetchSlots(DateTime day, String branchId) async {
    final date = DateFormat('yyyy-MM-dd').format(day);
    try {
      final res = await api.get('/v1/slots', query: {'branch_id': branchId, 'date': date});
      final raw = res['slots'];
      if (raw is List) {
        final out = <SlotOption>[];
        for (final item in raw) {
          if (item is! Map) continue;
          final at = DateTime.tryParse('${item['at'] ?? ''}');
          if (at == null) continue;
          out.add(SlotOption(
            at: at,
            label: '${item['label'] ?? DateFormat('HH:mm').format(at)}',
            free: int.tryParse('${item['free'] ?? 1}') ?? 1,
          ));
        }
        return out;
      }
    } catch (_) {}
    return [for (final t in slotsFor(day, branchId: branchId)) SlotOption(at: t, label: DateFormat('HH:mm').format(t))];
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
        v.isHistory = true;
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

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse('$v'.split('.').first) ?? 0;
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
