-- 11단계: 대표(최고 관리자) 역할, 대표 코드 인증, 회원 삭제, 왕관 표시 설정
-- schema10 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
-- 실행 전에 아래 '대표 코드' 값을 원하는 것으로 바꾸세요. (앱의 관리 탭에서 대표가 나중에 바꿀 수도 있습니다)

-- 1) 역할: owner(대표) / admin(관리자) / member(회원)
alter table profiles drop constraint if exists profiles_role_check;
alter table profiles add constraint profiles_role_check check (role in ('owner','admin','member'));
alter table profiles add column if not exists show_crown boolean not null default true;

create or replace function is_owner() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'owner');
$$;
create or replace function is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role in ('admin','owner'));
$$;

-- 2) 대표 코드
insert into app_settings (key, value) values ('owner_code', 'by-owner-2026')   -- ← 대표 코드. 여기를 바꾸세요
on conflict (key) do nothing;

-- 3) 보호 규칙: 역할 변경은 대표만, 상태 변경은 관리자 이상 (인증 함수는 예외)
create or replace function protect_role() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if current_setting('app.claim_admin', true) = 'on' then return new; end if;
  if new.role is distinct from old.role and not is_owner() then
    raise exception '대표만 역할을 바꿀 수 있습니다';
  end if;
  if new.status is distinct from old.status and not is_admin() then
    raise exception '관리자만 바꿀 수 있습니다';
  end if;
  return new;
end $$;

-- 4) 관리자 코드 인증 (회원 → 관리자)
create or replace function claim_admin(code text) returns boolean
language plpgsql security definer set search_path = public as $$
declare ok boolean;
begin
  if auth.uid() is null then raise exception '로그인이 필요합니다'; end if;
  perform pg_sleep(1);
  select exists (select 1 from app_settings where key = 'admin_code' and value = code) into ok;
  if not ok then return false; end if;
  perform set_config('app.claim_admin', 'on', true);
  update profiles set role = 'admin', status = 'approved' where id = auth.uid() and role = 'member';
  perform set_config('app.claim_admin', 'off', true);
  return true;
end $$;

-- 5) 대표 코드 인증 (관리자 → 대표, 기존 대표는 관리자로)
create or replace function claim_owner(code text) returns boolean
language plpgsql security definer set search_path = public as $$
declare ok boolean;
begin
  if not is_admin() then raise exception '관리자만 대표 인증을 할 수 있습니다'; end if;
  perform pg_sleep(1);
  select exists (select 1 from app_settings where key = 'owner_code' and value = code) into ok;
  if not ok then return false; end if;
  perform set_config('app.claim_admin', 'on', true);
  update profiles set role = 'admin' where role = 'owner' and id <> auth.uid();
  update profiles set role = 'owner' where id = auth.uid();
  perform set_config('app.claim_admin', 'off', true);
  return true;
end $$;

-- 6) 대표 넘기기 (대표 → 관리자에게)
create or replace function transfer_owner(target uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_owner() then raise exception '대표만 넘길 수 있습니다'; end if;
  if not exists (select 1 from profiles where id = target and role = 'admin') then
    raise exception '관리자에게만 넘길 수 있습니다';
  end if;
  perform set_config('app.claim_admin', 'on', true);
  update profiles set role = 'admin' where id = auth.uid();
  update profiles set role = 'owner' where id = target;
  perform set_config('app.claim_admin', 'off', true);
end $$;

-- 7) 코드 변경: 대표만
create or replace function set_admin_code(new_code text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_owner() then raise exception '대표만 변경할 수 있습니다'; end if;
  if length(trim(new_code)) < 6 then raise exception '코드는 6자 이상이어야 합니다'; end if;
  insert into app_settings (key, value) values ('admin_code', trim(new_code))
  on conflict (key) do update set value = excluded.value;
end $$;
create or replace function set_owner_code(new_code text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_owner() then raise exception '대표만 변경할 수 있습니다'; end if;
  if length(trim(new_code)) < 6 then raise exception '코드는 6자 이상이어야 합니다'; end if;
  insert into app_settings (key, value) values ('owner_code', trim(new_code))
  on conflict (key) do update set value = excluded.value;
end $$;

-- 8) 회원 삭제 (계정까지 삭제). 관리자는 일반 회원·게스트만, 대표는 관리자도 삭제 가능. 대표와 본인은 삭제 불가
create or replace function delete_member(target uuid) returns void
language plpgsql security definer set search_path = public as $$
declare r text;
begin
  if not is_admin() then raise exception '관리자만 삭제할 수 있습니다'; end if;
  if target = auth.uid() then raise exception '본인은 삭제할 수 없습니다'; end if;
  select role into r from profiles where id = target;
  if r is null then return; end if;
  if r = 'owner' then raise exception '대표는 삭제할 수 없습니다'; end if;
  if r = 'admin' and not is_owner() then raise exception '관리자는 대표만 삭제할 수 있습니다'; end if;
  delete from auth.users where id = target;
end $$;

grant execute on function claim_owner(text), transfer_owner(uuid), set_owner_code(text), delete_member(uuid) to authenticated;
revoke execute on function claim_owner(text), transfer_owner(uuid), set_owner_code(text), delete_member(uuid) from anon;

-- 9) 첫 대표: 가장 먼저 가입한 카카오 회원 (대표가 아직 없을 때만)
--    보호 규칙(역할 변경은 대표만)을 잠시 풀고 실행
select set_config('app.claim_admin', 'on', false);
update profiles set role = 'owner', status = 'approved'
where id = (select id from profiles where not is_guest order by created_at limit 1)
  and not exists (select 1 from profiles where role = 'owner');
select set_config('app.claim_admin', 'off', false);
