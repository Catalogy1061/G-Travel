import React, { useState, useMemo } from 'react';
import { 
  Card, 
  Grid, 
  Text, 
  Title, 
  Metric, 
  Flex, 
  Badge, 
  Table, 
  TableHead, 
  TableRow, 
  TableHeaderCell, 
  TableBody, 
  TableCell, 
  Button, 
  TextInput,
  Select,
  SelectItem,
  AreaChart,
  DonutChart,
  BarChart,
  SparkAreaChart,
  TabGroup,
  TabList,
  Tab,
  TabPanels,
  TabPanel
} from '@tremor/react';
import { Dialog, Transition } from '@headlessui/react';
import { Fragment } from 'react';
import { 
  Users, 
  CheckCircle, 
  Plus, 
  Search, 
  Download, 
  LogOut,
  MapPin,
  Smartphone,
  Calendar,
  ChevronRight,
  Mail,
  Fingerprint,
  X,
  Plane
} from 'lucide-react';
import { useDashboardData } from '../hooks/useDashboardData';
import { supabase } from '../lib/supabase';
import UserWorldMap from './UserWorldMap';

export default function Dashboard() {
  const { profiles, loading, error } = useDashboardData();
  const [searchTerm, setSearchTerm] = useState('');
  const [countryFilter, setCountryFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedUser, setSelectedUser] = useState(null);
  const [itineraries, setItineraries] = useState([]);
  const [itinerariesLoading, setItinerariesLoading] = useState(false);
  const [sortConfig, setSortConfig] = useState({ key: 'created_at', direction: 'desc' });

  const handleSort = (key) => {
    let direction = 'asc';
    if (sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
  };

  const SortIcon = ({ column }) => {
    if (sortConfig.key !== column) return <ChevronRight className="w-3 h-3 opacity-20 rotate-90" />;
    return sortConfig.direction === 'asc' ? <Plus className="w-3 h-3 rotate-45 text-blue-400" /> : <Plus className="w-3 h-3 rotate-0 text-blue-400" />;
  };

  const stats = useMemo(() => {
    const total = profiles.length;
    const active = profiles.filter(p => p.city || p.state).length;
    const today = profiles.filter(p => p.created_at && new Date(p.created_at).toLocaleDateString() === new Date().toLocaleDateString()).length;
    
    return { total, active, today };
  }, [profiles]);

  const filteredProfiles = useMemo(() => {
    let filtered = profiles.filter(u => {
      const matchesSearch = (u.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) || u.email?.toLowerCase().includes(searchTerm.toLowerCase()));
      const matchesCountry = countryFilter === 'all' || u.country === countryFilter;
      const hasLoc = u.city || u.state;
      const matchesStatus = statusFilter === 'all' || (statusFilter === 'online' ? hasLoc : !hasLoc);
      return matchesSearch && matchesCountry && matchesStatus;
    });

    if (sortConfig.key) {
      filtered.sort((a, b) => {
        const valA = a[sortConfig.key] || '';
        const valB = b[sortConfig.key] || '';
        if (valA < valB) return sortConfig.direction === 'asc' ? -1 : 1;
        if (valA > valB) return sortConfig.direction === 'asc' ? 1 : -1;
        return 0;
      });
    }

    return filtered;
  }, [profiles, searchTerm, countryFilter, statusFilter, sortConfig]);

  const countries = useMemo(() => {
    const counts = {};
    profiles.forEach(p => {
      if (p.country) counts[p.country] = (counts[p.country] || 0) + 1;
    });
    return Object.keys(counts).map(name => ({ name, value: counts[name] }));
  }, [profiles]);

  const chartData = useMemo(() => {
    const dates = {};
    profiles.forEach(p => {
      if (p.created_at) {
        const date = new Date(p.created_at).toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
        dates[date] = (dates[date] || 0) + 1;
      }
    });
    return Object.keys(dates).reverse().slice(0, 10).map(date => ({
      date,
      "Novos Usuários": dates[date]
    }));
  }, [profiles]);

  const statusData = useMemo(() => {
    const active = profiles.filter(p => p.city || p.state).length;
    const inactive = profiles.length - active;
    return [
      { name: 'Status', 'Localizados': active, 'Sem Localização': inactive }
    ];
  }, [profiles]);

  const handleLogout = () => supabase.auth.signOut();

  const fetchItineraries = async (userId) => {
    setItinerariesLoading(true);
    try {
      const { data, error } = await supabase.from('roteiros').select('*').eq('user_id', userId);
      if (error) throw error;
      setItineraries(data || []);
    } catch (err) {
      console.error("Erro ao buscar roteiros:", err);
    } finally {
      setItinerariesLoading(false);
    }
  };

  const openDrawer = (user) => {
    setSelectedUser(user);
    fetchItineraries(user.id);
  };

  const closeDrawer = () => {
    setSelectedUser(null);
    setItineraries([]);
  };

  const exportCSV = () => {
    const headers = ['ID', 'Nome', 'Email', 'Telefone', 'Cidade', 'Estado', 'Pais', 'Cadastro'];
    const rows = profiles.map(u => [u.id, u.full_name, u.email, u.phone || '', u.city, u.state, u.country, u.created_at]);
    let csvContent = "data:text/csv;charset=utf-8," + headers.join(",") + "\n" + rows.map(r => r.join(",")).join("\n");
    const link = document.createElement("a");
    link.setAttribute("href", encodeURI(csvContent));
    link.setAttribute("download", "gtravel_users.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="min-h-screen bg-slate-950 p-6 md:p-10 relative overflow-hidden">
      {/* Background Glows */}
      <div className="absolute top-0 left-1/2 w-3/4 h-96 bg-blue-900/10 rounded-full blur-[120px] pointer-events-none -translate-x-1/2"></div>
      <div className="absolute bottom-0 right-0 w-1/2 h-96 bg-indigo-900/10 rounded-full blur-[120px] pointer-events-none"></div>

      <div className="relative z-10 max-w-7xl mx-auto">
        {/* Header */}
        <Flex className="mb-8" alignItems="center" justifyContent="between">
          <div>
            <Title className="text-3xl font-bold text-white tracking-tight">G-TRAVEL Admin</Title>
            <Text className="text-slate-400">Gestão Premium de Viajantes</Text>
          </div>
          <Flex className="w-auto gap-4">
            <Button variant="secondary" icon={Download} onClick={exportCSV} className="bg-slate-900/50 border-slate-700 text-slate-300 hover:text-white">
              Exportar CSV
            </Button>
            <Button variant="secondary" color="red" icon={LogOut} onClick={handleLogout} className="bg-slate-900/50 border-red-900/30">
              Sair
            </Button>
          </Flex>
        </Flex>

        {/* Stats Cards */}
        <Grid numItemsSm={1} numItemsMd={3} className="gap-6 mb-8">
          <Card decoration="top" decorationColor="blue" className="bg-slate-900/40 backdrop-blur-xl border-slate-800/60 shadow-lg">
            <Flex alignItems="start" justifyContent="between">
              <div>
                <Text className="text-slate-400">Total de Usuários</Text>
                <Metric className="text-white mt-2">{stats.total}</Metric>
              </div>
              <Badge icon={Users} color="blue">Total</Badge>
            </Flex>
            <div className="mt-4 h-12">
              <SparkAreaChart
                data={chartData}
                categories={["Novos Usuários"]}
                index="date"
                colors={["blue"]}
                className="h-full w-full"
              />
            </div>
          </Card>

          <Card decoration="top" decorationColor="emerald" className="bg-slate-900/40 backdrop-blur-xl border-slate-800/60 shadow-lg">
            <Flex alignItems="start" justifyContent="between">
              <div>
                <Text className="text-slate-400">Usuários Localizados</Text>
                <Metric className="text-white mt-2">{stats.active}</Metric>
              </div>
              <Badge color="emerald" icon={CheckCircle}>Ativos</Badge>
            </Flex>
            <div className="mt-4 h-12 flex items-end">
                <div className="w-full bg-slate-800/50 h-2 rounded-full overflow-hidden">
                    <div className="bg-emerald-500 h-full rounded-full" style={{ width: `${(stats.active / Math.max(1, stats.total)) * 100}%` }}></div>
                </div>
            </div>
          </Card>

          <Card decoration="top" decorationColor="amber" className="bg-slate-900/40 backdrop-blur-xl border-slate-800/60 shadow-lg">
            <Flex alignItems="start" justifyContent="between">
              <div>
                <Text className="text-slate-400">Cadastros Hoje</Text>
                <Metric className="text-white mt-2">{stats.today}</Metric>
              </div>
              <Badge color="amber" icon={Plus}>Novos</Badge>
            </Flex>
            <div className="mt-4 h-12">
              <SparkAreaChart
                data={chartData.slice(-3)}
                categories={["Novos Usuários"]}
                index="date"
                colors={["amber"]}
                className="h-full w-full"
              />
            </div>
          </Card>
        </Grid>

        {/* World Map Section - Central Rectangle */}
        <div className="mb-8">
          <UserWorldMap users={profiles} />
        </div>

        {/* Charts Section */}
        <Grid numItemsSm={1} numItemsLg={3} className="gap-6 mb-8">
          <Card className="col-span-1 lg:col-span-2 bg-slate-900/40 backdrop-blur-xl border-slate-800/60 shadow-lg">
            <Title className="text-white">Crescimento da Base</Title>
            <Text className="text-slate-400">Novos usuários nos últimos dias</Text>
            <AreaChart
              className="h-72 mt-4"
              data={chartData}
              index="date"
              categories={["Novos Usuários"]}
              colors={["blue"]}
              showAnimation={true}
              showGridLines={false}
              curveType="monotone"
            />
          </Card>
          
          <div className="col-span-1 flex flex-col gap-6">
            <Card className="bg-slate-900/40 backdrop-blur-xl border-slate-800/60 shadow-lg flex-1">
                <Title className="text-white">Proporção de Status</Title>
                <BarChart
                  className="mt-6 h-32"
                  data={statusData}
                  index="name"
                  categories={["Localizados", "Sem Localização"]}
                  colors={["emerald", "slate"]}
                  layout="vertical"
                  showYAxis={false}
                  showLegend={false}
                />
            </Card>

            <Card className="bg-slate-900/40 backdrop-blur-xl border-slate-800/60 shadow-lg flex-1">
              <Title className="text-white">Distribuição Global</Title>
              <DonutChart
                className="h-32 mt-4"
                data={countries}
                category="value"
                index="name"
                colors={["blue", "cyan", "indigo", "violet", "fuchsia"]}
                showAnimation={true}
              />
            </Card>
          </div>
        </Grid>

        {/* Main Table Section */}
        <Card className="bg-slate-900/40 backdrop-blur-xl border-slate-800/60 shadow-lg">
          <Flex className="mb-6" flexDirection="col" alignItems="stretch" justifyContent="start">
            <Title className="mb-4 text-white">Gerenciamento de Usuários</Title>
            <Grid numItemsMd={3} className="gap-4">
              <TextInput 
                icon={Search} 
                placeholder="Buscar por nome ou e-mail..." 
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="bg-slate-900/50 border-slate-700 text-white placeholder-slate-500"
              />
              <Select value={countryFilter} onValueChange={setCountryFilter} className="bg-slate-900/50 border-slate-700 text-white">
                <SelectItem value="all">Todos os Países</SelectItem>
                {countries.map(c => (
                  <SelectItem key={c.name} value={c.name}>{c.name}</SelectItem>
                ))}
              </Select>
              <Select value={statusFilter} onValueChange={setStatusFilter} className="bg-slate-900/50 border-slate-700 text-white">
                <SelectItem value="all">Todos os Status</SelectItem>
                <SelectItem value="online">Localizado</SelectItem>
                <SelectItem value="offline">Sem Localização</SelectItem>
              </Select>
            </Grid>
          </Flex>

        <Table className="mt-5">
          <TableHead>
            <TableRow>
              <TableHeaderCell onClick={() => handleSort('full_name')} className="cursor-pointer hover:text-white group">
                <Flex justifyContent="start" className="gap-2">Usuário <SortIcon column="full_name" /></Flex>
              </TableHeaderCell>
              <TableHeaderCell onClick={() => handleSort('phone')} className="cursor-pointer hover:text-white group">
                <Flex justifyContent="start" className="gap-2">Telefone <SortIcon column="phone" /></Flex>
              </TableHeaderCell>
              <TableHeaderCell onClick={() => handleSort('city')} className="cursor-pointer hover:text-white group">
                <Flex justifyContent="start" className="gap-2">Localização <SortIcon column="city" /></Flex>
              </TableHeaderCell>
              <TableHeaderCell onClick={() => handleSort('country')} className="cursor-pointer hover:text-white group">
                <Flex justifyContent="start" className="gap-2">País <SortIcon column="country" /></Flex>
              </TableHeaderCell>
              <TableHeaderCell onClick={() => handleSort('created_at')} className="cursor-pointer hover:text-white group">
                <Flex justifyContent="start" className="gap-2">Cadastro <SortIcon column="created_at" /></Flex>
              </TableHeaderCell>
              <TableHeaderCell>Ações</TableHeaderCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredProfiles.map((user) => (
              <TableRow 
                key={user.id} 
                className="hover:bg-slate-800/30 cursor-pointer transition-colors border-b border-slate-800/40 last:border-0"
                onClick={() => openDrawer(user)}
              >
                <TableCell>
                  <Flex justifyContent="start" className="gap-3">
                    <div className="w-10 h-10 rounded-xl bg-blue-900/40 border border-blue-800/50 flex items-center justify-center text-blue-400 font-bold text-lg shadow-inner">
                      {user.full_name?.[0] || 'U'}
                    </div>
                    <div>
                      <Text className="font-bold text-white">{user.full_name || 'Usuário'}</Text>
                      <Text className="text-xs text-slate-400">{user.email}</Text>
                    </div>
                  </Flex>
                </TableCell>
                <TableCell>
                  <Text className="font-medium text-slate-300">{user.phone || '---'}</Text>
                </TableCell>
                <TableCell>
                  {user.city || user.state ? (
                    <Badge color="emerald" icon={MapPin}>
                      {user.city}{user.city && user.state ? ', ' : ''}{user.state}
                    </Badge>
                  ) : (
                    <Badge color="slate">N/A</Badge>
                  )}
                </TableCell>
                <TableCell>
                  <Text>{user.country || '---'}</Text>
                </TableCell>
                <TableCell>
                  <Text>{user.created_at ? new Date(user.created_at).toLocaleDateString('pt-BR') : '---'}</Text>
                </TableCell>
                <TableCell>
                  <Button 
                    size="xs" 
                    variant="light" 
                    icon={Mail} 
                    color="blue"
                    onClick={(e) => {
                      e.stopPropagation();
                      window.location.href=`mailto:${user.email}`;
                    }}
                  >
                    Marketing
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        {filteredProfiles.length === 0 && (
          <div className="text-center py-20">
            <Text className="text-slate-400">Nenhum usuário encontrado com estes filtros.</Text>
          </div>
        )}
      </Card>

      {/* Side Drawer */}
      <Transition.Root show={!!selectedUser} as={Fragment}>
        <Dialog as="div" className="relative z-50" onClose={closeDrawer}>
          <Transition.Child
            as={Fragment}
            enter="ease-in-out duration-500"
            enterFrom="opacity-0"
            enterTo="opacity-100"
            leave="ease-in-out duration-500"
            leaveFrom="opacity-100"
            leaveTo="opacity-0"
          >
            <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity" />
          </Transition.Child>

          <div className="fixed inset-0 overflow-hidden">
            <div className="absolute inset-0 overflow-hidden">
              <div className="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
                <Transition.Child
                  as={Fragment}
                  enter="transform transition ease-in-out duration-500 sm:duration-700"
                  enterFrom="translate-x-full"
                  enterTo="translate-x-0"
                  leave="transform transition ease-in-out duration-500 sm:duration-700"
                  leaveFrom="translate-x-0"
                  leaveTo="translate-x-full"
                >
                  <Dialog.Panel className="pointer-events-auto w-screen max-w-md border-l border-slate-800/60 shadow-2xl">
                    <div className="flex h-full flex-col overflow-y-scroll bg-slate-950 shadow-xl">
                      {selectedUser && (
                        <>
                          <div className="relative h-48 bg-gradient-to-br from-slate-900 to-blue-900/40 border-b border-slate-800/60 p-8 flex flex-col items-center justify-center">
                            <button
                              type="button"
                              className="absolute top-4 right-4 text-slate-400 hover:text-white bg-slate-800/50 p-2 rounded-full"
                              onClick={closeDrawer}
                            >
                              <X className="h-5 w-5" />
                            </button>
                            <div className="w-20 h-20 bg-slate-800 rounded-2xl flex items-center justify-center text-blue-400 text-3xl font-black shadow-[0_0_15px_rgba(59,130,246,0.3)] mb-4 border border-slate-700">
                              {selectedUser.full_name?.[0] || 'U'}
                            </div>
                            <Title className="text-white text-xl tracking-tight">{selectedUser.full_name || 'Usuário'}</Title>
                            <Text className="text-blue-300 opacity-80 font-medium">{selectedUser.email}</Text>
                          </div>

                          <div className="p-8 space-y-8 flex-1">
                            <section>
                              <Title className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-4 flex items-center gap-2">
                                <Fingerprint className="w-4 h-4 text-slate-400" /> Informações da Conta
                              </Title>
                              <div className="grid grid-cols-1 gap-4">
                                <Card className="p-4 bg-slate-900/50 border-slate-800/50">
                                  <Text className="text-xs text-slate-500 mb-1">ID DO USUÁRIO</Text>
                                  <Text className="font-mono text-xs text-slate-300 break-all">{selectedUser.id}</Text>
                                </Card>
                                <Card className="p-4 bg-slate-900/50 border-slate-800/50">
                                  <Text className="text-xs text-slate-500 mb-1">TELEFONE</Text>
                                  <Text className="font-bold text-white">{selectedUser.phone || 'Não informado'}</Text>
                                </Card>
                                <Card className="p-4 bg-slate-900/50 border-slate-800/50">
                                  <Text className="text-xs text-slate-500 mb-1">LOCALIZAÇÃO ATUAL</Text>
                                  <Text className="font-bold text-white">{selectedUser.city ? `${selectedUser.city}, ${selectedUser.state}` : '---'}</Text>
                                  <Text className="text-xs text-slate-400">{selectedUser.country || ''}</Text>
                                </Card>
                              </div>
                            </section>

                            <section>
                              <Title className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-4 flex items-center gap-2">
                                <Plane className="w-4 h-4 text-slate-400" /> Itinerários Planejados
                              </Title>
                              {itinerariesLoading ? (
                                <div className="space-y-3">
                                  <div className="h-16 bg-slate-800/50 animate-pulse rounded-xl" />
                                  <div className="h-16 bg-slate-800/50 animate-pulse rounded-xl" />
                                </div>
                              ) : itineraries.length > 0 ? (
                                <div className="space-y-3">
                                  {itineraries.map(r => (
                                    <Card key={r.id} className="p-4 bg-slate-900/50 hover:border-blue-500/50 transition-colors cursor-pointer group border-slate-800/50">
                                      <Flex>
                                        <div className="flex items-center gap-3">
                                          <div className="p-2 bg-blue-900/30 rounded-lg text-blue-400 border border-blue-800/30">
                                            <MapPin className="w-4 h-4" />
                                          </div>
                                          <div>
                                            <Text className="font-bold text-white group-hover:text-blue-400 transition-colors">{r.destino}</Text>
                                            <Text className="text-xs text-slate-400">{r.created_at ? new Date(r.created_at).toLocaleDateString('pt-BR') : '---'}</Text>
                                          </div>
                                        </div>
                                        <ChevronRight className="w-4 h-4 text-slate-600" />
                                      </Flex>
                                    </Card>
                                  ))}
                                </div>
                              ) : (
                                <div className="bg-slate-900/30 border border-slate-800/50 rounded-xl p-8 text-center">
                                  <Text className="text-slate-500">Nenhum roteiro encontrado.</Text>
                                </div>
                              )}
                            </section>
                          </div>

                          <div className="p-6 border-t border-slate-800/60 bg-slate-950 mt-auto">
                            <Grid numItems={2} className="gap-3">
                              <Button variant="primary" icon={Mail} className="w-full shadow-[0_0_10px_rgba(59,130,246,0.2)]" onClick={() => window.location.href=`mailto:${selectedUser.email}`}>
                                E-mail
                              </Button>
                              <Button variant="secondary" className="w-full bg-slate-800/50 border-slate-700 text-white" onClick={() => navigator.clipboard.writeText(selectedUser.id)}>
                                Copiar ID
                              </Button>
                            </Grid>
                          </div>
                        </>
                      )}
                    </div>
                  </Dialog.Panel>
                </Transition.Child>
              </div>
            </div>
          </div>
        </Dialog>
      </Transition.Root>
      </div>
    </div>
  );
}
