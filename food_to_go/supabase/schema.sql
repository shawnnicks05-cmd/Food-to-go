create table if not exists public.food_stalls (
  id text primary key,
  name text not null,
  description text not null default '',
  image_url text not null default '',
  contact_phone text not null default '',
  contact_email text not null default '',
  like_count integer not null default 0 check (like_count >= 0),
  created_at timestamptz not null default now()
);

alter table public.food_stalls
  add column if not exists contact_phone text not null default '',
  add column if not exists contact_email text not null default '';

create table if not exists public.food_items (
  id text primary key default gen_random_uuid()::text,
  stall_id text not null references public.food_stalls(id) on delete cascade,
  name text not null,
  description text not null default '',
  image_url text not null default '',
  solo_price numeric(10, 2) not null check (solo_price > 0),
  meal_price numeric(10, 2) not null check (meal_price > 0),
  is_available boolean not null default true,
  order_count integer not null default 0 check (order_count >= 0),
  created_at timestamptz not null default now()
);

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'food-images',
  'food-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'profile-images',
  'profile-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create table if not exists public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  food_item_id text not null references public.food_items(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, food_item_id)
);

create table if not exists public.stall_likes (
  user_id uuid not null references auth.users(id) on delete cascade,
  stall_id text not null references public.food_stalls(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, stall_id)
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  payment_method text not null
    check (payment_method in ('Cash on Pickup', 'Pay at Stall')),
  status text not null default 'placed',
  total numeric(10, 2) not null check (total >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  food_item_id text not null,
  food_name text not null,
  purchase_type text not null check (purchase_type in ('solo', 'meal')),
  quantity integer not null check (quantity between 1 and 99),
  unit_price numeric(10, 2) not null check (unit_price > 0),
  created_at timestamptz not null default now()
);

-- Keep the stall on each order item so it still appears after menu edits.
alter table public.order_items add column if not exists stall_id text;

update public.order_items as item
set stall_id = food.stall_id
from public.food_items as food
where item.stall_id is null and food.id = item.food_item_id;

create table if not exists public.stall_orders (
  order_id uuid not null references public.orders(id) on delete cascade,
  stall_id text not null,
  status text not null default 'placed'
    check (status in ('placed', 'preparing', 'ready', 'completed')),
  primary key (order_id, stall_id)
);

alter table public.stall_orders enable row level security;
revoke all on public.stall_orders from anon, authenticated;

insert into public.stall_orders (order_id, stall_id, status)
select distinct i.order_id, i.stall_id,
  case when o.status in ('preparing', 'ready', 'completed') then o.status
    else 'placed' end
from public.order_items i
join public.orders o on o.id = i.order_id
where i.stall_id is not null
on conflict do nothing;

create index if not exists food_items_stall_id_idx
  on public.food_items (stall_id);
create index if not exists order_items_stall_id_idx
  on public.order_items (stall_id);
create index if not exists order_items_order_id_idx
  on public.order_items (order_id);
create index if not exists orders_user_id_created_at_idx
  on public.orders (user_id, created_at desc);

alter table public.food_stalls enable row level security;
alter table public.food_items enable row level security;
alter table public.favorites enable row level security;
alter table public.stall_likes enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

drop policy if exists "Authenticated users can read stalls"
  on public.food_stalls;
create policy "Authenticated users can read stalls"
  on public.food_stalls for select to authenticated
  using (true);

-- Existing duplicate assignments must be resolved before either account can edit.
create or replace function public.can_manage_storefront(p_stall_id text)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select count(*) = 1 and coalesce(bool_or(u.id = auth.uid()), false)
  from auth.users as u
  where u.raw_app_meta_data ->> 'account_type' = 'foodstall'
    and u.raw_app_meta_data ->> 'storefront_id' = p_stall_id;
$$;
revoke all on function public.can_manage_storefront(text) from public, anon;
grant execute on function public.can_manage_storefront(text) to authenticated;

drop policy if exists "Stall owners can update their storefront profile"
  on public.food_stalls;
create policy "Stall owners can update their storefront profile"
  on public.food_stalls for update to authenticated
  using (
    public.can_manage_storefront(id)
  )
  with check (
    public.can_manage_storefront(id)
  );

drop policy if exists "Authenticated users can read menu items"
  on public.food_items;
create policy "Authenticated users can read menu items"
  on public.food_items for select to authenticated
  using (true);

drop policy if exists "Stall owners can add menu items"
  on public.food_items;
create policy "Stall owners can add menu items"
  on public.food_items for insert to authenticated
  with check (
    public.can_manage_storefront(stall_id)
  );

drop policy if exists "Stall owners can update their menu items"
  on public.food_items;
create policy "Stall owners can update their menu items"
  on public.food_items for update to authenticated
  using (
    public.can_manage_storefront(stall_id)
  )
  with check (
    public.can_manage_storefront(stall_id)
  );

drop policy if exists "Stall owners can delete their menu items"
  on public.food_items;
create policy "Stall owners can delete their menu items"
  on public.food_items for delete to authenticated
  using (
    public.can_manage_storefront(stall_id)
  );

drop policy if exists "Users can read their favorites" on public.favorites;
create policy "Users can read their favorites"
  on public.favorites for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "Users can add their favorites" on public.favorites;
create policy "Users can add their favorites"
  on public.favorites for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "Users can remove their favorites" on public.favorites;
create policy "Users can remove their favorites"
  on public.favorites for delete to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "Users can read their stall likes" on public.stall_likes;
create policy "Users can read their stall likes"
  on public.stall_likes for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "Users can like stalls" on public.stall_likes;
create policy "Users can like stalls"
  on public.stall_likes for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "Users can unlike stalls" on public.stall_likes;
create policy "Users can unlike stalls"
  on public.stall_likes for delete to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "Users can read their orders" on public.orders;
create policy "Users can read their orders"
  on public.orders for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "Users can read items from their orders"
  on public.order_items;
create policy "Users can read items from their orders"
  on public.order_items for select to authenticated
  using (
    exists (
      select 1
      from public.orders
      where orders.id = order_items.order_id
        and orders.user_id = (select auth.uid())
    )
  );

revoke all on public.food_stalls, public.food_items, public.favorites,
  public.stall_likes, public.orders, public.order_items
  from anon, authenticated;

grant select on public.food_stalls, public.food_items to authenticated;
grant update (name, description, contact_phone, contact_email)
  on public.food_stalls to authenticated;
grant select, insert, delete on public.favorites to authenticated;
grant select, insert, delete on public.stall_likes to authenticated;
grant select on public.orders, public.order_items to authenticated;
grant insert (
  stall_id, name, description, image_url, solo_price, meal_price, is_available
) on public.food_items to authenticated;
grant update (name, description, image_url, solo_price, meal_price, is_available)
  on public.food_items to authenticated;
grant delete on public.food_items to authenticated;

create or replace function public.update_stall_like_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.food_stalls
      set like_count = like_count + 1
      where id = new.stall_id;
    return new;
  end if;

  update public.food_stalls
    set like_count = greatest(like_count - 1, 0)
    where id = old.stall_id;
  return old;
end;
$$;

drop trigger if exists stall_likes_update_count on public.stall_likes;
create trigger stall_likes_update_count
after insert or delete on public.stall_likes
for each row execute function public.update_stall_like_count();

create or replace function public.increment_food_order_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.food_items
    set order_count = order_count + new.quantity
    where id = new.food_item_id;
  return new;
end;
$$;

drop trigger if exists order_items_increment_count on public.order_items;
create trigger order_items_increment_count
after insert on public.order_items
for each row execute function public.increment_food_order_count();

create or replace function public.place_food_order(
  p_items jsonb,
  p_payment_method text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_order_id uuid;
  v_item jsonb;
  v_food public.food_items%rowtype;
  v_purchase_type text;
  v_quantity integer;
  v_unit_price numeric(10, 2);
  v_total numeric(10, 2) := 0;
  v_item_count integer := 0;
begin
  if v_user_id is null then
    raise exception 'Sign in before placing an order.';
  end if;

  if p_payment_method is null
    or p_payment_method not in ('Cash on Pickup', 'Pay at Stall') then
    raise exception 'Choose a supported payment method.';
  end if;

  if p_items is null
    or jsonb_typeof(p_items) is distinct from 'array'
    or jsonb_array_length(p_items) = 0 then
    raise exception 'Add items to your cart before placing an order.';
  end if;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    if coalesce(v_item ->> 'food_id', '') = '' then
      raise exception 'An order item is missing its food ID.';
    end if;

    v_purchase_type := v_item ->> 'purchase_type';
    if v_purchase_type is null
      or v_purchase_type not in ('solo', 'meal') then
      raise exception 'An order item has an invalid purchase type.';
    end if;

    begin
      v_quantity := (v_item ->> 'quantity')::integer;
    exception when invalid_text_representation then
      raise exception 'An order item has an invalid quantity.';
    end;

    if v_quantity is null or v_quantity < 1 or v_quantity > 99 then
      raise exception 'Order quantities must be between 1 and 99.';
    end if;

    select * into v_food
      from public.food_items
      where id = v_item ->> 'food_id'
      for share;

    if not found or not v_food.is_available then
      raise exception 'An item in your cart is no longer available.';
    end if;

    v_unit_price := case
      when v_purchase_type = 'meal' then v_food.meal_price
      else v_food.solo_price
    end;
    v_total := v_total + v_unit_price * v_quantity;
    v_item_count := v_item_count + v_quantity;
  end loop;

  insert into public.orders (user_id, payment_method, total)
    values (v_user_id, p_payment_method, v_total)
    returning id into v_order_id;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_purchase_type := v_item ->> 'purchase_type';
    v_quantity := (v_item ->> 'quantity')::integer;

    select * into v_food
      from public.food_items
      where id = v_item ->> 'food_id';

    v_unit_price := case
      when v_purchase_type = 'meal' then v_food.meal_price
      else v_food.solo_price
    end;

    insert into public.stall_orders (order_id, stall_id)
    values (v_order_id, v_food.stall_id)
    on conflict do nothing;

    insert into public.order_items (
      order_id, stall_id, food_item_id, food_name, purchase_type, quantity, unit_price
    )
    values (
      v_order_id, v_food.stall_id, v_food.id, v_food.name, v_purchase_type, v_quantity,
      v_unit_price
    );
  end loop;

  return jsonb_build_object(
    'order_id', v_order_id,
    'total', v_total,
    'item_count', v_item_count
  );
end;
$$;

revoke all on function public.update_stall_like_count() from public, anon,
  authenticated;
revoke all on function public.increment_food_order_count() from public, anon,
  authenticated;
revoke all on function public.place_food_order(jsonb, text) from public, anon;
grant execute on function public.place_food_order(jsonb, text) to authenticated;

create or replace function public.list_pending_food_stall_accounts()
returns table (user_id uuid, email text, created_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null
    or (auth.jwt() -> 'app_metadata' ->> 'account_type')
      is distinct from 'admin' then
    raise exception 'Administrator access is required.';
  end if;

  return query
    select u.id, u.email::text, u.created_at
    from auth.users as u
    left join public.food_stalls as s
      on s.id = u.raw_app_meta_data ->> 'storefront_id'
    where u.raw_user_meta_data ->> 'requested_account_type' = 'foodstall'
      and (
        u.raw_app_meta_data ->> 'account_type' is distinct from 'foodstall'
        or s.id is null
        or exists (
          select 1 from auth.users as other
          where other.id <> u.id
            and other.raw_app_meta_data ->> 'account_type' = 'foodstall'
            and other.raw_app_meta_data ->> 'storefront_id' = s.id
        )
      )
    order by u.created_at;
end;
$$;

create or replace function public.list_available_storefront_ids()
returns setof text
language sql stable security definer
set search_path = ''
as $$
  select s.id
  from public.food_stalls as s
  where auth.jwt() -> 'app_metadata' ->> 'account_type' = 'admin'
    and not exists (
      select 1 from auth.users as u
      where u.raw_app_meta_data ->> 'account_type' = 'foodstall'
        and u.raw_app_meta_data ->> 'storefront_id' = s.id
    );
$$;
revoke all on function public.list_available_storefront_ids() from public, anon;
grant execute on function public.list_available_storefront_ids() to authenticated;

create or replace function public.approve_food_stall_account(
  p_user_id uuid,
  p_stall_id text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null
    or (auth.jwt() -> 'app_metadata' ->> 'account_type')
      is distinct from 'admin' then
    raise exception 'Administrator access is required.';
  end if;

  perform 1 from public.food_stalls where id = p_stall_id for update;
  if not found then
    raise exception 'The selected storefront does not exist.';
  end if;

  if exists (
    select 1 from auth.users as u
    where u.id <> p_user_id
      and u.raw_app_meta_data ->> 'account_type' = 'foodstall'
      and u.raw_app_meta_data ->> 'storefront_id' = p_stall_id
  ) then
    raise exception 'This storefront is already assigned. Choose another storefront.';
  end if;

  update auth.users as target
    set raw_app_meta_data =
      coalesce(raw_app_meta_data, '{}'::jsonb) ||
      jsonb_build_object(
        'account_type', 'foodstall',
        'storefront_id', p_stall_id
      )
    where id = p_user_id
      and raw_user_meta_data ->> 'requested_account_type' = 'foodstall'
      and raw_app_meta_data ->> 'account_type' is distinct from 'admin'
      and (
        raw_app_meta_data ->> 'account_type' is distinct from 'foodstall'
        or not exists (
          select 1 from public.food_stalls as current_stall
          where current_stall.id = target.raw_app_meta_data ->> 'storefront_id'
            and not exists (
              select 1 from auth.users as other
              where other.id <> p_user_id
                and other.raw_app_meta_data ->> 'account_type' = 'foodstall'
                and other.raw_app_meta_data ->> 'storefront_id' = current_stall.id
            )
        )
      );

  if not found then
    raise exception 'The pending Food Stall account was not found.';
  end if;
end;
$$;

revoke all on function public.list_pending_food_stall_accounts()
  from public, anon, authenticated;
revoke all on function public.approve_food_stall_account(uuid, text)
  from public, anon, authenticated;
grant execute on function public.list_pending_food_stall_accounts()
  to authenticated;
grant execute on function public.approve_food_stall_account(uuid, text)
  to authenticated;

drop policy if exists "Stall owners can upload food images"
  on storage.objects;
create policy "Stall owners can upload food images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'food-images'
    and public.can_manage_storefront((storage.foldername(name))[1])
  );

drop policy if exists "Users can upload their profile photos"
  on storage.objects;
create policy "Users can upload their profile photos"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

notify pgrst, 'reload schema';

-- Customers see their whole order. Owners see only their own stall's items.
create or replace function public.list_pickup_orders(p_stall_id text default null)
returns table (
  order_id uuid, stall_name text, created_at timestamptz,
  payment_method text, status text, items jsonb
)
language sql stable security definer
set search_path = ''
as $$
  select o.id, coalesce(s.name, 'Storefront unavailable'), o.created_at,
    o.payment_method, coalesce(so.status, o.status),
    jsonb_agg(jsonb_build_object(
      'name', i.food_name, 'type', i.purchase_type,
      'quantity', i.quantity, 'subtotal', i.quantity * i.unit_price
    ) order by i.food_name, i.purchase_type)
  from public.orders o
  join public.order_items i on i.order_id = o.id
  left join public.stall_orders so on so.order_id = o.id and so.stall_id = i.stall_id
  left join public.food_stalls s on s.id = i.stall_id
  where (p_stall_id is null and o.user_id = auth.uid())
    or (i.stall_id = p_stall_id and public.can_manage_storefront(p_stall_id))
  group by o.id, i.stall_id, s.name, so.status
  order by o.created_at desc, o.id, i.stall_id;
$$;

create or replace function public.advance_pickup_order(
  p_order_id uuid, p_stall_id text, p_status text
)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if not public.can_manage_storefront(p_stall_id) then
    raise exception 'You can only update orders for your assigned storefront.';
  end if;

  update public.stall_orders
  set status = case p_status
    when 'placed' then 'preparing'
    when 'preparing' then 'ready'
    when 'ready' then 'completed'
  end
  where order_id = p_order_id and stall_id = p_stall_id
    and status = p_status and p_status in ('placed', 'preparing', 'ready');

  if not found then
    raise exception 'The order status changed. Refresh and try again.';
  end if;
end;
$$;

revoke all on function public.list_pickup_orders(text) from public, anon;
revoke all on function public.advance_pickup_order(uuid, text, text) from public, anon;
grant execute on function public.list_pickup_orders(text) to authenticated;
grant execute on function public.advance_pickup_order(uuid, text, text) to authenticated;
