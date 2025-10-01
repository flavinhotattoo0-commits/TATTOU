-- Perfis (ligados ao auth.users)
create table if not exists public.profiles (
  user_id uuid primary key,
  role text check (role in ('client','artist','organizer','admin')) not null default 'client',
  name text,
  phone text,
  city text,
  created_at timestamptz default now()
);

-- Extensões úteis
create extension if not exists pgcrypto;

-- Trigger: cria profile automático ao registrar usuário
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id, name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name',''));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Artistas
create table if not exists public.artists (
  artist_id uuid primary key references public.profiles(user_id) on delete cascade,
  studio_name text,
  styles text[],
  slot_duration int default 60,
  created_at timestamptz default now()
);

-- Clientes
create table if not exists public.clients (
  client_id uuid primary key references public.profiles(user_id) on delete cascade,
  notes text,
  created_at timestamptz default now()
);

-- Flash tattoos
create table if not exists public.flash (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid references public.artists(artist_id) on delete cascade,
  title text not null,
  price_cents int not null,
  image_url text,
  is_available boolean default true,
  created_at timestamptz default now()
);

-- Agendamentos
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid references public.artists(artist_id) on delete cascade,
  client_id uuid references public.clients(client_id) on delete set null,
  flash_id uuid references public.flash(id) on delete set null,
  service_desc text,
  start_at timestamptz not null,
  end_at timestamptz not null,
  status text check (status in ('pending','confirmed','completed','cancelled','no_show')) default 'pending',
  deposit_cents int default 0,
  paid_cents int default 0,
  created_at timestamptz default now()
);

-- Pedidos
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid references public.profiles(user_id) on delete set null,
  total_cents int not null,
  currency text default 'BRL',
  status text check (status in ('requires_payment','paid','refunded','canceled')) default 'requires_payment',
  stripe_payment_intent text,
  created_at timestamptz default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references public.orders(id) on delete cascade,
  flash_id uuid references public.flash(id) on delete set null,
  qty int default 1,
  unit_price_cents int not null
);

-- Assinaturas
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(user_id) on delete cascade,
  plan text check (plan in ('pro','premium')),
  status text check (status in ('active','past_due','canceled')) default 'active',
  stripe_subscription_id text,
  current_period_end timestamptz
);

-- Repasses para artistas
create table if not exists public.payouts (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid references public.artists(artist_id) on delete cascade,
  amount_cents int not null,
  status text check (status in ('scheduled','paid','failed')) default 'scheduled',
  stripe_transfer_id text,
  created_at timestamptz default now()
);
