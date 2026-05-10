import React, { useState, useEffect } from 'react';
import { supabase, ADMIN_EMAIL } from './lib/supabase';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import { Text } from '@tremor/react';

function App() {
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(true);

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
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  if (loading) {
    return (
      <div className="h-screen w-screen flex flex-col items-center justify-center bg-slate-900">
        <div className="w-16 h-16 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mb-4"></div>
        <Text className="text-white font-medium">Carregando G-TRAVEL Admin...</Text>
      </div>
    );
  }

  return (
    <div className="App dark min-h-screen bg-slate-950 text-slate-50">
      {session ? <Dashboard /> : <Login onLoginSuccess={() => {}} />}
    </div>
  );
}

export default App;
