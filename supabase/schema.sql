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

-- Satranç: internetten (oda kodu ile) oynanan iki kişilik maçlar.
-- `moves` her hamlede tam liste olarak yeniden yazılır (yalnızca sırası
-- gelen taraf yazdığı için yarış durumu yok); `code` kullanıcıya gösterilen
-- kısa paylaşılabilir koddur.

create table if not exists public.chess_rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  host_name text not null,
  guest_name text,
  time_control text not null,
  moves jsonb not null default '[]',
  status text not null default 'waiting',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.chess_rooms enable row level security;

-- `to anon, authenticated`: uygulamada AuthGate herkesi Google ile giriş
-- yaptırdığı için Supabase istekleri fiilen hep `authenticated` rolüyle
-- gidiyor (yalnızca `anon`'a izin vermek RLS'in isteği sessizce reddetmesine
-- yol açar — oda kurulamaz).
create policy "Anyone can create a chess room"
  on public.chess_rooms for insert
  to anon, authenticated
  with check (true);

create policy "Anyone can read chess rooms"
  on public.chess_rooms for select
  to anon, authenticated
  using (true);

create policy "Anyone can update a chess room"
  on public.chess_rooms for update
  to anon, authenticated
  using (true)
  with check (true);

-- Realtime: satır değişikliklerinin (misafirin katılması, yeni hamleler)
-- istemcilere yayınlanabilmesi için tabloyu `supabase_realtime`
-- publication'ına ekle (Supabase panelinde Database > Replication'dan da
-- açılabilir).
alter publication supabase_realtime add table public.chess_rooms;
