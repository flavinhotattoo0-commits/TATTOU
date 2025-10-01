-- ========= EVENTOS (presencial / on-line / híbrido)

create table if not exists public.events (
  id              uuid primary key default gen_random_uuid(),
  organizer_id    uuid references public.profiles(user_id) on delete set null,
  title           text not null,
  description     text,
  event_type      text check (event_type in ('in_person','online','hybrid')) not null,
  venue_name      text,
  venue_address   text,
  city            text,
  start_at        timestamptz not null,
  end_at          timestamptz not null,
  capacity        int,
  is_published    boolean default false,
  online_provider text,
  online_url      text,
  created_at      timestamptz default now()
);

create table if not exists public.event_tiers (
  id           uuid primary key default gen_random_uuid(),
  event_id     uuid references public.events(id) on delete cascade,
  name         text not null,
  price_cents  int not null,
  currency     text default 'BRL',
  qty_total    int,
  qty_sold     int default 0,
  starts_at    timestamptz,
  ends_at      timestamptz
);

create table if not exists public.event_signups (
  id           uuid primary key default gen_random_uuid(),
  event_id     uuid references public.events(id) on delete cascade,
  tier_id      uuid references public.event_tiers(id) on delete set null,
  user_id      uuid references public.profiles(user_id) on delete cascade,
  status       text check (status in ('pending','paid','canceled','refunded')) default 'pending',
  qr_code_url  text,
  access_token text,
  joined_at    timestamptz,
  created_at   timestamptz default now()
);

-- ========= LOJA (produtos, cupons, frete, endereço)

create table if not exists public.products (
  id            uuid primary key default gen_random_uuid(),
  seller_id     uuid references public.artists(artist_id) on delete cascade,
  name          text not null,
  description   text,
  product_type  text check (product_type in ('physical','digital')) not null default 'physical',
  price_cents   int not null,
  currency      text default 'BRL',
  stock         int,
  weight_grams  int,
  dims_cm       text,
  digital_url   text,
  is_active     boolean default true,
  created_at    timestamptz default now()
);

create table if not exists public.coupons (
  code            text primary key,
  type            text check (type in ('percent','fixed')) not null,
  value_cents     int,
  percent         int,
  min_value_cents int,
  expires_at      timestamptz,
  active          boolean default true
);

create table if not exists public.shipping_rules (
  id              uuid primary key default gen_random_uuid(),
  seller_id       uuid references public.artists(artist_id) on delete cascade,
  origin_zip      text,
  free_over_cents int
);

create table if not exists public.order_shipping (
  order_id        uuid primary key references public.orders(id) on delete cascade,
  receiver_name   text,
  zip_code        text,
  address_line1   text,
  address_line2   text,
  city            text,
  state           text,
  freight_service text,
  freight_cents   int,
  tracking_code   text
);

-- Linkar itens de pedido com produtos da loja
alter table public.order_items
  add column if not exists product_id uuid references public.products(id);
