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
