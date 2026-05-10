import 'dart:convert';

class TripItinerary {
  final String viagemId;
  final UserConfig configuracaoUsuario;
  final DestinoInfo destinoInfo;
  final Logistica logistica;
  final List<RoteiroDiario> roteiroDiario;
  final GuiaLocal guiaLocal;
  final ComercioEUtilidades comercioEUtilidades;
  final List<String> dicasLocais;
  final Hospedagem? hospedagem;
  final List<AtracaoTicket> ticketsEAtracoes;

  TripItinerary({
    required this.viagemId,
    required this.configuracaoUsuario,
    required this.destinoInfo,
    required this.logistica,
    required this.roteiroDiario,
    required this.guiaLocal,
    required this.comercioEUtilidades,
    required this.dicasLocais,
    required this.ticketsEAtracoes,
    this.hospedagem,
  });

  factory TripItinerary.fromJson(Map<String, dynamic> json) {
    // Consolidar dicas de várias partes se o campo específico não existir
    List<String> dicasConsolidadas = [];
    if (json['dicas_locais'] != null) {
      dicasConsolidadas = List<String>.from(json['dicas_locais']);
    } else {
      // Tentar pegar do hack local do primeiro dia ou dicas de economia
      final logistica = json['logistica'];
      if (logistica != null && logistica['locomocao_interna'] != null) {
        dicasConsolidadas.add("Dica de Transporte: ${logistica['locomocao_interna']['dica_economia']}");
      }
      final guia = json['guia_local'];
      if (guia != null && guia['etiqueta_e_cultura'] != null) {
        dicasConsolidadas.add("Cultura: ${guia['etiqueta_e_cultura']['regras_sociais']}");
      }
    }

    return TripItinerary(
      viagemId: json['viagem_id'] ?? '',
      configuracaoUsuario: UserConfig.fromJson(json['configuracao_usuario'] ?? {}),
      destinoInfo: DestinoInfo.fromJson(json['destino_info'] ?? {}),
      hospedagem: json['hospedagem'] != null ? Hospedagem.fromJson(json['hospedagem']) : null,
      logistica: Logistica.fromJson(json['logistica'] ?? {}),
      roteiroDiario: (json['roteiro_diario'] as List? ?? [])
          .map((i) => RoteiroDiario.fromJson(i))
          .toList(),
      guiaLocal: GuiaLocal.fromJson(json['guia_local'] ?? {}),
      comercioEUtilidades: ComercioEUtilidades.fromJson(json['comercio_e_utilidades'] ?? {}),
      dicasLocais: dicasConsolidadas,
      ticketsEAtracoes: (json['tickets_e_atracoes'] as List? ?? [])
          .map((i) => AtracaoTicket.fromJson(i))
          .toList(),
    );
  }

  /// Constrói o modelo a partir dos dados normalizados do Supabase (Joins)
  factory TripItinerary.fromSupabaseMap(Map<String, dynamic> map) {
    // Nota: Supabase retorna joins como listas de objetos ou objetos únicos dependendo da query
    final hospedagemData = map['roteiro_hospedagem'];
    final destinoData = map['roteiro_destino_info'];
    final logisticaData = map['roteiro_logistica'];
    final guiaData = map['roteiro_guia_local'];
    final utilidadesData = map['roteiro_utilidades'];

    return TripItinerary(
      viagemId: map['id'] ?? '',
      configuracaoUsuario: UserConfig(
        destinoSolicitado: map['destino'] ?? '',
        moedaOrigem: 'BRL',
        orcamentoReferencia: (map['orcamento'] ?? 0).toString(),
        perfil: map['estilo_viagem'] ?? '',
      ),
      destinoInfo: DestinoInfo.fromSupabase(destinoData is List ? (destinoData.isNotEmpty ? destinoData[0] : {}) : (destinoData ?? {})),
      logistica: Logistica.fromSupabase(
        logisticaData is List ? (logisticaData.isNotEmpty ? logisticaData[0] : {}) : (logisticaData ?? {}),
        locadoras: map['roteiro_locadoras'] as List?,
      ),
      roteiroDiario: (map['roteiro_dias'] as List? ?? [])
          .map((d) => RoteiroDiario.fromSupabase(d))
          .toList(),
      guiaLocal: GuiaLocal.fromSupabase(guiaData is List ? (guiaData.isNotEmpty ? guiaData[0] : {}) : (guiaData ?? {})),
      comercioEUtilidades: ComercioEUtilidades.fromSupabase(utilidadesData is List ? (utilidadesData.isNotEmpty ? utilidadesData[0] : {}) : (utilidadesData ?? {})),
      dicasLocais: List<String>.from(map['dicas_locais'] ?? []),
      hospedagem: hospedagemData != null && (hospedagemData is! List || hospedagemData.isNotEmpty)
          ? Hospedagem.fromSupabase(hospedagemData is List ? hospedagemData[0] : hospedagemData)
          : null,
      ticketsEAtracoes: (map['roteiro_tickets'] as List? ?? [])
          .map((t) => AtracaoTicket.fromSupabase(t))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'viagem_id': viagemId,
    'configuracao_usuario': configuracaoUsuario.toJson(),
    'destino_info': destinoInfo.toJson(),
    'logistica': logistica.toJson(),
    'roteiro_diario': roteiroDiario.map((i) => i.toJson()).toList(),
    'guia_local': guiaLocal.toJson(),
    'comercio_e_utilidades': comercioEUtilidades.toJson(),
    'dicas_locais': dicasLocais,
    'hospedagem': hospedagem?.toJson(),
    'tickets_e_atracoes': ticketsEAtracoes.map((t) => t.toJson()).toList(),
  };
}

class UserConfig {
  final String destinoSolicitado;
  final String moedaOrigem;
  final String orcamentoReferencia;
  final String perfil;

  UserConfig({
    required this.destinoSolicitado,
    required this.moedaOrigem,
    required this.orcamentoReferencia,
    required this.perfil,
  });

  factory UserConfig.fromJson(Map<String, dynamic> json) {
    return UserConfig(
      destinoSolicitado: json['destino_solicitado'] ?? '',
      moedaOrigem: json['moeda_origem'] ?? 'BRL',
      orcamentoReferencia: json['orcamento_referencia'] ?? '',
      perfil: json['perfil'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'destino_solicitado': destinoSolicitado,
    'moeda_origem': moedaOrigem,
    'orcamento_referencia': orcamentoReferencia,
    'perfil': perfil,
  };
}

class DestinoInfo {
  final String nomeOficial;
  final String fusoHorario;
  final ClimaEsperado climaEsperado;
  final Documentacao documentacao;
  final Cambio cambio;

  DestinoInfo({
    required this.nomeOficial,
    required this.fusoHorario,
    required this.climaEsperado,
    required this.documentacao,
    required this.cambio,
  });

  factory DestinoInfo.fromJson(Map<String, dynamic> json) {
    return DestinoInfo(
      nomeOficial: json['nome_oficial'] ?? '',
      fusoHorario: json['fuso_horario'] ?? '',
      climaEsperado: ClimaEsperado.fromJson(json['clima_esperado'] ?? {}),
      documentacao: Documentacao.fromJson(json['documentacao'] ?? {}),
      cambio: Cambio.fromJson(json['cambio'] ?? {}),
    );
  }

  factory DestinoInfo.fromSupabase(Map<String, dynamic> map) {
    return DestinoInfo(
      nomeOficial: map['nome_oficial'] ?? '',
      fusoHorario: map['fuso_horario'] ?? '',
      climaEsperado: ClimaEsperado(
        descricao: map['clima_descricao'] ?? '',
        tempMedia: map['clima_temp_media'] ?? '',
      ),
      documentacao: Documentacao(
        vistoObrigatorio: map['visto_obrigatorio'] ?? false,
        vacinasExigidas: [], // TODO: Tabela separada se necessário
        seguroViagemObrigatorio: map['seguro_viagem_obrigatorio'] ?? false,
      ),
      cambio: Cambio(
        moedaLocal: map['moeda_local'] ?? '',
        cotacaoEstimada: map['cotacao_estimada'] ?? '',
        melhorFormaPagamento: map['melhor_forma_pagamento'] ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'nome_oficial': nomeOficial,
    'fuso_horario': fusoHorario,
    'clima_esperado': climaEsperado.toJson(),
    'documentacao': documentacao.toJson(),
    'cambio': cambio.toJson(),
  };
}

class ClimaEsperado {
  final String descricao;
  final String tempMedia;

  ClimaEsperado({required this.descricao, required this.tempMedia});

  factory ClimaEsperado.fromJson(Map<String, dynamic> json) {
    return ClimaEsperado(
      descricao: json['descricao'] ?? '',
      tempMedia: json['temp_media'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'descricao': descricao,
    'temp_media': tempMedia,
  };
}

class Documentacao {
  final bool vistoObrigatorio;
  final List<String> vacinasExigidas;
  final bool seguroViagemObrigatorio;

  Documentacao({
    required this.vistoObrigatorio,
    required this.vacinasExigidas,
    required this.seguroViagemObrigatorio,
  });

  factory Documentacao.fromJson(Map<String, dynamic> json) {
    return Documentacao(
      vistoObrigatorio: json['visto_obrigatorio'] ?? false,
      vacinasExigidas: List<String>.from(json['vacinas_exigidas'] ?? []),
      seguroViagemObrigatorio: json['seguro_viagem_obrigatorio'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'visto_obrigatorio': vistoObrigatorio,
    'vacinas_exigidas': vacinasExigidas,
    'seguro_viagem_obrigatorio': seguroViagemObrigatorio,
  };
}

class Cambio {
  final String moedaLocal;
  final String cotacaoEstimada;
  final String melhorFormaPagamento;

  Cambio({
    required this.moedaLocal,
    required this.cotacaoEstimada,
    required this.melhorFormaPagamento,
  });

  factory Cambio.fromJson(Map<String, dynamic> json) {
    return Cambio(
      moedaLocal: json['moeda_local'] ?? '',
      cotacaoEstimada: json['cotacao_estimada'] ?? '',
      melhorFormaPagamento: json['melhor_forma_pagamento'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'moeda_local': moedaLocal,
    'cotacao_estimada': cotacaoEstimada,
    'melhor_forma_pagamento': melhorFormaPagamento,
  };
}

class Logistica {
  final Chegada chegada;
  final LocomocaoInterna locomocaoInterna;
  final List<LocadoraOpcao> opcoesLocacao;

  Logistica({
    required this.chegada, 
    required this.locomocaoInterna,
    this.opcoesLocacao = const [],
  });

  factory Logistica.fromJson(Map<String, dynamic> json) {
    return Logistica(
      chegada: Chegada.fromJson(json['chegada'] ?? {}),
      locomocaoInterna: LocomocaoInterna.fromJson(json['locomocao_interna'] ?? {}),
      opcoesLocacao: (json['opcoes_locacao'] as List? ?? [])
          .map((l) => LocadoraOpcao.fromJson(l))
          .toList(),
    );
  }

  factory Logistica.fromSupabase(Map<String, dynamic> map, {List<dynamic>? locadoras}) {
    return Logistica(
      chegada: Chegada(
        aeroportoPrincipal: map['aeroporto_principal'] ?? '',
        transporteParaCentro: List<String>.from(map['transporte_centro'] ?? []),
      ),
      locomocaoInterna: LocomocaoInterna(
        melhorApp: map['melhor_app_transporte'] ?? '',
        passeTransporte: map['passe_transporte'] ?? '',
        dicaEconomia: map['dica_economia'] ?? '',
      ),
      opcoesLocacao: (locadoras ?? [])
          .map((l) => LocadoraOpcao.fromSupabase(l))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'chegada': chegada.toJson(),
    'locomocao_interna': locomocaoInterna.toJson(),
    'opcoes_locacao': opcoesLocacao.map((l) => l.toJson()).toList(),
  };
}

class Chegada {
  final String aeroportoPrincipal;
  final List<String> transporteParaCentro;

  Chegada({required this.aeroportoPrincipal, required this.transporteParaCentro});

  factory Chegada.fromJson(Map<String, dynamic> json) {
    final transporteRaw = json['transporte_para_centro'] as List? ?? [];
    return Chegada(
      aeroportoPrincipal: json['aeroporto_principal'] ?? '',
      transporteParaCentro: transporteRaw.map((t) {
        if (t is Map) {
          return "${t['modal']}: ${t['custo_estimado']} (${t['tempo_medio']}) - ${t['instrucoes']}";
        }
        return t.toString();
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'aeroporto_principal': aeroportoPrincipal,
    'transporte_para_centro': transporteParaCentro,
  };
}

class TransporteChegada {
  final String modal;
  final String custoEstimado;
  final String tempoMedio;
  final String instrucoes;

  TransporteChegada({
    required this.modal,
    required this.custoEstimado,
    required this.tempoMedio,
    required this.instrucoes,
  });

  factory TransporteChegada.fromJson(Map<String, dynamic> json) {
    return TransporteChegada(
      modal: json['modal'] ?? '',
      custoEstimado: json['custo_estimado'] ?? '',
      tempoMedio: json['tempo_medio'] ?? '',
      instrucoes: json['instrucoes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'modal': modal,
    'custo_estimado': custoEstimado,
    'tempo_medio': tempoMedio,
    'instrucoes': instrucoes,
  };
}

class LocomocaoInterna {
  final String melhorApp;
  final String passeTransporte;
  final String dicaEconomia;

  LocomocaoInterna({
    required this.melhorApp,
    required this.passeTransporte,
    required this.dicaEconomia,
  });

  factory LocomocaoInterna.fromJson(Map<String, dynamic> json) {
    return LocomocaoInterna(
      melhorApp: json['melhor_app'] ?? '',
      passeTransporte: json['passe_transporte'] ?? '',
      dicaEconomia: json['dica_economia'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'melhor_app': melhorApp,
    'passe_transporte': passeTransporte,
    'dica_economia': dicaEconomia,
  };
}

class RoteiroDiario {
  final int dia;
  final String tema;
  final List<Atividade> atividades;
  final Gastronomia gastronomia;

  RoteiroDiario({
    required this.dia,
    required this.tema,
    required this.atividades,
    required this.gastronomia,
  });

  factory RoteiroDiario.fromJson(Map<String, dynamic> json) {
    return RoteiroDiario(
      dia: json['dia'] ?? 0,
      tema: json['tema'] ?? '',
      atividades: (json['atividades'] as List? ?? [])
          .map((i) => Atividade.fromJson(i))
          .toList(),
      gastronomia: Gastronomia.fromJson(json['gastronomia'] ?? {}),
    );
  }

  factory RoteiroDiario.fromSupabase(Map<String, dynamic> map) {
    final atividadesData = map['roteiro_atividades'] as List? ?? [];
    final gastronomiaData = map['roteiro_gastronomia'];
    
    return RoteiroDiario(
      dia: map['dia'] ?? 0,
      tema: map['tema'] ?? '',
      atividades: atividadesData.map((a) => Atividade.fromSupabase(a)).toList(),
      gastronomia: Gastronomia.fromSupabase(gastronomiaData is List ? (gastronomiaData.isNotEmpty ? gastronomiaData[0] : {}) : (gastronomiaData ?? {})),
    );
  }

  Map<String, dynamic> toJson() => {
    'dia': dia,
    'tema': tema,
    'atividades': atividades.map((i) => i.toJson()).toList(),
    'gastronomia': gastronomia.toJson(),
  };
}

class Atividade {
  final String horarioSugerido;
  final String local;
  final String descricaoAtividade;
  final String custoEstimado;
  final Coordenadas coordenadas;
  final bool reservaAntecipada;
  final String linkReferencia;
  final String hackLocal;
  String? imageUrl;

  Atividade({
    required this.horarioSugerido,
    required this.local,
    required this.descricaoAtividade,
    required this.custoEstimado,
    required this.coordenadas,
    required this.reservaAntecipada,
    required this.linkReferencia,
    required this.hackLocal,
    this.imageUrl,
  });

  factory Atividade.fromJson(Map<String, dynamic> json) {
    return Atividade(
      horarioSugerido: json['horario'] ?? json['horario_sugerido'] ?? '',
      local: json['local'] ?? '',
      descricaoAtividade: json['descricao_experiencia'] ?? json['descricao_atividade'] ?? '',
      custoEstimado: json['custo_estimado'] ?? '',
      coordenadas: Coordenadas.fromJson(json['coordenadas'] ?? {}),
      reservaAntecipada: json['reserva_antecipada'] ?? false,
      linkReferencia: json['link_referencia'] ?? '',
      hackLocal: json['hack_local'] ?? '',
      imageUrl: json['image_url'],
    );
  }

  factory Atividade.fromSupabase(Map<String, dynamic> map) {
    return Atividade(
      horarioSugerido: map['horario'] ?? '',
      local: map['local'] ?? '',
      descricaoAtividade: map['descricao'] ?? '',
      custoEstimado: map['custo_estimado'] ?? '',
      coordenadas: Coordenadas(lat: map['lat'] ?? 0.0, lng: map['lng'] ?? 0.0),
      reservaAntecipada: map['reserva_antecipada'] ?? false,
      linkReferencia: map['link_referencia'] ?? '',
      hackLocal: map['hack_local'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'horario': horarioSugerido,
    'local': local,
    'descricao_experiencia': descricaoAtividade,
    'custo_estimado': custoEstimado,
    'coordenadas': coordenadas.toJson(),
    'reserva_antecipada': reservaAntecipada,
    'link_referencia': linkReferencia,
    'hack_local': hackLocal,
    'image_url': imageUrl,
  };
}

class Gastronomia {
  final String restauranteSugerido;
  final String pratoTipico;
  final String precoMedio;
  final Coordenadas localizacao;
  String? imageUrl;

  Gastronomia({
    required this.restauranteSugerido,
    required this.pratoTipico,
    required this.precoMedio,
    required this.localizacao,
    this.imageUrl,
  });

  factory Gastronomia.fromJson(Map<String, dynamic> json) {
    return Gastronomia(
      restauranteSugerido: json['restaurante_sugerido'] ?? '',
      pratoTipico: json['prato_tipico'] ?? '',
      precoMedio: json['preco_medio'] ?? '',
      localizacao: Coordenadas.fromJson(json['localizacao'] ?? {}),
      imageUrl: json['image_url'],
    );
  }

  factory Gastronomia.fromSupabase(Map<String, dynamic> map) {
    return Gastronomia(
      restauranteSugerido: map['restaurante_sugerido'] ?? '',
      pratoTipico: map['prato_tipico'] ?? '',
      precoMedio: map['preco_medio'] ?? '',
      localizacao: Coordenadas(lat: map['lat'] ?? 0.0, lng: map['lng'] ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() => {
    'restaurante_sugerido': restauranteSugerido,
    'prato_tipico': pratoTipico,
    'preco_medio': precoMedio,
    'localizacao': localizacao.toJson(),
    'image_url': imageUrl,
  };
}

class GuiaLocal {
  final Seguranca seguranca;
  final SaudeEmergencia saudeEmergencia;
  final EtiquetaECultura etiquetaECultura;

  GuiaLocal({
    required this.seguranca,
    required this.saudeEmergencia,
    required this.etiquetaECultura,
  });

  factory GuiaLocal.fromJson(Map<String, dynamic> json) {
    return GuiaLocal(
      seguranca: Seguranca.fromJson(json['seguranca'] ?? {}),
      saudeEmergencia: SaudeEmergencia.fromJson(json['saude_emergencia'] ?? {}),
      etiquetaECultura: EtiquetaECultura.fromJson(json['etiqueta_e_cultura'] ?? {}),
    );
  }

  factory GuiaLocal.fromSupabase(Map<String, dynamic> map) {
    return GuiaLocal(
      seguranca: Seguranca(
        nivelAlerta: map['nivel_alerta_seguranca'] ?? '',
        golpesComuns: List<String>.from(map['golpes_comuns'] ?? []), 
        bairrosPerigosos: List<String>.from(map['bairros_perigosos'] ?? []),
      ),
      saudeEmergencia: SaudeEmergencia(
        telefones: Map<String, String>.from(map['telefones_emergencia'] ?? {}),
        hospitaisProximos: List<String>.from(map['hospitais_proximos'] ?? []), 
        farmaciasPopulares: map['farmacias_populares'] ?? '',
      ),
      etiquetaECultura: EtiquetaECultura(
        gorjetas: map['gorjetas'] ?? '',
        frasesSobrevivencia: Map<String, String>.from(map['frases_sobrevivencia'] ?? {}), 
        regrasSociais: map['regras_sociais'] ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'seguranca': seguranca.toJson(),
    'saude_emergencia': saudeEmergencia.toJson(),
    'etiqueta_e_cultura': etiquetaECultura.toJson(),
  };
}

class Seguranca {
  final String nivelAlerta;
  final List<String> golpesComuns;
  final List<String> bairrosPerigosos;

  Seguranca({
    required this.nivelAlerta,
    required this.golpesComuns,
    required this.bairrosPerigosos,
  });

  factory Seguranca.fromJson(Map<String, dynamic> json) {
    return Seguranca(
      nivelAlerta: json['nivel_alerta'] ?? '',
      golpesComuns: List<String>.from(json['golpes_comuns'] ?? []),
      bairrosPerigosos: List<String>.from(json['bairros_perigosos'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'nivel_alerta': nivelAlerta,
    'golpes_comuns': golpesComuns,
    'bairros_perigosos': bairrosPerigosos,
  };
}

class SaudeEmergencia {
  final Map<String, String> telefones;
  final List<String> hospitaisProximos;
  final String farmaciasPopulares;

  SaudeEmergencia({
    required this.telefones,
    required this.hospitaisProximos,
    required this.farmaciasPopulares,
  });

  factory SaudeEmergencia.fromJson(Map<String, dynamic> json) {
    final hospitaisRaw = json['hospitais_proximos'] as List? ?? [];
    return SaudeEmergencia(
      telefones: Map<String, String>.from(json['telefones'] ?? {}),
      hospitaisProximos: hospitaisRaw.map((h) {
        if (h is Map) return h['nome'].toString();
        return h.toString();
      }).toList(),
      farmaciasPopulares: json['farmacias_populares'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'telefones': telefones,
    'hospitais_proximos': hospitaisProximos,
    'farmacias_populares': farmaciasPopulares,
  };
}

class EtiquetaECultura {
  final String gorjetas;
  final Map<String, String> frasesSobrevivencia;
  final String regrasSociais;

  EtiquetaECultura({
    required this.gorjetas,
    required this.frasesSobrevivencia,
    required this.regrasSociais,
  });

  factory EtiquetaECultura.fromJson(Map<String, dynamic> json) {
    return EtiquetaECultura(
      gorjetas: json['gorjetas'] ?? '',
      frasesSobrevivencia: Map<String, String>.from(json['frases_sobrevivencia'] ?? {}),
      regrasSociais: json['regras_sociais'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'gorjetas': gorjetas,
    'frases_sobrevivencia': frasesSobrevivencia,
    'regras_sociais': regrasSociais,
  };
}

class ComercioEUtilidades {
  final List<String> supermercadosBaratos;
  final String melhoresAreasCompras;
  final String lojasConveniencia;

  ComercioEUtilidades({
    required this.supermercadosBaratos,
    required this.melhoresAreasCompras,
    required this.lojasConveniencia,
  });

  factory ComercioEUtilidades.fromJson(Map<String, dynamic> json) {
    return ComercioEUtilidades(
      supermercadosBaratos: List<String>.from(json['supermercados_baratos'] ?? []),
      melhoresAreasCompras: json['melhores_areas_compras'] ?? '',
      lojasConveniencia: json['lojas_conveniencia'] ?? '',
    );
  }

  factory ComercioEUtilidades.fromSupabase(Map<String, dynamic> map) {
    // Para simplificar no MVP, esses campos podem vir de um JSONB na tabela de utilidades
    return ComercioEUtilidades(
      supermercadosBaratos: List<String>.from(map['supermercados_baratos'] ?? []),
      melhoresAreasCompras: map['melhores_areas_compras'] ?? '',
      lojasConveniencia: map['lojas_conveniencia'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'supermercados_baratos': supermercadosBaratos,
    'melhores_areas_compras': melhoresAreasCompras,
    'lojas_conveniencia': lojasConveniencia,
  };
}

class Coordenadas {
  final double lat;
  final double lng;

  Coordenadas({required this.lat, required this.lng});

  factory Coordenadas.fromJson(Map<String, dynamic> json) {
    return Coordenadas(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
  };
}

class PontoAtendimento {
  final String nome;
  final Coordenadas coordenadas;

  PontoAtendimento({required this.nome, required this.coordenadas});

  factory PontoAtendimento.fromJson(Map<String, dynamic> json) {
    return PontoAtendimento(
      nome: json['nome'] ?? '',
      coordenadas: Coordenadas.fromJson(json['coordenadas'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'coordenadas': coordenadas.toJson(),
  };
}

class Hospedagem {
  final String status;
  final String? nome;
  final String? tipo;
  final String? nivel;
  final String? endereco;
  final String? custoEstimado;
  final Coordenadas? coordenadas;
  final String? motivoSugestao;
  final String? linkReferencia;
  String? imageUrl;

  Hospedagem({
    required this.status,
    this.nome,
    this.tipo,
    this.nivel,
    this.endereco,
    this.custoEstimado,
    this.coordenadas,
    this.motivoSugestao,
    this.linkReferencia,
    this.imageUrl,
  });

  factory Hospedagem.fromJson(Map<String, dynamic> json) {
    return Hospedagem(
      status: json['status'] ?? 'sugerido',
      nome: json['nome'],
      tipo: json['tipo'],
      nivel: json['nivel_solicitado'],
      endereco: json['endereco'],
      custoEstimado: json['custo_estimado'],
      coordenadas: json['coordenadas'] != null ? Coordenadas.fromJson(json['coordenadas']) : null,
      motivoSugestao: json['motivo_sugestao'],
      linkReferencia: json['link_referencia'],
      imageUrl: json['image_url'],
    );
  }

  factory Hospedagem.fromSupabase(Map<String, dynamic> map) {
    return Hospedagem(
      status: map['status'] ?? '',
      nome: map['nome'],
      tipo: map['tipo'],
      nivel: map['nivel_solicitado'],
      endereco: map['endereco'],
      custoEstimado: map['custo_estimado'],
      coordenadas: Coordenadas(lat: map['lat'] ?? 0.0, lng: map['lng'] ?? 0.0),
      motivoSugestao: map['motivo_sugestao'],
      linkReferencia: map['link_referencia'],
      imageUrl: map['image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'nome': nome,
    'tipo': tipo,
    'nivel_solicitado': nivel,
    'endereco': endereco,
    'custo_estimado': custoEstimado,
    'coordenadas': coordenadas?.toJson(),
    'motivo_sugestao': motivoSugestao,
    'link_referencia': linkReferencia,
    'image_url': imageUrl,
  };
}

class AtracaoTicket {
  final String nome;
  final String? tipo;
  final String? custoEstimado;
  final String? dicaSeguranca;
  final bool isOficial;
  final String? linkOficial;
  final String? dataEvento;
  String? imageUrl;

  AtracaoTicket({
    required this.nome,
    this.tipo,
    this.custoEstimado,
    this.dicaSeguranca,
    this.isOficial = true,
    this.linkOficial,
    this.dataEvento,
    this.imageUrl,
  });

  factory AtracaoTicket.fromJson(Map<String, dynamic> json) {
    return AtracaoTicket(
      nome: json['nome'] ?? '',
      tipo: json['tipo'],
      custoEstimado: json['custo_estimado'],
      dicaSeguranca: json['dica_seguranca'],
      isOficial: json['is_oficial'] ?? true,
      linkOficial: json['link_oficial'],
      dataEvento: json['data_evento'],
      imageUrl: json['image_url'],
    );
  }

  factory AtracaoTicket.fromSupabase(Map<String, dynamic> map) {
    return AtracaoTicket(
      nome: map['nome'] ?? '',
      tipo: map['tipo'],
      custoEstimado: map['custo_estimado'],
      dicaSeguranca: map['dica_seguranca'],
      isOficial: map['is_oficial'] ?? true,
      linkOficial: map['link_oficial'],
      dataEvento: map['data_evento'],
      imageUrl: map['image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'tipo': tipo,
    'custo_estimado': custoEstimado,
    'dica_seguranca': dicaSeguranca,
    'is_oficial': isOficial,
    'link_oficial': linkOficial,
    'data_evento': dataEvento,
    'image_url': imageUrl,
  };
}

class LocadoraOpcao {
  final String nome;
  final String? endereco;
  final String? siteOficial;
  final String? tipoVeiculo;

  LocadoraOpcao({
    required this.nome,
    this.endereco,
    this.siteOficial,
    this.tipoVeiculo,
  });

  factory LocadoraOpcao.fromJson(Map<String, dynamic> json) {
    return LocadoraOpcao(
      nome: json['nome'] ?? '',
      endereco: json['endereco'],
      siteOficial: json['site_oficial'],
      tipoVeiculo: json['tipo_veiculo'],
    );
  }

  factory LocadoraOpcao.fromSupabase(Map<String, dynamic> map) {
    return LocadoraOpcao(
      nome: map['nome'] ?? '',
      endereco: map['endereco'],
      siteOficial: map['site_oficial'],
      tipoVeiculo: map['tipo_veiculo'],
    );
  }

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'endereco': endereco,
    'site_oficial': siteOficial,
    'tipo_veiculo': tipoVeiculo,
  };
}
