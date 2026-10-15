-- 13단계: 전화번호로 중복 가입 방지
--   카카오 가입자도 프로필에서 전화번호를 등록. 번호는 계정당 하나, 중복 불가.
-- schema12 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

-- 번호 고유 규칙
create unique index if not exists profile_private_phone_idx on profile_private (phone) where phone is not null;

-- 본인 번호 등록·수정 허용 (조회는 본인·관리자만, 기존 규칙 유지)
drop policy if exists "private insert" on profile_private;
drop policy if exists "private update" on profile_private;
create policy "private insert" on profile_private for insert to authenticated with check (id = auth.uid());
create policy "private update" on profile_private for update to authenticated
  using (id = auth.uid() or is_admin()) with check (id = auth.uid() or is_admin());

-- 번호가 이미 등록돼 있는지 (어떤 방식으로 가입했는지만 알려 줌)
--   반환: 'kakao' | 'phone' | null
create or replace function phone_taken(p text, self uuid default null) returns text
language plpgsql stable security definer set search_path = public as $$
declare r text;
begin
  select case when u.email like 'guest-%@guest.bytennis.app' then 'phone' else 'kakao' end
    into r
  from profile_private pp join auth.users u on u.id = pp.id
  where pp.phone = p and (self is null or pp.id <> self)
  limit 1;
  return r;
end $$;
grant execute on function phone_taken(text, uuid) to anon, authenticated;
