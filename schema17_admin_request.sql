-- 17단계: 자유 모임은 생성자가 왕
--   · 자유 모임: 수정·참가 승인·거절·대진표·점수는 만든 사람만. 관리자는 삭제만 가능(안전장치)
--   · 정기 모임: 만든 사람과 관리자가 관리
--   · 신청 후 승인 모임은 관리자·대표도 신청으로 들어감 (주최자만 바로 참가). 자기 신청은 스스로 승인 불가
-- schema16 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

-- 주최자 여부 / 관리 권한 (정기 모임은 관리자도)
create or replace function is_host(mid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from meetups where id = mid and created_by_id = auth.uid());
$$;
create or replace function can_manage(mid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from meetups where id = mid
      and (created_by_id = auth.uid() or (kind = 'regular' and is_admin()))
  );
$$;

-- 참가 등록 상태
create or replace function set_participant_status() returns trigger
language plpgsql security definer set search_path = public as $$
declare mode text; host uuid;
begin
  select join_mode, created_by_id into mode, host from meetups where id = new.meetup_id;
  if host = auth.uid() then
    new.status := 'approved';
  elsif is_guest() or mode = 'approve' then
    new.status := 'pending';
  else
    new.status := 'approved';
  end if;
  return new;
end $$;

-- 모임 수정: 주최자, 정기 모임은 관리자도
drop policy if exists "meetups update" on meetups;
create policy "meetups update" on meetups for update to authenticated
  using (can_manage(id))
  with check (can_manage(id) and (kind <> 'regular' or is_admin()));

-- 모임 삭제: 주최자 또는 관리자 (안전장치)
drop policy if exists "meetups delete" on meetups;
create policy "meetups delete" on meetups for delete to authenticated
  using (created_by_id = auth.uid() or is_admin());

-- 참가 승인: 관리 권한자, 단 자기 자신은 불가
drop policy if exists "participants update" on participants;
create policy "participants update" on participants for update to authenticated
  using (can_manage(meetup_id) and user_id <> auth.uid())
  with check (can_manage(meetup_id) and user_id <> auth.uid());

-- 참가 취소/거절: 본인, 또는 관리 권한자
drop policy if exists "participants delete" on participants;
create policy "participants delete" on participants for delete to authenticated
  using (user_id = auth.uid() or can_manage(meetup_id));

-- 대진표·점수: 관리 권한자만
drop policy if exists "matches write" on matches;
create policy "matches write" on matches for all to authenticated
  using (can_manage(meetup_id)) with check (can_manage(meetup_id));
