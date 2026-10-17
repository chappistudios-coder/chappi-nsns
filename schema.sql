-- Highway Eat: Supabase schema with Row Level Security. NOT YET RUN AND NOT YET TESTED.
-- Read it, then run it once in Supabase > SQL Editor. Safe to read; it contains no secrets.
-- Roles are stored in profiles.roles and can only be changed by an admin (see triggers below).
-- To make yourself the first admin, after you sign up run:
--   update public.profiles set roles = array['customer','admin'] where phone = '+91XXXXXXXXXX';

create extension if not exists pgcrypto;

-- ---------- profiles ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  phone text unique,
  roles text[] not null default array['customer'],
  kitchen_id uuid,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and 'admin' = any(roles));
$$;

create or replace function public.my_kitchen() returns uuid
language sql stable security definer set search_path = public as $$
  select kitchen_id from public.profiles where id = auth.uid();
$$;

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, phone, name)
  values (new.id, new.phone, coalesce(new.raw_user_meta_data->>'name', ''))
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.protect_profile() returns trigger
language plpgsql as $$
begin
  if not public.is_admin() then
    new.roles := old.roles; new.kitchen_id := old.kitchen_id; new.phone := old.phone; new.id := old.id;
  end if;
  return new;
end $$;
drop trigger if exists protect_profile on public.profiles;
create trigger protect_profile before update on public.profiles
  for each row execute function public.protect_profile();

alter table public.profiles enable row level security;
create policy "profile: read own or admin" on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_admin());
create policy "profile: update own or admin" on public.profiles for update to authenticated
  using (id = auth.uid() or public.is_admin()) with check (id = auth.uid() or public.is_admin());

-- ---------- kitchens ----------
create table if not exists public.kitchens (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id),
  name text not null,
  lat double precision, lng double precision,
  veg boolean not null default false,
  area text not null default '',
  capacity int not null default 20 check (capacity > 0),
  prep_minutes int not null default 25,
  commission_pct int not null default 15,
  rating numeric not null default 0,
  rating_count int not null default 0,
  active boolean not null default false,
  created_at timestamptz not null default now()
);
create or replace function public.protect_kitchen() returns trigger
language plpgsql as $$
begin
  if not public.is_admin() then
    new.owner_id := old.owner_id; new.active := old.active; new.commission_pct := old.commission_pct;
    new.rating := old.rating; new.rating_count := old.rating_count;
  end if;
  return new;
end $$;
drop trigger if exists protect_kitchen on public.kitchens;
create trigger protect_kitchen before update on public.kitchens
  for each row execute function public.protect_kitchen();

alter table public.kitchens enable row level security;
create policy "kitchen: public sees active" on public.kitchens for select to anon, authenticated
  using (active or owner_id = auth.uid() or public.is_admin());
create policy "kitchen: owner updates" on public.kitchens for update to authenticated
  using (owner_id = auth.uid() or public.is_admin()) with check (owner_id = auth.uid() or public.is_admin());
create policy "kitchen: admin creates" on public.kitchens for insert to authenticated
  with check (public.is_admin());

-- ---------- dishes a kitchen cooks (dish_key = key of the CAT catalogue in the app) ----------
create table if not exists public.kitchen_dishes (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references public.kitchens(id) on delete cascade,
  dish_key text not null,
  status text not null default 'available',
  daily_cap int not null default 20,
  unique (kitchen_id, dish_key)
);
alter table public.kitchen_dishes enable row level security;
create policy "dish: public reads active kitchens" on public.kitchen_dishes for select to anon, authenticated
  using (exists (select 1 from public.kitchens k where k.id = kitchen_id and (k.active or k.owner_id = auth.uid())) or public.is_admin());
create policy "dish: owner writes" on public.kitchen_dishes for all to authenticated
  using (kitchen_id = public.my_kitchen() or public.is_admin())
  with check (kitchen_id = public.my_kitchen() or public.is_admin());

-- ---------- 7-day menu a kitchen posts ----------
create table if not exists public.weekly_menus (
  kitchen_id uuid primary key references public.kitchens(id) on delete cascade,
  start_date date not null,
  days jsonb not null default '[]'::jsonb,   -- 7 items: {items:[dish_key], note:text}
  updated_at timestamptz not null default now()
);
alter table public.weekly_menus enable row level security;
create policy "menu: signed-in read" on public.weekly_menus for select to authenticated using (true);
create policy "menu: owner writes" on public.weekly_menus for all to authenticated
  using (kitchen_id = public.my_kitchen() or public.is_admin())
  with check (kitchen_id = public.my_kitchen() or public.is_admin());

-- ---------- customer extras / choice for each day ----------
create table if not exists public.meal_picks (
  customer_id uuid not null references auth.users(id) on delete cascade,
  kitchen_id uuid not null references public.kitchens(id) on delete cascade,
  day date not null,
  roti int not null default 0 check (roti between 0 and 4),
  rice int not null default 0 check (rice between 0 and 4),
  dal int not null default 0 check (dal between 0 and 4),
  choice text not null default '',
  primary key (customer_id, kitchen_id, day)
);
alter table public.meal_picks enable row level security;
create policy "pick: customer all own" on public.meal_picks for all to authenticated
  using (customer_id = auth.uid()) with check (customer_id = auth.uid());
create policy "pick: kitchen reads its own" on public.meal_picks for select to authenticated
  using (kitchen_id = public.my_kitchen() or public.is_admin());

-- ---------- subscriptions ----------
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id) on delete cascade,
  tier text not null check (tier in ('basic','pro','gold','platinum')),
  days int not null check (days in (7,30)),
  size text not null check (size in ('full','half')),
  done int not null default 0,
  skips_used int not null default 0,
  pauses_used int not null default 0,
  changes_used int not null default 0,
  paused boolean not null default false,
  slot text,
  address jsonb,
  starts_at timestamptz not null default now(),
  expires_at timestamptz,
  menu jsonb, custom jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.subscriptions enable row level security;
create policy "sub: customer all own" on public.subscriptions for all to authenticated
  using (customer_id = auth.uid()) with check (customer_id = auth.uid());
create policy "sub: admin reads" on public.subscriptions for select to authenticated using (public.is_admin());

-- ---------- orders ----------
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id),
  kitchen_id uuid not null references public.kitchens(id),
  lines jsonb not null,                       -- [{dish_key,size,qty}]
  status text not null default 'confirmed'
    check (status in ('confirmed','accepted','preparing','ready','assigned','picked','out','delivered','cancelled')),
  price int not null check (price >= 0),
  address jsonb,
  pay text,
  created_at timestamptz not null default now()
);
alter table public.orders enable row level security;
create policy "order: customer reads own" on public.orders for select to authenticated using (customer_id = auth.uid());
create policy "order: customer places own" on public.orders for insert to authenticated
  with check (customer_id = auth.uid() and status = 'confirmed');
create policy "order: kitchen reads and moves" on public.orders for select to authenticated using (kitchen_id = public.my_kitchen());
create policy "order: kitchen updates status" on public.orders for update to authenticated
  using (kitchen_id = public.my_kitchen()) with check (kitchen_id = public.my_kitchen());
create policy "order: admin all" on public.orders for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------- payments (records only; no payment gateway yet) ----------
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id),
  what text not null,
  amount int not null check (amount >= 0),
  method text, state text not null default 'paid',
  created_at timestamptz not null default now()
);
alter table public.payments enable row level security;
create policy "payment: customer reads own" on public.payments for select to authenticated using (customer_id = auth.uid());
create policy "payment: customer records own" on public.payments for insert to authenticated with check (customer_id = auth.uid());
create policy "payment: admin reads" on public.payments for select to authenticated using (public.is_admin());

-- ---------- partner applications (kitchen / delivery) ----------
create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  applicant_id uuid not null references auth.users(id),
  type text not null check (type in ('kitchen','delivery')),
  form jsonb not null, docs jsonb not null default '{}'::jsonb,
  status text not null default 'submitted',
  history jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.applications enable row level security;
create policy "app: applicant reads own" on public.applications for select to authenticated using (applicant_id = auth.uid());
create policy "app: applicant submits" on public.applications for insert to authenticated
  with check (applicant_id = auth.uid() and status = 'submitted');
create policy "app: admin all" on public.applications for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Not included yet: delivery partners, chats, complaints, refunds, promos, notifications.
-- Known gap: order price and subscription price are sent by the app. A server function should recalculate them before real money is involved.
