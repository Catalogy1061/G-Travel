import React, { useRef } from 'react';
import { motion, useScroll, useTransform, useSpring, useInView } from 'framer-motion';
import { 
  Plane, 
  Map, 
  ShieldCheck, 
  Wallet, 
  Sparkles, 
  ArrowRight,
  Download,
  LayoutDashboard,
  Globe,
  Zap,
  Smartphone,
  CheckCircle2,
  Menu,
  X
} from 'lucide-react';

const LandingPage = ({ onAdminClick, isLoggedIn }) => {
  const containerRef = useRef(null);
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"]
  });

  const smoothProgress = useSpring(scrollYProgress, {
    stiffness: 100,
    damping: 30,
    restDelta: 0.001
  });

  return (
    <div className="bg-slate-950 text-white selection:bg-purple-500/30 overflow-x-hidden font-sans">
      <Header onAdminClick={onAdminClick} isLoggedIn={isLoggedIn} />
      
      <main>
        <HeroSection />
        
        <div ref={containerRef} className="relative">
          <ScrollytellingSection progress={smoothProgress} />
        </div>

        <BentoGrid />
        
        <DownloadCTA />
      </main>

      <Footer onAdminClick={onAdminClick} isLoggedIn={isLoggedIn} />
    </div>
  );
};

// --- Sub-componentes ---

const Header = ({ onAdminClick, isLoggedIn }) => {
  return (
    <nav className="fixed top-0 w-full z-[100] px-6 py-4">
      <motion.div 
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="max-w-7xl mx-auto"
      >
        <div className="bg-slate-900/40 backdrop-blur-2xl border border-white/10 rounded-2xl px-6 py-3 flex items-center justify-between shadow-2xl shadow-purple-500/5">
          <div className="flex items-center gap-3 group cursor-pointer" onClick={() => window.scrollTo({top: 0, behavior: 'smooth'})}>
            <div className="w-10 h-10 bg-gradient-to-br from-purple-600 to-blue-600 rounded-xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform duration-300">
              <Plane className="text-white fill-current" size={22} />
            </div>
            <span className="text-xl font-bold tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-white to-slate-400">
              G-TRAVEL
            </span>
          </div>

          <div className="hidden md:flex items-center gap-8">
            <NavLink href="#features">Recursos</NavLink>
            <NavLink href="#app">O App</NavLink>
            <NavLink href="#security">Segurança</NavLink>
            <div className="h-4 w-[1px] bg-white/10 mx-2" />
            <button 
              onClick={onAdminClick}
              className="flex items-center gap-2 text-sm font-medium text-slate-400 hover:text-white transition-colors"
            >
              <LayoutDashboard size={16} />
              {isLoggedIn ? 'Dashboard' : 'Área Admin'}
            </button>
            <button className="bg-white text-black px-5 py-2 rounded-xl hover:bg-purple-500 hover:text-white transition-all duration-300 font-bold text-sm shadow-xl shadow-white/5">
              Baixar App
            </button>
          </div>

          <button className="md:hidden text-white p-2">
            <Menu size={24} />
          </button>
        </div>
      </motion.div>
    </nav>
  );
};

const NavLink = ({ href, children }) => (
  <a href={href} className="text-sm font-medium text-slate-400 hover:text-white transition-colors relative group">
    {children}
    <span className="absolute -bottom-1 left-0 w-0 h-[2px] bg-purple-500 transition-all group-hover:w-full" />
  </a>
);

const HeroSection = () => {
  return (
    <section className="relative min-h-screen flex items-center justify-center pt-20 overflow-hidden">
      {/* Background Orbs */}
      <div className="absolute top-1/4 -left-20 w-96 h-96 bg-purple-600/20 blur-[120px] rounded-full animate-pulse" />
      <div className="absolute bottom-1/4 -right-20 w-96 h-96 bg-blue-600/20 blur-[120px] rounded-full" />
      
      <div className="max-w-7xl mx-auto px-6 text-center z-10">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 1 }}
        >
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-purple-500/10 border border-purple-500/20 text-purple-400 text-xs font-bold uppercase tracking-widest mb-8">
            <Sparkles size={14} className="animate-spin-slow" />
            <span>A Revolução em Viagens Inteligentes</span>
          </div>
          
          <h1 className="text-6xl md:text-9xl font-black mb-8 leading-[0.9] tracking-tighter">
            EXPLORE O <br />
            <span className="bg-clip-text text-transparent bg-gradient-to-b from-white via-white to-white/40">
              INEXPLORADO.
            </span>
          </h1>
          
          <p className="text-xl md:text-2xl text-slate-400 max-w-3xl mx-auto mb-12 leading-relaxed">
            Roteiros gerados por IA, controle financeiro em tempo real e segurança global. 
            Tudo o que você precisa para a sua próxima jornada em um único lugar.
          </p>
          
          <div className="flex flex-col md:flex-row items-center justify-center gap-6">
            <motion.button 
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="bg-white text-black px-10 py-5 rounded-2xl font-black text-lg transition-all shadow-[0_0_40px_rgba(255,255,255,0.2)] flex items-center gap-3 group"
            >
              Baixar o G-TRAVEL
              <ArrowRight className="group-hover:translate-x-1 transition-transform" />
            </motion.button>
            <button className="text-white/60 hover:text-white px-10 py-5 rounded-2xl font-bold text-lg transition-all flex items-center gap-2">
              <Zap size={20} className="text-purple-500" />
              Ver Demonstração
            </button>
          </div>
        </motion.div>

        {/* Hero Mockup */}
        <motion.div
          initial={{ opacity: 0, y: 100 }}
          animate={{ opacity: 1, y: 50 }}
          transition={{ delay: 0.5, duration: 1.2 }}
          className="mt-20 max-w-5xl mx-auto relative group"
        >
          <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-transparent to-transparent z-20" />
          <div className="absolute -inset-4 bg-gradient-to-r from-purple-500/20 to-blue-500/20 blur-3xl opacity-0 group-hover:opacity-100 transition-opacity duration-1000" />
          <img 
            src="/assets/home.png" 
            alt="Dashboard" 
            className="w-full rounded-t-[3rem] border-x border-t border-white/10 shadow-2xl transition-transform duration-700 group-hover:scale-[1.02]"
          />
        </motion.div>
      </div>
    </section>
  );
};

const ScrollytellingSection = ({ progress }) => {
  const steps = [
    {
      title: "Roteiros Personalizados com IA",
      description: "Nossa IA analisa seu perfil, orçamento e interesses para criar o roteiro perfeito. Esqueça guias genéricos.",
      image: "/assets/home.png",
      icon: <Sparkles className="text-purple-400" size={32} />
    },
    {
      title: "Finanças Sob Controle",
      description: "Gestão de gastos multi-moeda com câmbio automático. Saiba exatamente quanto está gastando em cada categoria.",
      image: "/assets/finance.png",
      icon: <Wallet className="text-blue-400" size={32} />
    },
    {
      title: "Logística Inteligente",
      description: "Busca de voos, hotéis e aluguel de veículos integrada. Tudo o que você precisa para se mover pelo mundo.",
      image: "/assets/logistics.png",
      icon: <Map className="text-emerald-400" size={32} />
    },
    {
      title: "Segurança em Primeiro Lugar",
      description: "Botão SOS 24h, dicas de saúde local e alertas de segurança em tempo real para sua paz de espírito.",
      image: "/assets/security.png",
      icon: <ShieldCheck className="text-red-400" size={32} />
    }
  ];

  // Índice da tela atual baseado no scroll
  const stepIndex = useTransform(progress, [0, 0.25, 0.5, 0.75, 1], [0, 0, 1, 2, 3]);
  const [currentStep, setCurrentStep] = React.useState(0);
  
  React.useEffect(() => {
    return stepIndex.onChange(v => setCurrentStep(Math.round(v)));
  }, [stepIndex]);

  return (
    <section id="app" className="min-h-[400vh] py-20 px-6">
      <div className="max-w-7xl mx-auto flex flex-col md:flex-row gap-20">
        {/* Lado Esquerdo: Texto Progressivo */}
        <div className="flex-1 space-y-[80vh] py-[20vh]">
          {steps.map((step, i) => (
            <div key={i} className="min-h-[60vh] flex flex-col justify-center">
              <motion.div
                initial={{ opacity: 0, x: -50 }}
                whileInView={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.8 }}
                viewport={{ margin: "-20% 0px -20% 0px" }}
              >
                <div className="mb-6 p-4 bg-white/5 rounded-2xl w-fit">
                  {step.icon}
                </div>
                <h2 className="text-5xl md:text-7xl font-bold mb-8">{step.title}</h2>
                <p className="text-xl md:text-2xl text-slate-400 leading-relaxed max-w-lg">
                  {step.description}
                </p>
              </motion.div>
            </div>
          ))}
        </div>

        {/* Lado Direito: Celular Fixo */}
        <div className="hidden md:block flex-1 sticky top-0 h-screen flex items-center justify-center">
          <div className="relative w-[340px] h-[700px]">
            {/* iPhone Frame */}
            <div className="absolute inset-0 bg-slate-900 rounded-[3rem] border-[8px] border-slate-800 shadow-2xl z-10 overflow-hidden">
              {/* Dynamic Screen Content */}
              <motion.div 
                key={currentStep}
                initial={{ opacity: 0, scale: 1.1 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9 }}
                transition={{ duration: 0.5 }}
                className="w-full h-full"
              >
                <img 
                  src={steps[currentStep].image} 
                  className="w-full h-full object-cover"
                  alt="App Screen" 
                />
              </motion.div>
              
              {/* Dynamic Overlay Glow */}
              <div className={`absolute inset-0 pointer-events-none opacity-20 transition-colors duration-1000 ${
                currentStep === 0 ? 'bg-purple-500' : 
                currentStep === 1 ? 'bg-blue-500' : 
                currentStep === 2 ? 'bg-emerald-500' : 'bg-red-500'
              }`} />
            </div>
            
            {/* Notch */}
            <div className="absolute top-4 left-1/2 -translate-x-1/2 w-32 h-6 bg-slate-800 rounded-full z-20" />
            
            {/* Background Glow */}
            <div className="absolute -inset-20 bg-purple-500/10 blur-[100px] -z-10 animate-pulse" />
          </div>
        </div>
      </div>
    </section>
  );
};

const BentoGrid = () => {
  return (
    <section id="features" className="py-32 px-6">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-20">
          <h2 className="text-4xl md:text-6xl font-bold mb-6 italic">Feito para quem viaja de verdade.</h2>
          <p className="text-slate-400 text-xl">Detalhes que fazem a diferença na hora do embarque.</p>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-4 grid-rows-2 gap-6 h-auto md:h-[800px]">
          <BentoCard 
            className="md:col-span-2 md:row-span-2 bg-gradient-to-br from-purple-900/40 to-slate-900/40"
            icon={<Globe className="text-purple-400" size={40} />}
            title="Sincronização Global"
            description="Seus dados salvos na nuvem e acessíveis de qualquer dispositivo, em qualquer lugar do mundo."
          />
          <BentoCard 
            className="md:col-span-2 bg-slate-900/40"
            icon={<Zap className="text-yellow-400" size={32} />}
            title="Offline First"
            description="Acesse seus roteiros e documentos mesmo sem conexão com a internet."
          />
          <BentoCard 
            className="bg-slate-900/40"
            icon={<Smartphone className="text-blue-400" size={32} />}
            title="Interface Intuitiva"
            description="UX desenhada para ser rápida e funcional."
          />
          <BentoCard 
            className="bg-slate-900/40"
            icon={<CheckCircle2 className="text-emerald-400" size={32} />}
            title="Suporte 24h"
            description="Estamos com você em cada etapa da jornada."
          />
        </div>
      </div>
    </section>
  );
};

const BentoCard = ({ className, icon, title, description }) => (
  <motion.div 
    whileHover={{ y: -5 }}
    className={`p-10 rounded-[2.5rem] border border-white/5 hover:border-white/20 transition-all flex flex-col justify-between group ${className}`}
  >
    <div className="mb-6 p-4 bg-white/5 rounded-2xl w-fit group-hover:scale-110 transition-transform duration-500">
      {icon}
    </div>
    <div>
      <h3 className="text-2xl font-bold mb-4">{title}</h3>
      <p className="text-slate-400 leading-relaxed">{description}</p>
    </div>
  </motion.div>
);

const DownloadCTA = () => (
  <section className="py-32 px-6">
    <div className="max-w-5xl mx-auto">
      <div className="bg-gradient-to-br from-purple-600 to-blue-700 rounded-[3rem] p-12 md:p-20 text-center relative overflow-hidden shadow-2xl shadow-purple-500/20">
        <div className="absolute top-0 left-0 w-full h-full bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] opacity-10" />
        <h2 className="text-5xl md:text-7xl font-black mb-8 relative z-10">Pronto para a sua <br /> melhor viagem?</h2>
        <p className="text-white/80 text-xl mb-12 max-w-xl mx-auto relative z-10 italic">
          Junte-se a milhares de viajantes que já estão vivendo o futuro com o G-TRAVEL.
        </p>
        <div className="flex flex-col md:flex-row items-center justify-center gap-6 relative z-10">
          <button className="bg-white text-black px-12 py-5 rounded-2xl font-black text-xl hover:bg-slate-100 transition-all flex items-center gap-3">
            <Download size={24} />
            Baixar no iOS
          </button>
          <button className="bg-white text-black px-12 py-5 rounded-2xl font-black text-xl hover:bg-slate-100 transition-all flex items-center gap-3">
            <Download size={24} />
            Android APK
          </button>
        </div>
      </div>
    </div>
  </section>
);

const Footer = ({ onAdminClick, isLoggedIn }) => (
  <footer className="py-20 px-6 border-t border-white/5 bg-slate-950">
    <div className="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-center gap-10">
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 bg-purple-600 rounded-xl flex items-center justify-center">
          <Plane className="text-white" size={20} />
        </div>
        <span className="text-2xl font-bold tracking-tighter">G-TRAVEL</span>
      </div>
      
      <div className="text-slate-500 text-sm font-medium">
        © 2026 G-TRAVEL. Inteligência Artificial em Movimento.
      </div>
      
      <div className="flex items-center gap-8">
        <button 
          onClick={onAdminClick}
          className="text-sm font-bold text-slate-400 hover:text-white transition-colors uppercase tracking-widest"
        >
          {isLoggedIn ? 'Dashboard' : 'Acesso Administrativo'}
        </button>
        <div className="flex gap-4">
          <a href="#" className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center hover:bg-white/10 transition-colors border border-white/10">
            <X size={18} />
          </a>
        </div>
      </div>
    </div>
  </footer>
);

export default LandingPage;
