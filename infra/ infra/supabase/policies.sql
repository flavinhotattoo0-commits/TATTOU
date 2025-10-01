-- =========
--  ATIVAR RLS
-- =========
alter table public.profiles       enable row level security;
alter table public.artists        enable row level security;
alter table public.clients        enable row level security;
alter table public.flash          enable row level security;
alter table public.appointments   enable row level security;
alter table public.orders         enable row level security;
alter table public.order_items    enable row level security;
alter table public.subscriptions  enable row level security;
alter table public.payouts        enable row level security;

alter table public.events         enable row level security;
alter table public.event_tiers    enable row level security;
alter table public.event_signups  enable row level security;

alter table public.products       enable row level security;
alter table public.coupons        enable row level security;
alter table public.shipping_rules enable row level security;
alter table public.order_shipping enable row level security;


-- =========
--  PERFIS / ARTISTAS / CLIENTES
-- =========
-- Profiles: cada usuário vê/edita apenas o seu
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
for select using (auth.uid() = user_id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
for update using (auth.uid() = user_id);

-- Artists: apenas o dono (user) gerencia seu registro
drop policy if exists artists_self on public.artists;
create policy artists_self on public.artists
for all using (auth.uid() = artist_id);

-- Clients: apenas o dono
drop policy if exists clients_self on public.clients;
create policy clients_self on public.clients
for all using (auth.uid() = client_id);


-- =========
--  FLASH TATTOOS
-- =========
-- Leitura pública; escrita apenas do artista dono
drop policy if exists flash_read_public on public.flash;
create policy flash_read_public on public.flash
for select using (true);

drop policy if exists flash_write_owner on public.flash;
create policy flash_write_owner on public.flash
for all using (auth.uid() = artist_id);


-- =========
--  AGENDAMENTOS
-- =========
-- Artista ou cliente envolvidos leem; artista pode escrever (confirmar/cancelar/etc)
drop policy if exists appt_read_self on public.appointments;
create policy appt_read_self on public.appointments
for select using (auth.uid() = artist_id or auth.uid() = client_id);

drop policy if exists appt_write_artist on public.appointments;
create policy appt_write_artist on public.appointments
for all using (auth.uid() = artist_id);


-- =========
--  PEDIDOS
-- =========
-- Orders: o comprador gerencia seus pedidos
drop policy if exists orders_buyer_all on public.orders;
create policy orders_buyer_all on public.orders
for all using (auth.uid() = buyer_id);

-- Order items: leitura se pertencer a um pedido do usuário
drop policy if exists order_items_by_order on public.order_items;
create policy order_items_by_order on public.order_items
for select using (
  exists (
    select 1 from public.orders o
    where o.id = order_id and o.buyer_id = auth.uid()
  )
);


-- =========
--  ASSINATURAS / REAPASSES
-- =========
drop policy if exists subs_self on public.subscriptions;
create policy subs_self on public.subscriptions
for select using (auth.uid() = user_id);

drop policy if exists payouts_artist on public.payouts;
create policy payouts_artist on public.payouts
for select using (auth.uid() = artist_id);


-- =========
--  EVENTOS
-- =========
-- events: leitura pública se publicado; organizador gerencia
drop policy if exists events_read_public on public.events;
create policy events_read_public on public.events
for select using (is_published = true or auth.uid() = organizer_id);

drop policy if exists events_write_owner on public.events;
create policy events_write_owner on public.events
for all using (auth.uid() = organizer_id);

-- event_tiers: leitura pública; organizador escreve
drop policy if exists tiers_read_public on public.event_tiers;
create policy tiers_read_public on public.event_tiers
for select using (true);

drop policy if exists tiers_write_owner on public.event_tiers;
create policy tiers_write_owner on public.event_tiers
for all using (
  exists (
    select 1 from public.events e
    where e.id = event_id and e.organizer_id = auth.uid()
  )
);

-- event_signups: usuário vê seus ingressos; organizador vê inscritos do seu evento;
-- insert: o próprio usuário cria a inscrição (pendente)
drop policy if exists signups_read_self_or_org on public.event_signups;
create policy signups_read_self_or_org on public.event_signups
for select using (
  user_id = auth.uid() or
  exists (
    select 1 from public.events e
    where e.id = event_id and e.organizer_id = auth.uid()
  )
);

drop policy if exists signups_write_self on public.event_signups;
create policy signups_write_self on public.event_signups
for insert with check (user_id = auth.uid());


-- =========
--  LOJA (produtos, cupons, frete, endereço)
-- =========
-- products: público lê ativos; vendedor edita os seus
drop policy if exists products_read_public on public.products;
create policy products_read_public on public.products
for select using (is_active = true);

drop policy if exists products_write_seller on public.products;
create policy products_write_seller on public.products
for all using (seller_id = auth.uid());

-- coupons: leitura pública (validação feita no backend)
drop policy if exists coupons_read_public on public.coupons;
create policy coupons_read_public on public.coupons
for select using (true);

-- shipping_rules: vendedor gerencia as suas
drop policy if exists shipping_rules_seller on public.shipping_rules;
create policy shipping_rules_seller on public.shipping_rules
for all using (seller_id = auth.uid());

-- order_shipping: comprador e vendedor podem visualizar
drop policy if exists order_shipping_buyer_or_seller on public.order_shipping;
create policy order_shipping_buyer_or_seller on public.order_shipping
for select using (
  -- comprador
  exists (
    select 1 from public.orders o
    where o.id = order_id and o.buyer_id = auth.uid()
  )
  -- vendedor de qualquer produto do pedido
  or exists (
    select 1
    from public.order_items oi
    join public.products p on p.id = oi.product_id
    where oi.order_id = order_id and p.seller_id = auth.uid()
  )
);
