-- Ativar RLS
alter table public.profiles enable row level security;
alter table public.artists enable row level security;
alter table public.clients enable row level security;
alter table public.flash enable row level security;
alter table public.appointments enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.subscriptions enable row level security;
alter table public.payouts enable row level security;

-- Profiles: cada usuário só vê/edita o seu
create policy "profiles_select_own" on public.profiles
for select using (auth.uid() = user_id);
create policy "profiles_update_own" on public.profiles
for update using (auth.uid() = user_id);

-- Artists/Clients: só o dono
create policy "artists_self" on public.artists
for all using (auth.uid() = artist_id);
create policy "clients_self" on public.clients
for all using (auth.uid() = client_id);

-- Flash: leitura pública; edição só do artista dono
create policy "flash_read_public" on public.flash
for select using (true);
create policy "flash_write_owner" on public.flash
for all using (auth.uid() = artist_id);

-- Appointments: artista ou cliente envolvidos
create policy "appt_read_self" on public.appointments
for select using (auth.uid() = artist_id or auth.uid() = client_id);
create policy "appt_write_artist" on public.appointments
for all using (auth.uid() = artist_id);

-- Orders: comprador vê/gera seus pedidos
create policy "orders_buyer_all" on public.orders
for all using (auth.uid() = buyer_id);

-- Order items: leitura se o pedido é do usuário
create policy "order_items_by_order" on public.order_items
for select using (
  exists (select 1 from public.orders o where o.id = order_id and o.buyer_id = auth.uid())
);
