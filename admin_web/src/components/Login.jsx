import React, { useState } from 'react';
import { supabase, ADMIN_EMAIL } from '../lib/supabase';
import { Card, TextInput, Button, Text, Title, Italic } from '@tremor/react';
import { Lock, Mail } from 'lucide-react';

export default function Login({ onLoginSuccess }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const { data, error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (signInError) throw signInError;
      
      if (data.user.email !== ADMIN_EMAIL) {
        await supabase.auth.signOut();
        throw new Error('Acesso negado: apenas o administrador tem acesso.');
      }

      onLoginSuccess();
    } catch (err) {
      setError(err.message || 'Erro ao realizar login');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950 px-4 relative overflow-hidden">
      {/* Subtle Background Glows */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-blue-900/20 rounded-full blur-[128px] pointer-events-none"></div>
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-indigo-900/20 rounded-full blur-[128px] pointer-events-none"></div>

      <Card className="max-w-md w-full p-8 shadow-2xl bg-slate-900/60 backdrop-blur-xl border border-slate-800/50 relative z-10">
        <div className="flex flex-col items-center mb-8">
          <div className="p-3 bg-slate-800/80 rounded-2xl mb-4 border border-slate-700 shadow-inner">
            <Lock className="w-8 h-8 text-blue-400 drop-shadow-[0_0_8px_rgba(96,165,250,0.5)]" />
          </div>
          <Title className="text-2xl font-bold text-white tracking-wide">G-TRAVEL Admin</Title>
          <Text className="text-slate-400 mt-1 uppercase tracking-widest text-xs font-semibold">Acesso Restrito</Text>
        </div>

        <form onSubmit={handleLogin} className="space-y-6">
          <div>
            <Text className="mb-2 font-medium text-slate-300">E-mail</Text>
            <TextInput
              icon={Mail}
              type="email"
              placeholder="seu@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="bg-slate-950/50 border-slate-800 text-slate-200"
            />
          </div>
          <div>
            <Text className="mb-2 font-medium text-slate-300">Senha</Text>
            <TextInput
              icon={Lock}
              type="password"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="bg-slate-950/50 border-slate-800 text-slate-200"
            />
          </div>

          {error && (
            <div className="p-3 bg-red-950/50 border border-red-900/50 rounded-lg">
              <Text className="text-red-400 text-sm font-medium">{error}</Text>
            </div>
          )}

          <Button
            type="submit"
            variant="primary"
            className="w-full py-3 text-lg font-bold shadow-[0_0_15px_rgba(59,130,246,0.2)] hover:shadow-[0_0_25px_rgba(59,130,246,0.4)] transition-all"
            loading={loading}
          >
            ENTRAR
          </Button>
        </form>
        
        <div className="mt-8 text-center">
          <Italic className="text-xs text-slate-600">
            Powered by Antigravity AI & Tremor
          </Italic>
        </div>
      </Card>
    </div>
  );
}
