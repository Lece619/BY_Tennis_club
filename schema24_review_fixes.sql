-- 24단계 (전체 검토 반영)
-- 1) 관리자·대표는 항상 게스트 아님: 관리자 코드·대표 인증·대표 넘기기 어떤 경로든 자동으로 게스트 해제
-- 2) is_approved() 에 대표 포함 (승인 대기 상태로 대표가 된 경우 대비)
-- 3) 참가자 '이름' 중복 규칙 삭제 (닉네임을 바꾼 회원의 옛 닉네임을 다른 회원이 쓰면 참가가 막히던 문제). 같은 사람 중복 참가는 user_id 규칙이 계속 막음
-- 4) 회비 입금 계좌는 게스트 제외 (승인된 회원·관리자·대표만)
-- schema23 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

create or replace function staff_not_guest() returns trigger
language plpgsql as $$
begin
  if new.role in ('admin', 'owner') then new.is_guest := false; end if;
  return new;
end $$;
drop trigger if exists zz_profiles_staff_not_guest on profiles;   -- 이름이 zz 라 역할 보호 트리거 다음에 실행됨
create trigger zz_profiles_staff_not_guest before insert or update on profiles
  for each row execute function staff_not_guest();
select set_config('app.claim_admin', 'on', false);
update profiles set is_guest = false where role in ('admin', 'owner') and is_guest;
select set_config('app.claim_admin', 'off', false);

create or replace function is_approved() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and (status = 'approved' or role in ('admin', 'owner')));
$$;

alter table participants drop constraint if exists participants_meetup_id_name_key;

drop policy if exists "settings read" on club_settings;
create policy "settings read" on club_settings for select using (key <> 'dues_account' or (is_approved() and not is_guest()));
