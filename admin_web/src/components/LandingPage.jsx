import React from 'react';
import { motion } from 'framer-motion';
import { 
  Plane, 
  Map, 
  ShieldCheck, 
  Wallet, 
  Sparkles, 
  ArrowRight,
  Download,
  LayoutDashboard
} from 'lucide-react';

const LandingPage = ({ onAdminClick }) => {
  return (
    <div className="bg-slate-950 text-white selection:bg-purple-500/30 overflow-x-hidden">
      {/* Navbar */}
      <nav className="fixed top-0 w-full z-50 bg-slate-950/80 backdrop-blur-md border-b border-white/5">
        <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 bg-gradient-to-br from-purple-600 to-blue-600 rounded-xl flex items-center justify-center shadow-lg shadow-purple-500/20">
              <Plane className="text-white fill-current" size={24} />
            </div>
            <span className="text-2xl font-bold tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-white to-slate-400">
              G-TRAVEL
            </span>
          </div>
          
          <div className="hidden md:flex items-center gap-8 text-sm font-medium text-slate-400">
            <a href="#features" className="hover:text-white transition-colors">Funcionalidades</a>
            <a href="#app" className="hover:text-white transition-colors">O App</a>
            <button 
              onClick={onAdminClick}
              className="flex items-center gap-2 text-slate-400 hover:text-white transition-colors"
            >
              <LayoutDashboard size={18} />
              Admin
            </button>
            <button className="bg-white text-black px-6 py-2.5 rounded-full hover:bg-slate-200 transition-all font-semibold">
              Download
            </button>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative pt-32 pb-20 px-6">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[600px] bg-purple-600/10 blur-[120px] rounded-full pointer-events-none" />
        
        <div className="max-w-7xl mx-auto text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/5 border border-white/10 text-purple-400 text-sm font-medium mb-8">
              <Sparkles size={16} />
              <span>Inteligência Artificial aplicada a viagens</span>
            </div>
            
            <h1 className="text-6xl md:text-8xl font-black mb-8 leading-[1.1] tracking-tight">
              A Viagem do Futuro <br />
              <span className="bg-clip-text text-transparent bg-gradient-to-r from-purple-400 via-blue-400 to-emerald-400">
                Começa Aqui.
              </span>
            </h1>
            
            <p className="text-xl text-slate-400 max-w-2xl mx-auto mb-12 leading-relaxed">
              Roteiros personalizados, controle financeiro em tempo real e segurança total para sua jornada. Tudo em um só lugar.
            </p>
            
            <div className="flex flex-col md:flex-row items-center justify-center gap-4">
              <button className="w-full md:w-auto bg-purple-600 hover:bg-purple-500 text-white px-10 py-4 rounded-2xl font-bold text-lg transition-all shadow-xl shadow-purple-500/25 flex items-center justify-center gap-2">
                Baixar agora
                <ArrowRight size={20} />
              </button>
              <button className="w-full md:w-auto bg-white/5 hover:bg-white/10 text-white px-10 py-4 rounded-2xl font-bold text-lg transition-all border border-white/10">
                Ver demonstração
              </button>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.4, duration: 1 }}
            className="mt-20 relative"
          >
            <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-transparent to-transparent z-10" />
            <img 
              src="/mockup.png" 
              alt="G-TRAVEL App Mockup" 
              className="w-full max-w-4xl mx-auto drop-shadow-[0_0_50px_rgba(108,99,255,0.3)]"
            />
          </motion.div>
        </div>
      </section>

      {/* Features Grid */}
      <section id="features" className="py-32 px-6 bg-slate-950">
        <div className="max-w-7xl mx-auto">
          <div className="grid md:grid-cols-3 gap-8">
            <FeatureCard 
              icon={<Map className="text-purple-400" />}
              title="Roteiros com IA"
              description="A nossa inteligência artificial cria planos de viagem únicos baseados no seu perfil e orçamento."
            />
            <FeatureCard 
              icon={<Wallet className="text-blue-400" />}
              title="Controle Financeiro"
              description="Gestão completa de gastos, câmbio e orçamentos para você nunca sair do planejado."
            />
            <FeatureCard 
              icon={<ShieldCheck className="text-emerald-400" />}
              title="Segurança & Saúde"
              description="Informações essenciais sobre segurança local e emergências em tempo real."
            />
          </div>
        </div>
      </section>

      {/* Scrollytelling Section */}
      <section id="app" className="py-32 px-6">
        <div className="max-w-7xl mx-auto">
          <div className="flex flex-col md:flex-row gap-20 items-center">
            <div className="flex-1 space-y-20">
              <ScrollStep 
                title="Planejamento Sem Estresse"
                description="Otimize seu tempo com roteiros gerados em segundos. A IA cuida da logística para você só curtir a paisagem."
              />
              <ScrollStep 
                title="Tudo em um só lugar"
                description="Hospedagem, passagens, ingressos e dicas locais. Esqueça os 50 apps diferentes para viajar."
              />
              <ScrollStep 
                title="Offline First"
                description="Acesse suas informações mesmo sem internet. Seus dados estão sempre com você."
              />
            </div>
            
            <div className="flex-1 sticky top-32 h-[600px] hidden md:block">
              <motion.div
                initial={{ rotateY: -20, rotateX: 10 }}
                animate={{ rotateY: 0, rotateX: 0 }}
                transition={{ duration: 2, repeat: Infinity, repeatType: "reverse" }}
                className="w-full h-full bg-gradient-to-br from-purple-500/20 to-blue-500/20 rounded-[3rem] border border-white/10 backdrop-blur-3xl p-4 flex items-center justify-center"
              >
                <img 
                  src="/mockup.png" 
                  alt="App Interface" 
                  className="h-full object-contain drop-shadow-2xl"
                />
              </motion.div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-20 px-6 border-t border-white/5 bg-slate-950">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-center gap-10">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-purple-600 rounded-lg flex items-center justify-center">
              <Plane className="text-white" size={18} />
            </div>
            <span className="text-xl font-bold">G-TRAVEL</span>
          </div>
          
          <div className="text-slate-500 text-sm">
            © 2026 G-TRAVEL. Todos os direitos reservados.
          </div>
          
          <div className="flex gap-6">
            <button 
              onClick={onAdminClick}
              className="text-slate-400 hover:text-white transition-colors"
            >
              Área Administrativa
            </button>
            <a href="#" className="text-slate-400 hover:text-white">Privacidade</a>
            <a href="#" className="text-slate-400 hover:text-white">Termos</a>
          </div>
        </div>
      </footer>
    </div>
  );
};

const FeatureCard = ({ icon, title, description }) => (
  <motion.div 
    whileHover={{ y: -10 }}
    className="p-10 rounded-[2.5rem] bg-white/5 border border-white/10 hover:border-purple-500/50 transition-all group"
  >
    <div className="w-16 h-16 rounded-2xl bg-white/5 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
      {icon}
    </div>
    <h3 className="text-2xl font-bold mb-4">{title}</h3>
    <p className="text-slate-400 leading-relaxed">{description}</p>
  </motion.div>
);

const ScrollStep = ({ title, description }) => (
  <motion.div
    initial={{ opacity: 0, x: -20 }}
    whileInView={{ opacity: 1, x: 0 }}
    viewport={{ once: true }}
    className="space-y-4"
  >
    <h3 className="text-4xl font-bold text-white">{title}</h3>
    <p className="text-xl text-slate-400 leading-relaxed max-w-md">{description}</p>
  </motion.div>
);

export default LandingPage;
