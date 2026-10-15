-- 3단계: 운영진 코드 방식
-- schema2_auth.sql 을 실행한 뒤에 Supabase > SQL Editor 에서 Run 하세요.
-- 실행 전에 아래 '운영진 코드' 값을 원하는 것으로 바꾸세요. (앱에서 운영진이 나중에 변경할 수도 있습니다)

-- 1) 첫 로그인 자동 운영진 제거: 모든 신규 회원은 일반 회원
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  nm text := coalesce(meta->>'name', meta->>'full_name', meta->>'preferred_username', meta->>'user_name', '회원');
  av text := coalesce(meta->>'avatar_url', meta->>'picture');
begin
  insert into profiles (id, name, avatar_url, role)
  values (new.id, nm, av, 'member')
  on conflict (id) do nothing;
  return new;
end $$;

-- 2) 비공개 설정 테이블 (RLS 켜고 정책 없음 = 앱에서 직접 읽을 수 없음)
create table if not exists app_settings (
  key text primary key,
  value text not null
);
alter table app_settings enable row level security;

insert into app_settings (key, value) values ('admin_code', 'by-tennis-2026')   -- ← 운영진 코드. 여기를 바꾸세요
on conflict (key) do nothing;

-- 3) 운영진 코드 입력 → 본인을 운영진으로
create or replace function claim_admin(code text) returns boolean
language plpgsql security definer set search_path = public as $$
declare ok boolean;
begin
  if auth.uid() is null then raise exception '로그인이 필요합니다'; end if;
  perform pg_sleep(1);   -- 무차별 대입 속도 제한
  select exists (select 1 from app_settings where key = 'admin_code' and value = code) into ok;
  if not ok then return false; end if;
  update profiles set role = 'admin' where id = auth.uid();
  return true;
end $$;

-- 4) 운영진이 코드 변경
create or replace function set_admin_code(new_code text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception '운영진만 변경할 수 있습니다'; end if;
  if length(trim(new_code)) < 6 then raise exception '코드는 6자 이상이어야 합니다'; end if;
  insert into app_settings (key, value) values ('admin_code', trim(new_code))
  on conflict (key) do update set value = excluded.value;
end $$;

grant execute on function claim_admin(text) to authenticated;
grant execute on function set_admin_code(text) to authenticated;
revoke execute on function claim_admin(text) from anon;
revoke execute on function set_admin_code(text) from anon;
