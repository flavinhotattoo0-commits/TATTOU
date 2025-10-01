-- Perfis (ligados ao auth.users)
create table if not exists public.profiles (
  user_id uuid primary key,
  role text check (role in ('client','artist','organizer','admin')) not null default 'client',
  name text,
  phone text,
  city text,
  created_at timestamptz default now()
);
