-- Shelf database setup. Paste this into Supabase → SQL Editor → Run.

create table if not exists public.books (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title       text not null check (char_length(title) between 1 and 300),
  author      text default '',
  finished_on date,
  rating      smallint check (rating between 1 and 5),
  notes       text default '',
  created_at  timestamptz not null default now()
);

create index if not exists books_user_idx on public.books (user_id, finished_on desc);

-- Row-level security: each person can only see and change their own books.
alter table public.books enable row level security;

drop policy if exists "Read own books"   on public.books;
drop policy if exists "Add own books"    on public.books;
drop policy if exists "Edit own books"   on public.books;
drop policy if exists "Delete own books" on public.books;

create policy "Read own books"   on public.books for select using (auth.uid() = user_id);
create policy "Add own books"    on public.books for insert with check (auth.uid() = user_id);
create policy "Edit own books"   on public.books for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Delete own books" on public.books for delete using (auth.uid() = user_id);

-- Added Nov 2026: page counts and the exact cover picked from suggestions.
-- Safe to run more than once.
alter table public.books add column if not exists pages integer check (pages between 1 and 20000);
alter table public.books add column if not exists cover_url text check (cover_url is null or cover_url like 'https://covers.openlibrary.org/%');
notify pgrst, 'reload schema';

-- Added Nov 2026: usernames, so an email is optional.
-- Accounts without an email get a placeholder login address <username>@shelf.invalid
-- (the .invalid domain can never receive mail). Safe to run more than once.
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  username   text unique not null check (username ~ '^[a-z0-9_.]{3,24}$'),
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
drop policy if exists "Read own profile" on public.profiles;
create policy "Read own profile" on public.profiles for select using (auth.uid() = id);

-- Save the username when an account is created.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.raw_user_meta_data ->> 'username' is not null then
    insert into public.profiles (id, username) values (new.id, lower(new.raw_user_meta_data ->> 'username'));
  end if;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Is a username free? (used on the sign-up screen)
create or replace function public.username_available(name text) returns boolean
language sql security definer stable set search_path = public as $$
  select not exists (select 1 from public.profiles where username = lower(name));
$$;

-- Sign in with a username: returns that account's login email, but only when the password is right,
-- so nobody can look up someone else's email from their username.
create or replace function public.login_email(name text, pass text) returns text
language plpgsql security definer set search_path = public, extensions as $$
declare e text; h text;
begin
  select u.email, u.encrypted_password into e, h
    from auth.users u join public.profiles p on p.id = u.id
   where p.username = lower(name);
  if h is null or extensions.crypt(pass, h) <> h then
    perform pg_sleep(0.4);   -- slow down password guessing
    return null;
  end if;
  return e;
end $$;

revoke all on function public.username_available(text) from public;
revoke all on function public.login_email(text, text) from public;
grant execute on function public.username_available(text) to anon, authenticated;
grant execute on function public.login_email(text, text) to anon, authenticated;
notify pgrst, 'reload schema';
