import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:g_route_app/services/financeiro_service.dart';
import 'package:g_route_app/services/cache_service.dart';
import 'package:intl/intl.dart';
import 'package:g_route_app/models/itinerary_model.dart';
import 'package:g_route_app/services/roteiro_service.dart';

class FinanceiroScreen extends StatefulWidget {
  final TripItinerary? itinerarioIA;
  const FinanceiroScreen({super.key, this.itinerarioIA});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  List<Map<String, dynamic>> _expenses = [];
  TripItinerary? _itinerarioIA;
  bool _isLoading = true;
  double _totalAmount = 0.0;
  String _selectedCategory = "Tudo";

  @override
  void initState() {
    super.initState();
    _itinerarioIA = widget.itinerarioIA;
    _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant FinanceiroScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itinerarioIA != oldWidget.itinerarioIA) {
      setState(() {
        _itinerarioIA = widget.itinerarioIA;
        if (_itinerarioIA == null) {
          _expenses = [];
          _totalAmount = 0.0;
        }
        _calculateTotal();
      });
    }
  }

  Future<void> _loadInitialData() async {
    final cachedRoteiro = await CacheService.getData(CacheService.KEY_ACTIVE_ITINERARY);
    if (cachedRoteiro != null) {
      final roteiroId = cachedRoteiro['id'].toString();
      
      // Se não recebemos itinerário, buscar
      if (_itinerarioIA == null) {
        final itinerario = await RoteiroService.getItinerarioCompleto(roteiroId);
        if (mounted) setState(() => _itinerarioIA = itinerario);
      }

      final cachedExpenses = await CacheService.getData('expenses_$roteiroId');
      
      if (mounted) {
        setState(() {
          if (cachedExpenses != null) _expenses = (cachedExpenses as List).map((i) => Map<String, dynamic>.from(i)).toList();
          _calculateTotal();
          _isLoading = false;
        });
      }

      final freshExpenses = await FinanceiroService.fetchExpenses(roteiroId);
      if (mounted) {
        setState(() {
          _expenses = freshExpenses;
          _calculateTotal();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _itinerarioIA = null;
          _expenses = [];
          _totalAmount = 0.0;
          _isLoading = false;
        });
      }
    }
  }

  void _calculateTotal() {
    _totalAmount = _expenses.fold(0.0, (sum, item) => sum + (item['valor'] as num).toDouble());
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'alimentação': return Icons.restaurant;
      case 'hospedagem': return Icons.hotel;
      case 'lazer': return Icons.directions_boat;
      case 'transporte': return Icons.directions_bus;
      case 'compras': return Icons.shopping_bag;
      default: return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _selectedCategory == "Tudo" 
        ? _expenses 
        : _expenses.where((e) => e['categoria'] == _selectedCategory).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        color: AppTheme.primaryPurple,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.primaryPurple,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text("Gestão Financeira", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                background: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryPurple, Color(0xFF7B2FF7)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          const SizedBox(height: 30),
                          Text(_itinerarioIA != null ? "Orçamento: ${_itinerarioIA!.configuracaoUsuario.orcamentoReferencia}" : "Total Gasto", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                          Text("${_itinerarioIA?.configuracaoUsuario.moedaOrigem ?? 'R\$'} ${_totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                          if (_itinerarioIA != null)
                             Padding(
                               padding: const EdgeInsets.only(top: 8),
                               child: Text("Câmbio: ${_itinerarioIA!.destinoInfo.cambio.cotacaoEstimada}", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                             ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (_itinerarioIA != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade100)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 15),
                      Expanded(child: Text("Dica de Câmbio: ${_itinerarioIA!.destinoInfo.cambio.melhorFormaPagamento}", style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ),

            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: _buildCategoryFilters())),

            if (_isLoading && _expenses.isEmpty) const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.only(top: 50), child: CircularProgressIndicator(color: AppTheme.primaryPurple))))
            else if (_expenses.isEmpty) const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("Nenhuma despesa cadastrada.", style: TextStyle(color: AppTheme.textGrey)))))
            else SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) => _buildExpenseTile(filteredExpenses[index]), childCount: filteredExpenses.length))),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, 
        backgroundColor: AppTheme.primaryPurple, 
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30)
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = ["Tudo", "Alimentação", "Hospedagem", "Lazer", "Transporte", "Compras"];
    return SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), physics: const BouncingScrollPhysics(), child: Row(children: categories.map((cat) { bool isSelected = cat == _selectedCategory; return Padding(padding: const EdgeInsets.only(right: 12), child: FilterChip(label: Text(cat), selected: isSelected, onSelected: (val) => setState(() => _selectedCategory = cat), backgroundColor: Colors.grey[50], selectedColor: AppTheme.primaryPurple.withOpacity(0.1), labelStyle: TextStyle(color: isSelected ? AppTheme.primaryPurple : AppTheme.textGrey, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: isSelected ? AppTheme.primaryPurple.withOpacity(0.3) : Colors.grey[200]!))); }).toList()));
  }

  Widget _buildExpenseTile(Map<String, dynamic> expense) {
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[100]!), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primaryPurple.withOpacity(0.05), shape: BoxShape.circle), child: Icon(_getIconForCategory(expense['categoria'] ?? ''), color: AppTheme.primaryPurple, size: 22)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(expense['titulo'] ?? 'Despesa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text("${expense['categoria']} • ${expense['data']}", style: const TextStyle(fontSize: 11, color: AppTheme.textGrey))])), Text("- ${(expense['valor'] as num).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.redAccent))]));
  }
}
