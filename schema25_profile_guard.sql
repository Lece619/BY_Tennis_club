-- 25단계: 프로필 수정 권한을 화면 규칙과 같게
-- 1) 관리자·대표의 상태(휴식 등)는 대표만 바꿀 수 있음
-- 2) 남의 닉네임·구력·성별·생년·사진·별 표시는 대표만 바꿀 수 있음 (본인 것은 자유)
-- (관리자는 지금처럼 회원·게스트의 승인/휴식, 회원↔게스트 전환 가능)
-- schema24 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.
create or replace function protect_role() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if current_setting('app.claim_admin', true) = 'on' then return new; end if;   -- 관리자 코드 인증 등 서버 함수
  if new.role is distinct from old.role and not is_owner() then
    raise exception '대표만 역할을 바꿀 수 있습니다';
  end if;
  if (new.status is distinct from old.status or new.is_guest is distinct from old.is_guest) and not is_admin() then
    raise exception '관리자만 바꿀 수 있습니다';
  end if;
  if new.status is distinct from old.status and old.role in ('admin', 'owner') and not is_owner() then
    raise exception '관리자의 상태는 대표만 바꿀 수 있습니다';
  end if;
  if old.id <> auth.uid() and not is_owner() and (
       new.name is distinct from old.name or new.experience is distinct from old.experience
    or new.gender is distinct from old.gender or new.birth_year is distinct from old.birth_year
    or new.avatar_url is distinct from old.avatar_url or new.show_crown is distinct from old.show_crown) then
    raise exception '다른 회원의 프로필은 바꿀 수 없습니다';
  end if;
  return new;
end $$;
