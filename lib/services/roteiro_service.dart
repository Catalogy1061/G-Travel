import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:g_route_app/models/itinerary_model.dart';
import 'package:g_route_app/services/cache_service.dart';

class RoteiroService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Busca todos os roteiros do usuário logado
  static Future<List<Map<String, dynamic>>> fetchRoteiros() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('roteiros')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar roteiros: \$e');
      return [];
    }
  }

  static Future<String?> criarRoteiro({
    required String destino,
    required String? pais,
    required String? estado,
    required double lat,
    required double lng,
    DateTime? dataInicio,
    DateTime? dataFim,
    double? orcamento,
    String? estilo,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // --- REMOVIDA A REGRA DE DELETAR ROTEIRO ÚNICO PARA SUPORTAR SaaS ---
      // No futuro, podemos marcar o anterior como 'arquivado'

      final response = await _supabase.from('roteiros').insert({
        'user_id': userId,
        'destino': destino,
        'pais': pais,
        'estado': estado,
        'lat': lat,
        'lng': lng,
        'data_inicio': dataInicio?.toIso8601String(),
        'data_fim': dataFim?.toIso8601String(),
        'orcamento': orcamento,
        'estilo_viagem': estilo,
      }).select('id').single();
      return response['id'];
    } catch (e) {
      print('Erro ao criar roteiro: $e');
      return null;
    }
  }

  /// Salva os dados de forma normalizada em múltiplas tabelas
  static Future<void> salvarDadosIA(String roteiroId, Map<String, dynamic> json) async {
    try {
      final itinerary = TripItinerary.fromJson(json);
      print('--- INICIANDO SALVAMENTO NORMALIZADO ---');
      print('Destino: ${itinerary.configuracaoUsuario.destinoSolicitado}');
      
      // 0. Limpeza preventiva de dias existentes (Cascata apaga atividades/gastronomia)
      await _supabase.from('roteiro_dias').delete().eq('roteiro_id', roteiroId);

      // 1. Atualizar dados principais e dicas
      await _supabase.from('roteiros').update({
        'dados_ia': json, // Backup
        'dicas_locais': itinerary.dicasLocais,
      }).eq('id', roteiroId);
      print('1. Cabeçalho e Dicas atualizados.');

      // 2. Hospedagem
      if (itinerary.hospedagem != null) {
        final h = itinerary.hospedagem!;
        await _supabase.from('roteiro_hospedagem').upsert({
          'roteiro_id': roteiroId,
          'status': h.status,
          'nome': h.nome,
          'tipo': h.tipo,
          'endereco': h.endereco,
          'custo_estimado': h.custoEstimado,
          'lat': h.coordenadas?.lat,
          'lng': h.coordenadas?.lng,
          'motivo_sugestao': h.motivoSugestao,
          'link_referencia': h.linkReferencia,
          'image_url': h.imageUrl,
        });
        print('2. Hospedagem salva.');
      }

      // 3. Destino Info
      final di = itinerary.destinoInfo;
      await _supabase.from('roteiro_destino_info').upsert({
        'roteiro_id': roteiroId,
        'nome_oficial': di.nomeOficial,
        'fuso_horario': di.fusoHorario,
        'clima_descricao': di.climaEsperado.descricao,
        'clima_temp_media': di.climaEsperado.tempMedia,
        'visto_obrigatorio': di.documentacao.vistoObrigatorio,
        'seguro_viagem_obrigatorio': di.documentacao.seguroViagemObrigatorio,
        'moeda_local': di.cambio.moedaLocal,
        'cotacao_estimada': di.cambio.cotacaoEstimada,
        'melhor_forma_pagamento': di.cambio.melhorFormaPagamento,
      });
      print('3. Info do Destino salva.');

      // 4. Logística
      final log = itinerary.logistica;
      await _supabase.from('roteiro_logistica').upsert({
        'roteiro_id': roteiroId,
        'aeroporto_principal': log.chegada.aeroportoPrincipal,
        'melhor_app_transporte': log.locomocaoInterna.melhorApp,
        'passe_transporte': log.locomocaoInterna.passeTransporte,
        'dica_economia': log.locomocaoInterna.dicaEconomia,
        'transporte_centro': log.chegada.transporteParaCentro,
      });
      print('4. Logística salva.');

      // 5. Guia Local
      final guia = itinerary.guiaLocal;
      await _supabase.from('roteiro_guia_local').upsert({
        'roteiro_id': roteiroId,
        'nivel_alerta_seguranca': guia.seguranca.nivelAlerta,
        'telefones_emergencia': guia.saudeEmergencia.telefones,
        'farmacias_populares': guia.saudeEmergencia.farmaciasPopulares,
        'regras_sociais': guia.etiquetaECultura.regrasSociais,
        'gorjetas': guia.etiquetaECultura.gorjetas,
        'golpes_comuns': guia.seguranca.golpesComuns,
        'bairros_perigosos': guia.seguranca.bairrosPerigosos,
        'hospitais_proximos': guia.saudeEmergencia.hospitaisProximos,
        'frases_sobrevivencia': guia.etiquetaECultura.frasesSobrevivencia,
      });
      print('5. Guia Local salvo.');

      // 6. Comércio e Utilidades
      final util = itinerary.comercioEUtilidades;
      await _supabase.from('roteiro_utilidades').upsert({
        'roteiro_id': roteiroId,
        'supermercados_baratos': util.supermercadosBaratos,
        'melhores_areas_compras': util.melhoresAreasCompras,
        'lojas_conveniencia': util.lojasConveniencia,
      });
      print('6. Utilidades salvas.');
      
      // 8. Tickets e Atrações
      if (itinerary.ticketsEAtracoes.isNotEmpty) {
        await _supabase.from('roteiro_tickets').delete().eq('roteiro_id', roteiroId);
        final ticketsData = itinerary.ticketsEAtracoes.map((t) => {
          'roteiro_id': roteiroId,
          'nome': t.nome,
          'tipo': t.tipo,
          'custo_estimado': t.custoEstimado,
          'link_oficial': t.linkOficial,
          'dica_seguranca': t.dicaSeguranca,
          'is_oficial': t.isOficial,
          'data_evento': t.dataEvento,
          'image_url': t.imageUrl,
        }).toList();
        await _supabase.from('roteiro_tickets').insert(ticketsData);
        print('8. ${ticketsData.length} Tickets e Atrações salvos.');
      }

      // 7. Dias e Atividades
      print('7. Iniciando salvamento de ${itinerary.roteiroDiario.length} dias...');
      for (var dia in itinerary.roteiroDiario) {
        // Upsert do dia
        final diaData = await _supabase.from('roteiro_dias').upsert({
          'roteiro_id': roteiroId,
          'dia': dia.dia,
          'tema': dia.tema,
        }).select('id').maybeSingle();

        if (diaData == null) continue;
        final diaId = diaData['id'];
        print('   - Dia ${dia.dia} salvo (ID: $diaId). Salvando gastronomia e atividades...');

        // Gastronomia do dia
        await _supabase.from('roteiro_gastronomia').upsert({
          'dia_id': diaId,
          'restaurante_sugerido': dia.gastronomia.restauranteSugerido,
          'prato_tipico': dia.gastronomia.pratoTipico,
          'preco_medio': dia.gastronomia.precoMedio,
          'lat': dia.gastronomia.localizacao.lat,
          'lng': dia.gastronomia.localizacao.lng,
        });

        // Atividades do dia
        for (var ativ in dia.atividades) {
          await _supabase.from('roteiro_atividades').insert({
            'dia_id': diaId,
            'horario': ativ.horarioSugerido,
            'local': ativ.local,
            'lat': ativ.coordenadas.lat,
            'lng': ativ.coordenadas.lng,
            'descricao': ativ.descricaoAtividade,
            'custo_estimado': ativ.custoEstimado,
            'reserva_antecipada': ativ.reservaAntecipada,
            'link_referencia': ativ.linkReferencia,
            'hack_local': ativ.hackLocal,
          });
        }
      }

      // 9. Salvar Opções de Locação
      if (itinerary.logistica.opcoesLocacao.isNotEmpty) {
        await _supabase.from('roteiro_locadoras').delete().eq('viagem_id', roteiroId);
        final locadorasData = itinerary.logistica.opcoesLocacao.map((l) => {
          'viagem_id': roteiroId,
          'nome': l.nome,
          'endereco': l.endereco,
          'site_oficial': l.siteOficial,
          'tipo_veiculo': l.tipoVeiculo,
        }).toList();
        
        await _supabase.from('roteiro_locadoras').insert(locadorasData);
        print('9. ${locadorasData.length} Opções de Locação salvas.');
      }

      // 8. Limpar cache para garantir que as telas leiam os dados novos
      await CacheService.removeData('itinerary_v3_$roteiroId');
      
      print('--- SALVAMENTO CONCLUÍDO COM SUCESSO ---');
    } catch (e) {
      print('ERRO CRÍTICO NO SALVAMENTO NORMALIZADO: $e');
    }
  }

  /// Busca o itinerário completo usando JOINs (Performance SaaS)
  static Future<TripItinerary?> getItinerarioCompleto(String roteiroId, {bool forceRefresh = false}) async {
    try {
      // 1. Cache Local v3 (Versionado)
      if (!forceRefresh) {
        final cachedData = await CacheService.getData('itinerary_v3_$roteiroId');
        if (cachedData != null) {
          final it = TripItinerary.fromJson(Map<String, dynamic>.from(cachedData));
          // Se o cache não tem imagem mas é um campo que deveria ter, forçamos o refresh do banco
          if (it.hospedagem != null && it.hospedagem!.imageUrl == null) {
            print('G-ROUTE: Cache sem imagem, forçando busca no banco...');
          } else {
            return it;
          }
        }
      }

      // 2. Busca Normalizada com Joins
      final response = await _supabase
          .from('roteiros')
          .select('''
            *,
            roteiro_hospedagem(*),
            roteiro_destino_info(*),
            roteiro_logistica(*),
            roteiro_utilidades(*),
            roteiro_tickets(*),
            roteiro_locadoras(*),
            roteiro_dias(
              *,
              roteiro_gastronomia(*),
              roteiro_atividades(*)
            ),
            roteiro_guia_local(*)
          ''')
          .eq('id', roteiroId)
          .maybeSingle();

      if (response != null) {
        final itinerary = TripItinerary.fromSupabaseMap(response);
        
        // Salva no cache a versão serializada
        await CacheService.saveData('itinerary_v3_$roteiroId', itinerary.toJson());
        
        return itinerary;
      }
    } catch (e) {
      print('Erro ao obter itinerário normalizado: $e');
    }
    return null;
  }

  // Deleta um roteiro
  static Future<bool> deletarRoteiro(String roteiroId) async {
    try {
      await _supabase.from('roteiros').delete().eq('id', roteiroId);
      return true;
    } catch (e) {
      print('Erro ao deletar roteiro: $e');
      return false;
    }
  }

  // --- Métodos para Pontos de Interesse (POIs) ---

  static Future<List<Map<String, dynamic>>> fetchPontos(String roteiroId) async {
    try {
      final response = await _supabase
          .from('roteiro_pontos')
          .select()
          .eq('roteiro_id', roteiroId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar pontos: $e');
      return [];
    }
  }

  static Future<bool> salvarPonto({
    required String roteiroId,
    required String nome,
    required double lat,
    required double lng,
    String? categoria,
  }) async {
    try {
      await _supabase.from('roteiro_pontos').insert({
        'roteiro_id': roteiroId,
        'nome': nome,
        'lat': lat,
        'lng': lng,
        'categoria': categoria,
      });
      return true;
    } catch (e) {
      print('Erro ao salvar ponto: $e');
      return false;
    }
  }

  static Future<bool> deletarPonto(String pontoId) async {
    try {
      await _supabase.from('roteiro_pontos').delete().eq('id', pontoId);
      return true;
    } catch (e) {
      print('Erro ao deletar ponto: $e');
      return false;
    }
  }
}
