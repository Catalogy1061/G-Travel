import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = 'https://zsprjastaiblctaoulof.supabase.co'
const SUPABASE_KEY = 'sb_publishable_dtoS4EyP8J4wmJ7IMRIv7A_VoCnXO6I'

export const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)

export const ADMIN_EMAIL = 'cleisoncel@gmail.com'
