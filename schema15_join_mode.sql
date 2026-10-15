-- 15단계: 모임별 참가 방식 (자동 승인 / 신청 후 승인)
-- schema14 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

alter table meetups add column if not exists join_mode text not null default 'auto'
  check (join_mode in ('auto','approve'));
alter table participants add column if not exists status text not null default 'approved'
  check (status in ('approved','pending'));

-- 참가 등록 시: 신청 후 승인 모임이면 '대기', 주최자·관리자 본인은 바로 승인
create or replace function set_participant_status() returns trigger
language plpgsql security definer set search_path = public as $$
declare mode text; host uuid;
begin
  select join_mode, created_by_id into mode, host from meetups where id = new.meetup_id;
  if mode = 'approve' and not (is_admin() or host = auth.uid()) then
    new.status := 'pending';
  else
    new.status := 'approved';
  end if;
  return new;
end $$;
drop trigger if exists participants_set_status on participants;
create trigger participants_set_status before insert on participants
  for each row execute function set_participant_status();

-- 참가 승인(상태 변경): 주최자·관리자만
drop policy if exists "participants update" on participants;
create policy "participants update" on participants for update to authenticated
  using (is_admin() or exists (select 1 from meetups m where m.id = participants.meetup_id and m.created_by_id = auth.uid()))
  with check (is_admin() or exists (select 1 from meetups m where m.id = participants.meetup_id and m.created_by_id = auth.uid()));
