import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:g_route_app/services/roteiro_service.dart';
import 'package:g_route_app/services/image_service.dart';
import 'package:g_route_app/services/gemini_service.dart';
import 'package:g_route_app/services/cache_service.dart';
import 'package:g_route_app/models/itinerary_model.dart';
import 'package:g_route_app/widgets/travel_loading_widget.dart';
import 'dart:async';

class LoadingItineraryScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const LoadingItineraryScreen({super.key, required this.tripData});

  @override
  State<LoadingItineraryScreen> createState() => _LoadingItineraryScreenState();
}

class _LoadingItineraryScreenState extends State<LoadingItineraryScreen> {
  int _messageIndex = 0;
  Timer? _timer;
  
  final List<String> _messages = [
    "Iniciando seu planejamento personalizado...",
    "Ajustando o GPS da sua aventura...",
    "Consultando os melhores pontos turísticos...",
    "Buscando as melhores opções de hospedagem...",
    "Explorando dicas exclusivas de locais...",
    "Preparando o check-in dos seus sonhos...",
    "Sincronizando as melhores rotas...",
    "Descobrindo tesouros escondidos no destino...",
    "Consultando o clima para sua diversão...",
    "Garantindo que cada minuto seja inesquecível...",
    "Organizando sua mala digital...",
    "Finalizando os detalhes mágicos...",
    "Quase lá! Aperte os cintos...",
  ];

  @override
  void initState() {
    super.initState();
    _startMessageCycle();
    _createAndPrepareItinerary();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMessageCycle() {
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    });
  }

  Future<void> _createAndPrepareItinerary() async {
    try {
      final startTime = DateTime.now();

      // 1. Salvar estrutura básica no Supabase
      final roteiroId = await RoteiroService.criarRoteiro(
        destino: widget.tripData['destino'],
        pais: widget.tripData['pais'],
        estado: widget.tripData['estado'],
        lat: widget.tripData['lat'],
        lng: widget.tripData['lng'],
        estilo: widget.tripData['estilo'] ?? 'Aventura',
        dataInicio: widget.tripData['dataInicio'],
        dataFim: widget.tripData['dataFim'],
        orcamento: widget.tripData['orcamento'] ?? 0.0,
      );

      if (roteiroId != null) {
        // Calcular número de dias
        final inicio = widget.tripData['dataInicio'] as DateTime;
        final fim = widget.tripData['dataFim'] as DateTime;
        final dias = fim.difference(inicio).inDays + 1;

        // 2. Chamar o Gemini AI para gerar o Roteiro
        final roteiroJson = await GeminiService.gerarRoteiroJSON(
          destino: widget.tripData['destino'],
          orcamento: widget.tripData['orcamento'] ?? 0.0,
          estilo: widget.tripData['estilo'] ?? 'Geral',
          perfil: widget.tripData['perfil'] ?? 'Individual',
          dias: dias,
          hospedagemRequerida: !(widget.tripData['possuiHospedagem'] ?? false),
          nivelHospedagem: widget.tripData['nivelHospedagem'] ?? 'Intermediário',
        );

        // 3. Salvar os pontos do roteiro_diario no Supabase
        final diario = roteiroJson['roteiro_diario'] as List?;
        if (diario != null) {
          for (var diaData in diario) {
            final atividades = diaData['atividades'] as List?;
            if (atividades != null) {
              for (var att in atividades) {
                final coords = att['coordenadas'];
                await RoteiroService.salvarPonto(
                  roteiroId: roteiroId,
                  nome: att['local'],
                  lat: (coords != null && coords['lat'] != null) ? (coords['lat'] as num).toDouble() : widget.tripData['lat'],
                  lng: (coords != null && coords['lng'] != null) ? (coords['lng'] as num).toDouble() : widget.tripData['lng'],
                  categoria: diaData['tema'] ?? 'Atividade',
                );
              }
            }
          }
        }

        // 4. Salvar o JSON completo no Cache Local
        await CacheService.saveData('roteiro_json_$roteiroId', roteiroJson);

        // 5. ENRIQUECIMENTO VISUAL
        final itinerario = TripItinerary.fromJson(roteiroJson);
        final itinerarioEnriquecido = await ImageService.enrichItinerary(itinerario);
        
        final jsonFinal = itinerarioEnriquecido.toJson();
        await CacheService.saveData('roteiro_json_$roteiroId', jsonFinal);
        await RoteiroService.salvarDadosIA(roteiroId, jsonFinal);
        await CacheService.saveData(CacheService.KEY_ACTIVE_ITINERARY, {
          'id': roteiroId,
          'destino': widget.tripData['destino'],
          'pais': widget.tripData['pais'],
        });

        // Garante que a tela de loading dure pelo menos 5 segundos
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        if (duration.inSeconds < 5) {
          await Future.delayed(Duration(seconds: 5 - duration.inSeconds));
        }

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        }
      } else {
        throw Exception("Erro ao criar roteiro no banco");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ocorreu um erro: $e"), backgroundColor: Colors.redAccent),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF0EFFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TravelLoadingWidget(size: 320),
                const SizedBox(height: 50),
                
                // Texto de carregamento com animação
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    key: ValueKey<int>(_messageIndex),
                    children: [
                      Text(
                        _messages[_messageIndex],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
