import 'package:flutter/foundation.dart';

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
    this.works = const [],
  });

  final String id;
  final String serviceTitle;
  final String branchName;
  final String carPlate;
  final DateTime when;
  String status;
  final int? amount;
  final List<String> works;
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
  bool loggedIn = false;
  String phone = '+7 900 123-45-67';
  String clientName = 'Алексей';
  int bonus = 1840;
  String activeCarId = 'c1';

  final branches = [
    Branch(
      id: 'b1',
      name: 'DRIVE на Ленина',
      address: 'ул. Ленина, 42',
      phone: '+7 345 268-00-11',
      hours: 'Пн–Сб 09:00–21:00',
      distanceKm: 1.8,
      services: ['ТО', 'Диагностика', 'Шиномонтаж', 'Масло'],
    ),
    Branch(
      id: 'b2',
      name: 'DRIVE Южный',
      address: 'ул. Республики, 158',
      phone: '+7 345 268-00-22',
      hours: 'Ежедневно 08:00–22:00',
      distanceKm: 4.3,
      services: ['ТО', 'Кузов', 'Шиномонтаж'],
    ),
    Branch(
      id: 'b3',
      name: 'DRIVE Заречный',
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
      make: 'Toyota',
      model: 'Camry',
      year: 2019,
      mileage: 86420,
      vin: 'JTNB11HK40K123456',
      nextServiceKm: 90000,
    ),
    Vehicle(
      id: 'c2',
      plate: 'К 777 КК 72',
      make: 'Kia',
      model: 'Sportage',
      year: 2021,
      mileage: 41200,
      nextServiceKm: 45000,
    ),
  ];

  late List<Visit> visits = [
    Visit(
      id: 'v1',
      serviceTitle: 'Замена масла',
      branchName: 'DRIVE на Ленина',
      carPlate: 'А 123 ВС 72',
      when: DateTime.now().add(const Duration(days: 2, hours: 4)),
      status: 'подтверждена',
    ),
    Visit(
      id: 'v2',
      serviceTitle: 'ТО-2 + тормоза',
      branchName: 'DRIVE Южный',
      carPlate: 'А 123 ВС 72',
      when: DateTime.now().subtract(const Duration(days: 86)),
      status: 'выполнен',
      amount: 24890,
      works: ['Замена масла 5W-30', 'Фильтр салона', 'Колодки передние', 'Диагностика'],
    ),
    Visit(
      id: 'v3',
      serviceTitle: 'Шиномонтаж',
      branchName: 'DRIVE на Ленина',
      carPlate: 'К 777 КК 72',
      when: DateTime.now().subtract(const Duration(days: 140)),
      status: 'выполнен',
      amount: 2200,
      works: ['Смена комплекта R17', 'Балансировка'],
    ),
  ];

  final repairSteps = [
    RepairStep(title: 'Принят на пост', at: DateTime.now().subtract(const Duration(hours: 5)), done: true, detail: 'Мастер Иван'),
    RepairStep(title: 'Диагностика', at: DateTime.now().subtract(const Duration(hours: 4)), done: true, detail: 'Рекомендована замена колодок'),
    RepairStep(title: 'Ожидание запчастей', at: DateTime.now().subtract(const Duration(hours: 2)), done: true, detail: 'Колодки в пути, STOCRM'),
    RepairStep(title: 'Ремонт', at: DateTime.now().add(const Duration(hours: 1)), done: false, detail: 'Ориентир 17:30'),
    RepairStep(title: 'Готов к выдаче', at: DateTime.now().add(const Duration(hours: 3)), done: false),
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
    ChatMessage(fromStaff: true, text: 'Здравствуйте, Алексей! Это DRIVE СТО. Чем помочь?'),
    ChatMessage(fromStaff: false, text: 'Можно записаться на замену масла завтра утром?'),
    ChatMessage(fromStaff: true, text: 'Да. На Ленина свободно 10:00 и 11:30. Запись уйдёт в STOCRM как сделка «Онлайн-запись».'),
  ];

  Vehicle get activeCar => cars.firstWhere((c) => c.id == activeCarId, orElse: () => cars.first);

  Visit? get nextVisit {
    final upcoming = visits.where((v) => v.when.isAfter(DateTime.now()) && v.status != 'отменена').toList()
      ..sort((a, b) => a.when.compareTo(b.when));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  List<Visit> get upcoming =>
      visits.where((v) => v.status != 'выполнен' && v.status != 'отменена').toList();

  List<Visit> get history => visits.where((v) => v.status == 'выполнен' || v.status == 'отменена').toList();

  void login(String value) {
    loggedIn = true;
    phone = value;
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
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

  List<DateTime> slotsFor(DateTime day) {
    final base = DateTime(day.year, day.month, day.day, 9);
    return List.generate(10, (i) => base.add(Duration(minutes: 60 * i))).where((t) => t.hour < 20).toList();
  }

  void addVisit({
    required ServiceItem service,
    required Branch branch,
    required DateTime when,
    required Vehicle car,
  }) {
    visits = [
      Visit(
        id: 'v${visits.length + 1}',
        serviceTitle: service.title,
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
      text: 'Приняли. В боевой версии сообщение уйдёт мастеру-консультанту, заявка — в STOCRM.',
    ));
    notifyListeners();
  }
}
