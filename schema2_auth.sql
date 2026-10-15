-- 2단계: 카카오 로그인 + 운영진 권한
-- Supabase 대시보드 > SQL Editor 에 붙여넣고 Run 하세요. (schema.sql 을 먼저 실행한 상태여야 합니다)

-- 1) 회원 프로필 ---------------------------------------------------------
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  avatar_url text,
  role text not null default 'member' check (role in ('admin','member')),
  created_at timestamptz not null default now()
);

-- 가입(첫 로그인) 시 프로필 자동 생성. 첫 번째 회원은 자동으로 운영진.
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  nm text := coalesce(meta->>'name', meta->>'full_name', meta->>'preferred_username', meta->>'user_name', '회원');
  av text := coalesce(meta->>'avatar_url', meta->>'picture');
  first_user boolean := not exists (select 1 from profiles);
begin
  insert into profiles (id, name, avatar_url, role)
  values (new.id, nm, av, case when first_user then 'admin' else 'member' end)
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users for each row execute function handle_new_user();

-- 운영진 여부
create or replace function is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin');
$$;

-- 일반 회원이 자기 역할(role)을 바꾸지 못하게
create or replace function protect_role() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.role is distinct from old.role and not is_admin() then
    raise exception '운영진만 역할을 바꿀 수 있습니다';
  end if;
  return new;
end $$;
drop trigger if exists profiles_protect_role on profiles;
create trigger profiles_protect_role before update on profiles for each row execute function protect_role();

-- 2) 기존 테이블에 사용자 연결 컬럼 추가 ------------------------------------
alter table meetups      add column if not exists created_by_id uuid references auth.users(id) on delete set null;
alter table participants add column if not exists user_id uuid references auth.users(id) on delete cascade;
create unique index if not exists participants_meetup_user_idx on participants(meetup_id, user_id);

-- 3) 권한 규칙 (RLS) -------------------------------------------------------
alter table profiles enable row level security;

drop policy if exists "public all" on meetups;
drop policy if exists "public all" on participants;
drop policy if exists "public all" on matches;

-- profiles: 누구나 이름 조회, 본인만 수정(역할 변경은 트리거로 운영진만)
drop policy if exists "profiles read"   on profiles;
drop policy if exists "profiles update" on profiles;
create policy "profiles read"   on profiles for select using (true);
create policy "profiles update" on profiles for update
  using (id = auth.uid() or is_admin()) with check (id = auth.uid() or is_admin());

-- meetups: 누구나 조회, 로그인 회원이 생성, 만든 사람/운영진만 수정·삭제
drop policy if exists "meetups read"   on meetups;
drop policy if exists "meetups insert" on meetups;
drop policy if exists "meetups update" on meetups;
drop policy if exists "meetups delete" on meetups;
create policy "meetups read"   on meetups for select using (true);
create policy "meetups insert" on meetups for insert to authenticated with check (created_by_id = auth.uid());
create policy "meetups update" on meetups for update to authenticated
  using (created_by_id = auth.uid() or is_admin()) with check (created_by_id = auth.uid() or is_admin());
create policy "meetups delete" on meetups for delete to authenticated using (created_by_id = auth.uid() or is_admin());

-- participants: 누구나 조회, 본인 참가만 등록, 본인/모임 주최자/운영진이 취소
drop policy if exists "participants read"   on participants;
drop policy if exists "participants insert" on participants;
drop policy if exists "participants delete" on participants;
create policy "participants read"   on participants for select using (true);
create policy "participants insert" on participants for insert to authenticated with check (user_id = auth.uid());
create policy "participants delete" on participants for delete to authenticated using (
  user_id = auth.uid() or is_admin()
  or exists (select 1 from meetups m where m.id = participants.meetup_id and m.created_by_id = auth.uid())
);

-- matches: 누구나 조회, 모임 주최자/운영진만 생성·수정·삭제
drop policy if exists "matches read"  on matches;
drop policy if exists "matches write" on matches;
create policy "matches read"  on matches for select using (true);
create policy "matches write" on matches for all to authenticated
  using (is_admin() or exists (select 1 from meetups m where m.id = matches.meetup_id and m.created_by_id = auth.uid()))
  with check (is_admin() or exists (select 1 from meetups m where m.id = matches.meetup_id and m.created_by_id = auth.uid()));

-- 참고: 운영진을 수동으로 지정하려면
-- update profiles set role = 'admin' where name = '이름';
