class TravelHistory {
  final String id;
  final String userId;
  final String destination;
  final String style;
  final double? budget;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? profile;
  final int? durationDays;
  final DateTime completionDate;

  TravelHistory({
    required this.id,
    required this.userId,
    required this.destination,
    required this.style,
    this.budget,
    this.startDate,
    this.endDate,
    this.profile,
    this.durationDays,
    required this.completionDate,
  });

  factory TravelHistory.fromJson(Map<String, dynamic> json) => TravelHistory(
    id: json['id'],
    userId: json['user_id'],
    destination: json['destination'],
    style: json['style'] ?? 'Geral',
    budget: (json['orcamento'] as num?)?.toDouble(),
    startDate: json['data_inicio'] != null ? DateTime.parse(json['data_inicio']) : null,
    endDate: json['data_fim'] != null ? DateTime.parse(json['data_fim']) : null,
    profile: json['perfil'],
    durationDays: json['duracao_dias'],
    completionDate: DateTime.parse(json['completion_date']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'destination': destination,
    'style': style,
    'orcamento': budget,
    'data_inicio': startDate?.toIso8601String(),
    'data_fim': endDate?.toIso8601String(),
    'perfil': profile,
    'duracao_dias': durationDays,
    'completion_date': completionDate.toIso8601String(),
  };
}
