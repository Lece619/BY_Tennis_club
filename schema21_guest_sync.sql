-- 21단계: 전화번호 계정의 로그인 정보 동기화
--   닉네임이나 전화번호를 바꾸면 "현재 닉네임 + 현재 번호"로 로그인되도록 서버가 로그인 정보를 함께 갱신
-- schema20 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

create or replace function sync_guest_credentials(uid uuid) returns void
language plpgsql security definer set search_path = public, extensions as $$
declare nm text; ph text; em text; pw text; new_em text;
begin
  select p.name, pp.phone into nm, ph from profiles p left join profile_private pp on pp.id = p.id where p.id = uid;
  if nm is null or ph is null then return; end if;
  select email into em from auth.users where id = uid;
  if em is null or em not like 'guest-%@guest.bytennis.app' then return; end if;   -- 전화번호 계정만
  new_em := 'guest-' || ph || '@guest.bytennis.app';
  pw := encode(extensions.digest(ph || ':' || regexp_replace(nm, '\s', '', 'g') || ':BY-TENNIS', 'sha256'), 'hex');
  update auth.users
     set email = new_em,
         encrypted_password = extensions.crypt(pw, extensions.gen_salt('bf')),
         updated_at = now()
   where id = uid;
  update auth.identities
     set identity_data = jsonb_set(coalesce(identity_data, '{}'::jsonb), '{email}', to_jsonb(new_em)),
         updated_at = now()
   where user_id = uid and provider = 'email';
end $$;

-- 닉네임 변경 시
create or replace function trg_sync_on_profile() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' or new.name is distinct from old.name then perform sync_guest_credentials(new.id); end if;
  return new;
end $$;
drop trigger if exists profiles_sync_guest on profiles;
create trigger profiles_sync_guest after insert or update of name on profiles
  for each row execute function trg_sync_on_profile();

-- 전화번호 변경 시
create or replace function trg_sync_on_phone() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform sync_guest_credentials(new.id);
  return new;
end $$;
drop trigger if exists private_sync_guest on profile_private;
create trigger private_sync_guest after insert or update of phone on profile_private
  for each row execute function trg_sync_on_phone();

-- 기존 전화번호 계정 전부 현재 값 기준으로 맞춤
do $$
declare r record;
begin
  for r in select id from profiles loop perform sync_guest_credentials(r.id); end loop;
end $$;
