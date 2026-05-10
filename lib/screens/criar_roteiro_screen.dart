import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:g_route_app/services/roteiro_service.dart';
import 'package:g_route_app/services/mapbox_service.dart';
import 'package:g_route_app/services/image_service.dart';
import 'package:g_route_app/screens/loading_itinerary_screen.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class CriarRoteiroScreen extends StatefulWidget {
  const CriarRoteiroScreen({super.key});

  @override
  State<CriarRoteiroScreen> createState() => _CriarRoteiroScreenState();
}

class _CriarRoteiroScreenState extends State<CriarRoteiroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orcamentoController = TextEditingController();
  final _destinoController = TextEditingController();
  Timer? _debounce;
  
  Map<String, dynamic>? _selectedPlace;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;

  String? _selectedStyle;
  String _selectedPerfil = 'Individual';
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _isLoading = false;
  bool _possuiHospedagem = false;
  String _nivelHospedagem = 'Intermediário';

  final List<String> _perfilOptions = ['Individual', 'Família', 'Casal', 'Amigos'];

  final List<Map<String, dynamic>> _travelStyles = [
    {'name': 'Aventura', 'icon': Icons.terrain},
    {'name': 'Romântica', 'icon': Icons.favorite},
    {'name': 'Cultura', 'icon': Icons.museum},
    {'name': 'Gastronomia', 'icon': Icons.restaurant},
    {'name': 'Luxo', 'icon': Icons.diamond_outlined},
    {'name': 'Econômica', 'icon': Icons.savings_outlined},
  ];

  @override
  void dispose() {
    _destinoController.dispose();
    _orcamentoController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() => _suggestions = []);
        return;
      }

      setState(() => _isSearching = true);
      final results = await MapboxService.searchPlaces(query);
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    });
  }

  Future<void> _selecionarDatas(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dataInicio = picked.start;
        _dataFim = picked.end;
      });
    }
  }

  void _salvarRoteiro() async {
    if (_selectedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecione um destino.')));
      return;
    }
    if (_dataInicio == null || _dataFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecione as datas.')));
      return;
    }

    final orcamento = double.tryParse(_orcamentoController.text.replaceAll(',', '.')) ?? 0.0;

    final tripData = {
      'destino': _selectedPlace!['placeName'],
      'pais': _selectedPlace!['country'],
      'estado': _selectedPlace!['state'],
      'lat': (_selectedPlace!['lat'] as num).toDouble(),
      'lng': (_selectedPlace!['lng'] as num).toDouble(),
      'estilo': _selectedStyle ?? 'Geral',
      'perfil': _selectedPerfil,
      'orcamento': orcamento,
      'dataInicio': _dataInicio!,
      'dataFim': _dataFim!,
      'possuiHospedagem': _possuiHospedagem,
      'nivelHospedagem': _nivelHospedagem,
    };

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoadingItineraryScreen(tripData: tripData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Viagem', style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Para onde você quer ir?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark, letterSpacing: -0.5)),
              const SizedBox(height: 24),

              // Busca Mapbox
              _buildLabel('Destino'),
              TextField(
                controller: _destinoController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Cidade, país ou lugar...",
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryPurple),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
                  suffixIcon: _isSearching ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : null,
                ),
              ),

              // Lista de Sugestões
              if (_suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final place = _suggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryPurple),
                        title: Text(place['placeName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(place['fullName'], style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          setState(() {
                            _selectedPlace = place;
                            _destinoController.text = place['fullName'];
                            _suggestions = [];
                          });
                        },
                      );
                    },
                  ),
                ),

              const SizedBox(height: 32),
              
              // Perfil de Viajante
              _buildLabel('Perfil de Viajante'),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _perfilOptions.map((perfil) {
                    final isSelected = _selectedPerfil == perfil;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(perfil),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedPerfil = perfil),
                        selectedColor: AppTheme.primaryPurple,
                        backgroundColor: Colors.grey[50],
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),

              // Estilo de Viagem
              _buildLabel('Estilo da Viagem'),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _travelStyles.map((style) {
                    final isSelected = _selectedStyle == style['name'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(style['name']),
                        avatar: Icon(style['icon'], size: 16, color: isSelected ? Colors.white : AppTheme.primaryPurple),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedStyle = val ? style['name'] : null),
                        selectedColor: AppTheme.primaryPurple,
                        backgroundColor: Colors.grey[50],
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),

              // Datas
              _buildLabel('Quando?'),
              InkWell(
                onTap: () => _selecionarDatas(context),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryPurple, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _dataInicio == null ? 'Selecionar datas' : '${DateFormat('dd MMM').format(_dataInicio!)} - ${DateFormat('dd MMM').format(_dataFim!)}',
                        style: TextStyle(color: _dataInicio == null ? AppTheme.textGrey : AppTheme.textDark, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Orçamento
              _buildLabel('Orçamento Estimado'),
              TextFormField(
                controller: _orcamentoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Ex: 5000",
                  prefixIcon: const Icon(Icons.attach_money, color: AppTheme.primaryPurple),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),

              const SizedBox(height: 32),

              // HOSPEDAGEM
              _buildLabel('Hospedagem'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SwitchListTile(
                  title: const Text("Já possui hospedagem?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  value: _possuiHospedagem,
                  activeColor: AppTheme.primaryPurple,
                  onChanged: (val) => setState(() => _possuiHospedagem = val),
                ),
              ),

              if (!_possuiHospedagem) ...[
                const SizedBox(height: 20),
                _buildLabel('Nível de Conforto Desejado'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Econômico', 'Intermediário', 'Luxo'].map((nivel) {
                      final isSelected = _nivelHospedagem == nivel;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(nivel),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _nivelHospedagem = nivel),
                          selectedColor: AppTheme.primaryPurple,
                          backgroundColor: Colors.grey[50],
                          labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _salvarRoteiro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CRIAR ROTEIRO MÁGICO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)));
}
