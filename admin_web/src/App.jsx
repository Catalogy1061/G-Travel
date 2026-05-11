import React, { useState, useEffect } from 'react';
import { supabase, ADMIN_EMAIL } from './lib/supabase';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import LandingPage from './components/LandingPage';
import { Text } from '@tremor/react';

function App() {
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(true);
  const [showLogin, setShowLogin] = useState(false);
  const [view, setView] = useState('landing'); // 'landing' ou 'admin'

  useEffect(() => {
    // Check initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session && session.user.email === ADMIN_EMAIL) {
        setSession(session);
      }
      setLoading(false);
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (session && session.user.email === ADMIN_EMAIL) {
        setSession(session);
      } else {
        setSession(null);
        setView('landing'); // Volta para landing ao deslogar
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  if (loading) {
    return (
      <div className="h-screen w-screen flex flex-col items-center justify-center bg-slate-950">
        <div className="w-16 h-16 border-4 border-purple-500 border-t-transparent rounded-full animate-spin mb-4 shadow-lg shadow-purple-500/20"></div>
        <Text className="text-white font-medium">Iniciando G-TRAVEL Experience...</Text>
      </div>
    );
  }

  // Se estiver logado e na visão admin, mostra o Dashboard
  if (session && view === 'admin') {
    return (
      <div className="App dark min-h-screen bg-slate-950 text-slate-50">
        <Dashboard onBackToLanding={() => setView('landing')} />
      </div>
    );
  }

  // Caso contrário, mostra sempre a Landing Page
  return (
    <div className="App dark min-h-screen bg-slate-950 text-slate-50 relative">
      <LandingPage 
        onAdminClick={() => {
          if (session) {
            setView('admin');
          } else {
            setShowLogin(true);
          }
        }} 
        isLoggedIn={!!session}
      />
      
      {showLogin && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-950/80 backdrop-blur-xl">
          <div className="relative w-full max-w-md p-4">
            <button 
              onClick={() => setShowLogin(false)}
              className="absolute top-8 right-8 text-slate-400 hover:text-white transition-colors"
            >
              Fechar
            </button>
            <Login onLoginSuccess={() => {
              setShowLogin(false);
              setView('admin');
            }} />
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
