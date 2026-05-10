import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyBJDXpABVbf7Gp-lPKmku-Rcdn1G3coBOo';
  
  static Future<Map<String, dynamic>> gerarRoteiroJSON({
    required String destino,
    required double orcamento,
    required String estilo,
    required String perfil,
    required int dias,
    bool hospedagemRequerida = true,
    String nivelHospedagem = 'Intermediário',
  }) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );

    final viagemId = const Uuid().v4();

    final prompt = '''
Instruções: Atue como um Especialista em Viagens Global. Gere um JSON estrito onde cada campo deve ser preenchido com dados reais e atualizados do destino solicitado. Use coordenadas geográficas (latitude/longitude) reais para pontos turísticos, hotéis e hospitais. Sua resposta deve ser unica e exclusivamente um objeto JSON válido, sem markdown ou explicações antes ou depois.

Planejamento de viagem de $dias dias para $destino.
Estilo: $estilo | Perfil: $perfil | Orçamento: R\$ $orcamento
Hospedagem Requerida: ${hospedagemRequerida ? "SIM, nível $nivelHospedagem" : "NÃO (usuário já possui)"}

Responda ESTRITAMENTE seguindo a estrutura JSON abaixo:
{
  "viagem_id": "$viagemId",
  "configuracao_usuario": {
    "destino_solicitado": "$destino",
    "moeda_origem": "BRL",
    "orcamento_referencia": "$orcamento BRL",
    "perfil": "$estilo"
  },
  "hospedagem": {
    "status": "${hospedagemRequerida ? 'sugerido' : 'confirmada'}",
    "nivel_solicitado": "$nivelHospedagem",
    "nome": "${hospedagemRequerida ? 'Nome de um hotel/pousada REAL' : ''}",
    "tipo": "${hospedagemRequerida ? 'Hotel/Hostel/Airbnb' : ''}",
    "endereco": "${hospedagemRequerida ? 'Endereço completo' : ''}",
    "custo_estimado": "${hospedagemRequerida ? 'Valor médio por noite' : ''}",
    "coordenadas": ${hospedagemRequerida ? '{ "lat": 0.0, "lng": 0.0 }' : 'null'},
    "motivo_sugestao": "${hospedagemRequerida ? 'Por que este lugar combina com o perfil?' : ''}",
    "link_referencia": "URL"
  },
  "destino_info": {
    "nome_oficial": "string",
    "fuso_horario": "UTC+/-X",
    "clima_esperado": {
      "descricao": "Ex: Inverno rigoroso, levar casacos pesados",
      "temp_media": "°C"
    },
    "documentacao": {
      "visto_obrigatorio": boolean,
      "vacinas_exigidas": ["Lista de vacinas"],
      "seguro_viagem_obrigatorio": boolean
    },
    "cambio": {
      "moeda_local": "Nome/Sigla",
      "cotacao_estimada": "1 BRL = X [Local]",
      "melhor_forma_pagamento": "Dinheiro/Cartão/Digital"
    }
  },
  "logistica": {
    "chegada": {
      "aeroporto_principal": "Nome + IATA",
      "transporte_para_centro": [
        {
          "modal": "Trem/Ônibus/Taxi",
          "custo_estimado": "Valor",
          "tempo_medio": "min",
          "instrucoes": "Onde pegar e como pagar"
        }
      ]
    },
    "locomocao_interna": {
      "melhor_app": "Uber/Grab/Bolt",
      "passe_transporte": "Ex: Navigo, Oyster Card",
      "dica_economia": "Texto sobre passes diários ou semanais"
    },
    "opcoes_locacao": [
      {
        "nome": "Nome da Locadora REAL",
        "endereco": "Endereço aproximado no destino",
        "site_oficial": "URL oficial para reserva",
        "tipo_veiculo": "carro/moto/ambos"
      }
    ]
  },
  "roteiro_diario": [
    {
      "dia": 1,
      "tema": "Título do Dia",
      "atividades": [
        {
          "horario": "HH:MM",
          "local": "Nome do Local",
          "coordenadas": { "lat": 0.0, "lng": 0.0 },
          "descricao_experiencia": "Texto rico da IA",
          "custo_estimado": "Valor",
          "reserva_antecipada": boolean,
          "link_referencia": "URL oficial ou agregador",
          "hack_local": "Ex: Entre pela porta lateral para evitar filas"
        }
      ],
      "gastronomia": {
        "restaurante_sugerido": "Nome",
        "prato_tipico": "Nome do prato",
        "preco_medio": "Valor",
        "localizacao": { "lat": 0.0, "lng": 0.0 }
      }
    }
  ],
  "guia_local": {
    "seguranca": {
      "nivel_alerta": "Baixo/Médio/Alto",
      "golpes_comuns": ["Lista de golpes locais"],
      "bairros_perigosos": ["Lista de locais a evitar"]
    },
    "saude_emergencia": {
      "telefones": { "policia": "X", "ambulancia": "Y", "bombeiros": "Z" },
      "hospitais_proximos": [
        { "nome": "Hospital X", "coordenadas": { "lat": 0.0, "lng": 0.0 } }
      ],
      "farmacias_populares": "Nome da rede de farmácias"
    },
    "etiqueta_e_cultura": {
      "gorjetas": "Explicação sobre como funciona no país",
      "frases_sobrevivencia": {
        "obrigado": "Tradução/Fonética",
        "onde_fica": "Tradução/Fonética"
      },
      "regras_sociais": "Ex: Cobrir ombros em templos"
    }
  },
  "comercio_e_utilidades": {
    "supermercados_baratos": ["Nome da Rede"],
    "melhores_areas_compras": "Nome dos bairros ou ruas",
    "lojas_conveniencia": "Ex: 7-Eleven, Lawson"
  },
  "tickets_e_atracoes": [
    {
      "nome": "Nome REAL e ESPECÍFICO (ex: Museu do Louvre, Estátua da Liberdade)",
      "tipo": "Atração/Evento/Festival/Teatro",
      "custo_estimado": "Valor médio do ingresso",
      "link_oficial": "URL OFICIAL E SEGURA para compra de ingressos",
      "dica_seguranca": "Dica prática sobre o local",
      "is_oficial": true,
      "data_evento": "YYYY-MM-DD (se aplicável)",
      "image_url": ""
    }
  ]
}

IMPORTANTE: Pesquise por eventos reais, festivais ou atrações icônicas. Use nomes completos e específicos para que possamos buscar fotos reais. Inclua pelo menos 3 opções fundamentais.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      final String responseText = response.text ?? '';
      
      // Limpeza por precaução caso a IA devolva algo fora do JSON
      final jsonStr = _limparResposta(responseText);
      
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print('Erro no Gemini: $e');
      throw Exception('Falha ao gerar roteiro com Inteligência Artificial: $e');
    }
  }

  static String _limparResposta(String raw) {
    String clean = raw.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    return clean.trim();
  }
  static Future<List<Map<String, String>>> getClayMagnetOptions(String destination) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );

    final prompt = '''
Para o destino turístico "$destination", sugira 5 conceitos iconicos (monumentos, cultura, gastronomia) para imãs de geladeira.
Retorne APENAS um JSON válido contendo um array de 5 objetos com a estrutura:
[
  {"name": "Nome curto do marco", "emoji": "🗽", "colorHex": "#E87A30"}
]
A cor deve ser vibrante e associada ao item. Sem markdown, sem texto extra, apenas o JSON.
''';
    
    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final cleanText = _limparResposta(response.text ?? "[]");
      final List<dynamic> jsonList = jsonDecode(cleanText);
      
      return jsonList.map((item) => {
        'name': item['name'].toString(),
        'emoji': item['emoji'].toString(),
        'colorHex': item['colorHex'].toString(),
      }).toList();
    } catch (e) {
      print('Erro ao buscar imãs sugeridos: $e');
      return [
        {'name': destination, 'emoji': '📍', 'colorHex': '#E87A30'},
        {'name': 'Monumento', 'emoji': '🏛️', 'colorHex': '#4C8CE2'},
        {'name': 'Cultura', 'emoji': '🎭', 'colorHex': '#E2C44C'},
        {'name': 'Gastronomia', 'emoji': '🍽️', 'colorHex': '#E24C4C'},
        {'name': 'Natureza', 'emoji': '🌲', 'colorHex': '#63C8B7'},
      ];
    }
  }
}
