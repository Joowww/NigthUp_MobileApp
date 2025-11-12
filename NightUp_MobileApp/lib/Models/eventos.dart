class Evento {
  final String id;
  final String name;
  final String schedule;
  final String address;
  final int? capacidadMaxima;
  final List<String> apuntados;

  Evento({
    required this.id,
    required this.name,
    required this.schedule,
    required this.address,
    this.capacidadMaxima,
    required this.apuntados,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['_id'],
      name: json['name'],
      schedule: json['schedule'],
      address: json['address'] ?? '',
      capacidadMaxima: json['capacidadMaxima'],
      apuntados: List<String>.from(json['apuntados'] ?? []),
    );
  }
}
