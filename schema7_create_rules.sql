-- 7단계: 모임 생성 규칙
--   정기 모임: 관리자만 / 자유 모임: 게스트를 제외한 회원
-- schema6 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

create or replace function is_guest() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select is_guest from profiles where id = auth.uid()), false);
$$;

drop policy if exists "meetups insert" on meetups;
create policy "meetups insert" on meetups for insert to authenticated
  with check (
    created_by_id = auth.uid()
    and not is_guest()
    and (kind <> 'regular' or is_admin())
  );

drop policy if exists "meetups update" on meetups;
create policy "meetups update" on meetups for update to authenticated
  using (created_by_id = auth.uid() or is_admin())
  with check ((created_by_id = auth.uid() or is_admin()) and (kind <> 'regular' or is_admin()));
