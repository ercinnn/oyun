-- Bombalı Sayılar oyun sonuçları tablosu.
-- Supabase Dashboard > SQL Editor içinde bir kez çalıştırın:
-- https://supabase.com/dashboard/project/fdvokdfuamwezuoffbyz/sql/new

create table if not exists public.game_results (
  id uuid primary key default gen_random_uuid(),
  player_name text not null,
  attempts integer not null,
  finished_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.game_results enable row level security;

-- Uygulamanın henüz kullanıcı girişi (auth) yok; anon anahtarla oynayan
-- herkes sonuç yazabilsin ve skor tablosunu okuyabilsin.
create policy "Anyone can insert game results"
  on public.game_results for insert
  to anon
  with check (true);

create policy "Anyone can read game results"
  on public.game_results for select
  to anon
  using (true);
