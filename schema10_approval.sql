-- 10단계: 회원 승인 — 새로 가입한 계정은 '승인 대기', 관리자가 승인해야 참가·모임 생성 가능
-- schema9 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

alter table profiles add column if not exists status text not null default 'pending'
  check (status in ('pending','approved','blocked'));

-- 지금까지 가입한 회원은 전원 승인 처리
update profiles set status = 'approved' where status = 'pending';

-- 승인된 회원(또는 관리자)인지
create or replace function is_approved() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and (status = 'approved' or role = 'admin'));
$$;

-- 일반 회원이 자기 역할/상태를 바꾸지 못하게 (관리자 코드 인증 함수는 예외)
create or replace function protect_role() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if current_setting('app.claim_admin', true) = 'on' then
    return new;
  end if;
  if (new.role is distinct from old.role or new.status is distinct from old.status) and not is_admin() then
    raise exception '관리자만 바꿀 수 있습니다';
  end if;
  return new;
end $$;

-- 관리자 코드 인증: 보호 규칙을 잠시 풀고 역할 변경 (버그 수정)
create or replace function claim_admin(code text) returns boolean
language plpgsql security definer set search_path = public as $$
declare ok boolean;
begin
  if auth.uid() is null then raise exception '로그인이 필요합니다'; end if;
  perform pg_sleep(1);
  select exists (select 1 from app_settings where key = 'admin_code' and value = code) into ok;
  if not ok then return false; end if;
  perform set_config('app.claim_admin', 'on', true);
  update profiles set role = 'admin', status = 'approved' where id = auth.uid();
  perform set_config('app.claim_admin', 'off', true);
  return true;
end $$;

-- 모임 생성: 승인된 회원만 (+ 기존 규칙 유지)
drop policy if exists "meetups insert" on meetups;
create policy "meetups insert" on meetups for insert to authenticated
  with check (
    created_by_id = auth.uid()
    and is_approved()
    and not is_guest()
    and (kind <> 'regular' or is_admin())
  );

-- 참가 신청: 승인된 회원만
drop policy if exists "participants insert" on participants;
create policy "participants insert" on participants for insert to authenticated
  with check (user_id = auth.uid() and is_approved());
