-- ATIVAR RLS
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

-- PROFILES
create policy profiles_select_own on public.profiles
for select using (auth.uid() = user_id);
create policy profiles_update_own on public.profiles
for update using (auth.uid() = user_id);

-- ARTISTS / CLIENTS
create policy artists_self on public.artists
for all using (auth.uid() = artist_id);
create policy clients_self on public.clients
for all using (auth.uid() = client_id);

-- FLASH
create policy flash_read_public on public.flash
for select using (true);
create policy flash_write_owner on public.flash
for all using (auth.uid() = artist_id);

-- APPOINTMENTS
create policy appt_read_self on public.appointments
for select using (auth.uid() = artist_id or auth.uid() = client_id);
create policy appt_write_artist on public.appointments
for all using (auth.uid() = artist_id);

-- ORDERS / ITEMS
create policy orders_buyer_all on public.orders
for all using (auth.uid() = buyer_id);

create policy order_items_by_order on public.order_items
for select using (
  exists (select 1 from public.orders o where o.id = order_id and o.buyer_id = auth.uid())
);

-- SUBSCRIPTIONS / PAYOUTS
create policy subs_self on public.subscriptions
for select using (auth.uid() = user_id);
create policy payouts_artist on public.payouts
for select using (auth.uid() = artist_id);

-- EVENTS
create policy events_read_public on public.events
for select using (is_published = true or auth.uid() = organizer_id);
create policy events_write_owner on public.events
for all using (auth.uid() = organizer_id);

create policy tiers_read_public on public.event_tiers
for select using (true);
create policy tiers_write_owner on public.event_tiers
for all using (
  exists (select 1 from public.events e where e.id = event_id and e.organizer_id = auth.uid())
);

create policy signups_read_self_or_org on public.event_signups
for select using (
  user_id = auth.uid() or
  exists (select 1 from public.events e where e.id = event_id and e.organizer_id = auth.uid())
);
create policy signups_write_self on public.event_signups
for insert with check (user_id = auth.uid());

-- LOJA
create policy products_read_public on public.products
for select using (is_active = true);
create policy products_write_seller on public.products
for all using (seller_id = auth.uid());

create policy coupons_read_public on public.coupons
for select using (true);

create policy shipping_rules_seller on public.shipping_rules
for all using (seller_id = auth.uid());

create policy order_shipping_buyer_or_seller on public.order_shipping
for select using (
  exists (select 1 from public.orders o where o.id = order_id and o.buyer_id = auth.uid())
  or exists (
    select 1
    from public.order_items oi
    join public.products p on p.id = oi.product_id
    where oi.order_id = order_id and p.seller_id = auth.uid()
  )
);
