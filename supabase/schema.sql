-- Executar uma vez num projeto Supabase novo, no SQL Editor.
create extension if not exists pgcrypto;
create table public.profiles(id uuid primary key references auth.users(id) on delete cascade,display_name text not null check(length(trim(display_name)) between 1 and 80),role text not null check(role in ('candidate','owner')),created_at timestamptz not null default now());
create table public.private_contacts(user_id uuid primary key references auth.users(id) on delete cascade,email text not null check(length(trim(email)) between 3 and 254),phone text not null default '' check(length(phone)<=30));
create table public.candidate_profiles(id uuid primary key references public.profiles(id) on delete cascade,display_name text not null check(length(trim(display_name)) between 1 and 80),city text not null check(length(trim(city)) between 1 and 80),type text not null check(type in ('Quarto','Apartamento','Estúdio','Outro')),max_budget integer not null check(max_budget>0),description text not null default '' check(length(description)<=500),created_at timestamptz not null default now());
create table public.listings(id uuid primary key default gen_random_uuid(),owner_id uuid not null references public.profiles(id) on delete cascade,title text not null check(length(trim(title)) between 1 and 100),city text not null check(length(trim(city)) between 1 and 80),type text not null check(type in ('Quarto','Apartamento','Estúdio','Outro')),price integer not null check(price>0),description text not null default '' check(length(description)<=1000),active boolean not null default true,created_at timestamptz not null default now(),unique(id,owner_id));
create table public.proposals(id uuid primary key default gen_random_uuid(),listing_id uuid not null,owner_id uuid not null,candidate_id uuid not null references public.candidate_profiles(id) on delete cascade,status text not null default 'pending' check(status in ('pending','accepted','declined')),created_at timestamptz not null default now(),unique(listing_id,candidate_id),foreign key(listing_id,owner_id) references public.listings(id,owner_id) on delete cascade,check(owner_id<>candidate_id));
create index on public.proposals(candidate_id);create index on public.proposals(owner_id);
alter table public.profiles enable row level security;alter table public.private_contacts enable row level security;alter table public.candidate_profiles enable row level security;alter table public.listings enable row level security;alter table public.proposals enable row level security;
create policy self_read on public.profiles for select to authenticated using(id=(select auth.uid()));
create policy self_insert on public.profiles for insert to authenticated with check(id=(select auth.uid()));
create policy self_update on public.profiles for update to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
create policy self_read on public.private_contacts for select to authenticated using(user_id=(select auth.uid()));
create policy self_insert on public.private_contacts for insert to authenticated with check(user_id=(select auth.uid()));
create policy self_update on public.private_contacts for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy members_read on public.candidate_profiles for select to authenticated using(true);
create policy candidate_insert on public.candidate_profiles for insert to authenticated with check(id=(select auth.uid()) and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='candidate'));
create policy candidate_update on public.candidate_profiles for update to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()) and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='candidate'));
create policy public_read on public.listings for select to anon,authenticated using(active or owner_id=(select auth.uid()));
create policy owner_insert on public.listings for insert to authenticated with check(owner_id=(select auth.uid()) and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='owner'));
create policy owner_update on public.listings for update to authenticated using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()));
create policy participants_read on public.proposals for select to authenticated using(owner_id=(select auth.uid()) or candidate_id=(select auth.uid()));
create policy owner_propose on public.proposals for insert to authenticated with check(owner_id=(select auth.uid()) and status='pending' and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='owner') and exists(select 1 from public.listings l where l.id=listing_id and l.owner_id=(select auth.uid()) and l.active) and exists(select 1 from public.private_contacts c where c.user_id=(select auth.uid())));
-- Não existe política de update para propostas. Decisões passam só pela função.
create or replace function public.decide_proposal(p_id uuid,p_status text) returns void language plpgsql security definer set search_path='' as $$
begin
 if p_status not in ('accepted','declined') then raise exception 'Estado inválido'; end if;
 if p_status='accepted' and not exists(select 1 from public.private_contacts c where c.user_id=(select auth.uid())) then raise exception 'Guarda primeiro o teu contacto privado'; end if;
 update public.proposals set status=p_status where id=p_id and candidate_id=(select auth.uid()) and status='pending';
 if not found then raise exception 'Proposta indisponível'; end if;
end $$;
create or replace function public.proposal_contact(p_proposal_id uuid) returns table(email text,phone text) language plpgsql security definer set search_path='' as $$
begin
 return query select c.email,c.phone from public.proposals p join public.private_contacts c on c.user_id=case when p.candidate_id=(select auth.uid()) then p.owner_id else p.candidate_id end where p.id=p_proposal_id and ((p.candidate_id=(select auth.uid()) and p.status in ('pending','accepted')) or (p.owner_id=(select auth.uid()) and p.status='accepted'));
end $$;
revoke all on function public.decide_proposal(uuid,text) from public,anon;
revoke all on function public.proposal_contact(uuid) from public,anon;
grant execute on function public.decide_proposal(uuid,text) to authenticated;
grant execute on function public.proposal_contact(uuid) to authenticated;
