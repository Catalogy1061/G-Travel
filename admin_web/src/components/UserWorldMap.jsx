import React, { useMemo, useState, useRef, useEffect } from 'react';
import { Card, Text, Title, Badge, Flex, Button } from '@tremor/react';
import { Globe, ZoomIn, ZoomOut, RotateCcw } from 'lucide-react';
import worldData from './worldData.json';

const UserWorldMap = ({ users }) => {
  const [zoom, setZoom] = useState(1);
  const [offset, setOffset] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);
  const [startPos, setStartPos] = useState({ x: 0, y: 0 });
  const containerRef = useRef(null);

  // Mapeia nomes de países para IDs/Centros
  const countryMap = useMemo(() => {
    const map = {};
    worldData.forEach(c => {
      map[c.name.toLowerCase()] = c;
      map[c.id.toLowerCase()] = c;
    });
    return map;
  }, []);

  const normalizeCountry = (name) => {
    if (!name) return 'desconhecido';
    const n = name.toLowerCase().trim();
    const variations = {
      'brasil': 'brazil',
      'brazil': 'brazil',
      'estados unidos': 'united states',
      'united states': 'united states',
      'eua': 'united states',
      'usa': 'united states',
      'canada': 'canada',
      'canadá': 'canada',
      'alemanha': 'germany',
      'itália': 'italy',
      'frança': 'france',
      'espanha': 'spain',
      'japão': 'japan',
      'reino unido': 'united kingdom',
      'portugal': 'portugal',
    };
    return variations[n] || n;
  };

  // Converte Lat/Lng para coordenadas SVG (2000x857)
  // Calibrado para o mapa Robinson/Miller do worldData.json
  const project = (lat, lng) => {
    if (lat === undefined || lng === undefined || lat === null || lng === null) return null;
    
    // Ajuste empírico para este mapa específico
    // O mapa parece estar levemente deslocado e escalonado
    const x = (lng + 175) * (2000 / 355); 
    const y = (85 - lat) * (857 / 170);
    
    return { x, y };
  };

  const countryStats = useMemo(() => {
    const stats = {};
    users.forEach(u => {
      const country = normalizeCountry(u.country);
      const displayName = country.split(' ').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
      stats[displayName] = (stats[displayName] || 0) + 1;
    });
    return Object.entries(stats)
      .map(([name, count]) => ({ name, count }))
      .sort((a, b) => b.count - a.count);
  }, [users]);

  const userDots = useMemo(() => {
    const dots = [];
    users.forEach((user, index) => {
      // 1. Tentar mapear pelo país primeiro (mais estável para o dashboard atual)
      const normalizedName = normalizeCountry(user.country);
      const country = countryMap[normalizedName];
      
      let x, y;

      if (country) {
        // Correção específica para o Brasil (worldData.json original está com erro)
        if (normalizedName === 'brazil') {
          x = 735; 
          y = 550;
        } 
        // Usar centro do worldData se for válido (> 100px)
        else if (country.center && country.center.x > 100) {
          x = country.center.x;
          y = country.center.y;
        } else {
          // Extrair primeira coordenada do path SVG como fallback
          const firstPoint = country.d.match(/M\s*([\d.-]+)[\s,]+([\d.-]+)/i);
          if (firstPoint) {
            x = parseFloat(firstPoint[1]);
            y = parseFloat(firstPoint[2]);
          }
        }
      }

      // 2. Se falhar o país, tentar GPS como último recurso
      if (x === undefined && user.last_lat && user.last_lng) {
        const coords = project(user.last_lat, user.last_lng);
        if (coords) {
          x = coords.x;
          y = coords.y;
        }
      }

      if (x !== undefined && !isNaN(x)) {
        const jitterX = (Math.sin(index * 13) * 20);
        const jitterY = (Math.cos(index * 17) * 20);
        dots.push({
          id: user.id || `dot-${index}`,
          x: x + jitterX,
          y: y + jitterY,
          name: user.full_name
        });
      }
    });
    return dots;
  }, [users, countryMap]);

  const handleZoomIn = () => setZoom(prev => Math.min(prev + 0.5, 5));
  const handleZoomOut = () => setZoom(prev => {
    const newZoom = Math.max(prev - 0.5, 1);
    if (newZoom === 1) setOffset({ x: 0, y: 0 });
    return newZoom;
  });
  const handleReset = () => { setZoom(1); setOffset({ x: 0, y: 0 }); };

  // Lógica de Arrastar (Pan)
  const onPointerDown = (e) => {
    if (zoom <= 1) return;
    setIsDragging(true);
    setStartPos({ x: e.clientX - offset.x, y: e.clientY - offset.y });
  };

  const onPointerMove = (e) => {
    if (!isDragging || zoom <= 1) return;
    const newX = e.clientX - startPos.x;
    const newY = e.clientY - startPos.y;
    
    // Limites básicos para não fugir totalmente da tela
    const limitX = (2000 * (zoom - 1)) / 2;
    const limitY = (857 * (zoom - 1)) / 2;
    
    setOffset({
      x: Math.max(-limitX, Math.min(limitX, newX)),
      y: Math.max(-limitY, Math.min(limitY, newY))
    });
  };

  const onPointerUp = () => setIsDragging(false);

  return (
    <Card className="bg-slate-900/40 backdrop-blur-xl border-slate-800/60 shadow-xl overflow-hidden p-0">
      <div className="flex flex-col">
        <div className="p-8 border-b border-slate-800/50 flex flex-col">
          <Flex justifyContent="between" className="mb-8">
            <div>
              <Title className="text-white text-2xl flex items-center gap-3">
                <Globe className="w-6 h-6 text-blue-500" /> Presença Global em Tempo Real
              </Title>
              <Text className="text-slate-400 text-sm mt-1">Navegue pelo mapa para detalhes geográficos</Text>
            </div>
            
            <Badge color="blue" size="xl" className="px-6 py-2 text-lg font-bold bg-blue-500/10 border-blue-500/20">
              {users.length} Viajantes Ativos
            </Badge>
          </Flex>

          <div 
            ref={containerRef}
            className={`relative aspect-[2000/857] w-full bg-slate-950/60 rounded-3xl border border-slate-800/80 shadow-2xl overflow-hidden group min-h-[500px] select-none ${zoom > 1 ? 'cursor-grab active:cursor-grabbing' : 'cursor-default'}`}
            onPointerDown={onPointerDown}
            onPointerMove={onPointerMove}
            onPointerUp={onPointerUp}
            onPointerLeave={onPointerUp}
          >
            <svg 
              viewBox="0 0 2000 857" 
              className={`w-full h-full transition-transform ${isDragging ? 'duration-0' : 'duration-500'} ease-out origin-center`}
              style={{ transform: `scale(${zoom}) translate(${offset.x / zoom}px, ${offset.y / zoom}px)` }}
            >
              <defs>
                <pattern id="dotGrid" width="30" height="30" patternUnits="userSpaceOnUse">
                  <circle cx="1" cy="1" r="0.8" fill="rgba(255,255,255,0.08)" />
                </pattern>
                <linearGradient id="mapGradient" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0%" stopColor="#1e293b" />
                  <stop offset="100%" stopColor="#0f172a" />
                </linearGradient>
              </defs>
              
              <rect width="2000" height="857" fill="url(#dotGrid)" />

              <g className="stroke-slate-700/50 stroke-[0.6] transition-all">
                {worldData.map((country) => (
                  <path 
                    key={country.id}
                    d={country.d} 
                    fill="url(#mapGradient)"
                    className="hover:fill-slate-800/60 transition-colors duration-200"
                  />
                ))}
              </g>

              {userDots.map((dot) => (
                <g key={dot.id} className="pointer-events-none">
                  <circle cx={dot.x} cy={dot.y} r={8} className="fill-blue-500/10" />
                  <circle cx={dot.x} cy={dot.y} r={4} className="fill-blue-400">
                    <animate attributeName="r" from="4" to="12" dur="2s" repeatCount="indefinite" />
                    <animate attributeName="opacity" from="0.6" to="0" dur="2s" repeatCount="indefinite" />
                  </circle>
                  <circle cx={dot.x} cy={dot.y} r={3.5} className="fill-blue-400 shadow-[0_0_10px_rgba(59,130,246,0.8)]" />
                </g>
              ))}
            </svg>
            
            {/* Controles de Zoom Dentro do Mapa (Estilo Premium) */}
            <div className="absolute top-6 right-6 flex flex-col gap-2">
              <div className="flex flex-col bg-slate-900/80 backdrop-blur-xl rounded-xl p-1 border border-white/10 shadow-2xl overflow-hidden">
                <Button 
                  variant="light" 
                  icon={ZoomIn} 
                  onClick={(e) => { e.stopPropagation(); handleZoomIn(); }} 
                  className="text-slate-300 hover:bg-white/5 hover:text-white p-3" 
                />
                <div className="h-[1px] bg-white/5 mx-2" />
                <Button 
                  variant="light" 
                  icon={ZoomOut} 
                  onClick={(e) => { e.stopPropagation(); handleZoomOut(); }} 
                  className="text-slate-300 hover:bg-white/5 hover:text-white p-3" 
                />
              </div>
              <Button 
                variant="light" 
                icon={RotateCcw} 
                onClick={(e) => { e.stopPropagation(); handleReset(); }} 
                className="bg-slate-900/80 backdrop-blur-xl rounded-xl p-3 border border-white/10 shadow-2xl text-slate-300 hover:text-white" 
              />
            </div>

            {/* Indicador de Zoom */}
            <div className="absolute bottom-6 right-6 bg-blue-500/10 backdrop-blur-md px-4 py-1.5 rounded-full border border-blue-500/20 text-[11px] text-blue-400 font-bold tracking-widest font-mono">
              ZOOM: {Math.round(zoom * 100)}%
            </div>
          </div>
          
          <div className="mt-6 flex gap-6 text-xs text-slate-500 font-medium">
            <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-blue-500 shadow-[0_0_8px_rgba(59,130,246,0.5)]"></div> Usuário Ativo</div>
            <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full bg-slate-800 border border-slate-700"></div> Território Mapeado</div>
            {zoom > 1 && <div className="ml-auto text-blue-400/60 animate-pulse">Arraste para navegar pelo mundo</div>}
          </div>
        </div>

        <div className="p-8 bg-slate-900/10">
          <Title className="text-white text-lg uppercase tracking-[0.2em] opacity-80 font-bold mb-6">Performance por Região</Title>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {countryStats.slice(0, 12).map((item, idx) => (
              <div key={item.name} className="bg-slate-950/30 rounded-xl p-4 border border-slate-800/40 hover:border-blue-500/30 transition-all group">
                <Flex justifyContent="between">
                  <div className="flex items-center gap-3">
                    <span className="text-xs text-slate-600 font-mono">{(idx + 1).toString().padStart(2, '0')}</span>
                    <Text className="text-slate-300 font-semibold group-hover:text-white transition-colors">{item.name}</Text>
                  </div>
                  <Badge size="xs" color="blue" className="bg-blue-500/10 text-blue-400 border-blue-500/20 px-3">
                    {item.count}
                  </Badge>
                </Flex>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Card>
  );
};

export default UserWorldMap;
