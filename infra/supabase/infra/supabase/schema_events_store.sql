-- =========
--  SCHEMA: EVENTOS (presencial / on-line / híbrido)
-- =========

-- Tipos: 'in_person' | 'online' | 'hybrid'
create table if not exists public.events (
  id              uuid primary key default gen_random_uuid(),
  organizer_id    uuid references public.profiles(user_id) on delete set null,
  title           text not null,
  description     text,
  event_type      text check (event_type in ('in_person','online','hybrid')) not null,
  -- Presencial
  venue_name      text,
  venue_address   text,
  city            text,
  -- Datas
  start_at        timestamptz not null,
  end_at          timestamptz not null,
  -- Capacidade e publicação
  capacity        int,
  is_published    boolean default false,
  -- On-line
  online_provider text,           -- 'zoom','youtube','custom'
  online_url      text,           -- manter privado; acesso por token do signup
  created_at      timestamptz default now()
);

create index if not exists idx_events_start_at on public.events(start_at);
create index if not exists idx_events_city on public.events(city);

-- Lotes/tiers (ex.: Early Bird, VIP, Meia)
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

create index if not exists idx_event_tiers_event on public.event_tiers(event_id);

-- Inscrições / ingressos
-- status: 'pending' | 'paid' | 'canceled' | 'refunded'
create table if not exists public.event_signups (
  id             uuid primary key default gen_random_uuid(),
  event_id       uuid references public.events(id) on delete cascade,
  tier_id        uuid references public.event_tiers(id) on delete set null,
  user_id        uuid references public.profiles(user_id) on delete cascade,
  status         text check (status in ('pending','paid','canceled','refunded')) default 'pending',
  qr_code_url    text,        -- gerado após pagamento
  access_token   text,        -- para evento on-line
  joined_at      timestamptz,
  created_at     timestamptz default now()
);

create index if not exists idx_event_signups_event on public.event_signups(event_id);
create index if not exists idx_event_signups_user on public.event_signups(user_id);


-- =========
--  SCHEMA: LOJA (produtos físicos e digitais) + CUPONS + FRETE
-- =========

-- product_type: 'physical' | 'digital'
create table if not exists public.products (
  id              uuid primary key default gen_random_uuid(),
  seller_id       uuid references public.artists(artist_id) on delete cascade,
  name            text not null,
  description     text,
  product_type    text check (product_type in ('physical','digital')) not null default 'physical',
  price_cents     int not null,
  currency        text default 'BRL',
  stock           int,
  weight_grams    int,   -- físicos
  dims_cm         text,  -- "10x5x3"
  digital_url     text,  -- storage (acesso por URL assinada)
  is_active       boolean default true,
  created_at      timestamptz default now()
);

create index if not exists idx_products_seller on public.products(seller_id);
create index if not exists idx_products_active on public.products(is_active);

-- Cupons
-- type: 'percent' | 'fixed'
create table if not exists public.coupons (
  code            text primary key,
  type            text check (type in ('percent','fixed')) not null,
  value_cents     int,   -- usado se type='fixed'
  percent         int,   -- usado se type='percent'
  min_value_cents int,
  expires_at      timestamptz,
  active          boolean default true
);

-- Regras de frete do vendedor
create table if not exists public.shipping_rules (
  id              uuid primary key default gen_random_uuid(),
  seller_id       uuid references public.artists(artist_id) on delete cascade,
  origin_zip      text,
  free_over_cents int
);

-- Endereço/entrega por pedido (se tiver item físico)
create table if not exists public.order_shipping (
  order_id        uuid primary key references public.orders(id) on delete cascade,
  receiver_name   text,
  zip_code        text,
  address_line1   text,
  address_line2   text,
  city            text,
  state           text,
  freight_service text,        -- "PAC" | "SEDEX"
  freight_cents   int,
  tracking_code   text
);

-- Adiciona product_id nos itens de pedido (mantém flash_id para o marketplace de flash)
alter table public.order_items
  add column if not exists product_id uuid references public.products(id);

create index if not exists idx_order_items_product on public.order_items(product_id);
