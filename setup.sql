-- Run this whole file once in Supabase: SQL Editor -> New query -> paste -> Run
-- CHANGE 'your-passcode-here' below to the passcode you will share with friends.

create table members (
  id uuid primary key,
  name text not null,
  created_at timestamptz default now()
);
create table messages (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid(),
  name text not null,
  body text,
  media_url text,
  media_type text,
  created_at timestamptz default now()
);
create table settings (id int primary key check (id = 1), pass text not null);
insert into settings values (1, 'ilovechess');

alter table members enable row level security;
alter table messages enable row level security;
alter table settings enable row level security;  -- no policies = nobody can read the passcode

create function is_member() returns boolean
language sql security definer stable set search_path = public
as $$ select exists (select 1 from members where id = auth.uid()) $$;

create policy "members read members" on members for select using (is_member());
create policy "members read messages" on messages for select using (is_member());
create policy "members send messages" on messages for insert with check (is_member() and user_id = auth.uid());
create policy "delete own messages" on messages for delete using (user_id = auth.uid());

-- Joining: checks passcode and the 5-person limit on the server
create function join_chat(p_pass text, p_name text) returns text
language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is null then return 'auth'; end if;
  if exists (select 1 from members where id = auth.uid()) then
    update members set name = p_name where id = auth.uid(); return 'ok';
  end if;
  if (select pass from settings where id = 1) is distinct from p_pass then return 'wrong'; end if;
  if (select count(*) from members) >= 5 then return 'full'; end if;
  insert into members (id, name) values (auth.uid(), p_name);
  return 'ok';
end $$;

-- Live updates
alter publication supabase_realtime add table messages, members;

-- Photo/video storage (25 MB per file)
insert into storage.buckets (id, name, public, file_size_limit) values ('media', 'media', true, 26214400);
create policy "members upload media" on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and public.is_member());
