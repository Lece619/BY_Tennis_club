-- 16단계: 게스트는 모임 설정과 상관없이 항상 '신청'으로 들어감 (주최자·관리자 승인 필요)
-- schema15 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

create or replace function set_participant_status() returns trigger
language plpgsql security definer set search_path = public as $$
declare mode text; host uuid;
begin
  select join_mode, created_by_id into mode, host from meetups where id = new.meetup_id;
  if is_admin() or host = auth.uid() then
    new.status := 'approved';                       -- 주최자·관리자는 바로 참가
  elsif is_guest() or mode = 'approve' then
    new.status := 'pending';                        -- 게스트는 항상 신청, 회원은 모임 설정에 따라
  else
    new.status := 'approved';
  end if;
  return new;
end $$;
