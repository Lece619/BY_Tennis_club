-- 12단계: 모든 신규 가입은 게스트로 시작 (카카오 포함). 관리자가 회원으로 올림.
-- schema11 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

-- 가입 트리거: 로그인 방법과 상관없이 게스트
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  nm text := coalesce(meta->>'name', meta->>'full_name', meta->>'preferred_username', meta->>'user_name', '회원');
  av text := replace(coalesce(meta->>'avatar_url', meta->>'picture', ''), 'http://', 'https://');
begin
  insert into profiles (id, name, avatar_url, role, is_guest)
  values (new.id, unique_name(nm), nullif(av, ''), 'member', true)
  on conflict (id) do nothing;
  if meta->>'phone' is not null then
    insert into profile_private (id, phone) values (new.id, meta->>'phone')
    on conflict (id) do update set phone = excluded.phone;
  end if;
  return new;
end $$;

-- 보호 규칙: 역할은 대표만, 상태·게스트 여부는 관리자 이상
create or replace function protect_role() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if current_setting('app.claim_admin', true) = 'on' then return new; end if;
  if new.role is distinct from old.role and not is_owner() then
    raise exception '대표만 역할을 바꿀 수 있습니다';
  end if;
  if (new.status is distinct from old.status or new.is_guest is distinct from old.is_guest) and not is_admin() then
    raise exception '관리자만 바꿀 수 있습니다';
  end if;
  return new;
end $$;

-- 관리자·대표는 게스트일 수 없음
update profiles set is_guest = false where role in ('admin','owner');
