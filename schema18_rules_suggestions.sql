-- 18단계: 회칙(관리자 수정 가능) + 건의사항
-- schema17 까지 실행한 뒤 Supabase > SQL Editor 에서 Run 하세요.

-- 건의사항
create table if not exists suggestions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete set null,
  name text,
  content text not null,
  status text not null default 'open' check (status in ('open','done')),
  created_at timestamptz not null default now()
);
alter table suggestions enable row level security;
drop policy if exists "sug insert" on suggestions;
drop policy if exists "sug read"   on suggestions;
drop policy if exists "sug update" on suggestions;
drop policy if exists "sug delete" on suggestions;
create policy "sug insert" on suggestions for insert to authenticated with check (user_id = auth.uid() and is_approved());
create policy "sug read"   on suggestions for select to authenticated using (user_id = auth.uid() or is_admin());
create policy "sug update" on suggestions for update to authenticated using (is_admin()) with check (is_admin());
create policy "sug delete" on suggestions for delete to authenticated using (is_admin() or user_id = auth.uid());

-- 회칙 본문 (club_settings 에 저장, 관리자가 앱에서 수정)
insert into club_settings (key, value) values ('rules', $rules$
제1장 총칙
• 제1조 (명칭): 본 클럽은 'BY 테니스 클럽 (1기)'(이하 비테원)이라 칭한다.
• 제2조 (목적): 비테원은 회원 간의 테니스 실력 향상과 친목 도모, 건강 증진을 목적으로 한다.

제2장 회원 및 자격
• 제3조 (회원 자격):
◦ BY 테니스장에서 레슨을 받고 있는 회원에 한함
◦ 게임이 가능한 회원
• 제4조 (회원의 의무 및 권리):
◦ 회원은 회칙을 준수하고 회비 납부 및 모임 참석 의무를 가진다.
◦ 회원은 비테원이 주관하는 모든 모임과 행사에 참여할 권리를 가진다.
• 제5조 (탈퇴 및 제명):
◦ 회원은 임원진에게 의사를 전달하고 자진 탈퇴할 수 있다.
◦ 회원이 레슨을 그만두게 되는 경우, 그 달까지만 회원 자격을 유지할 수 있다.
◦ 회원이 탈퇴를 하게 되어도 회비의 환불은 불가능하다.
◦ 다음 각 호에 해당하는 경우 임원진 회의를 거쳐 제명할 수 있다.
▪ 정당한 사유 없이 3개월 이상 모임 불참
▪ 회비 미납 2회 이상 경과
▪ 과도한 승부욕 또는 감정적인 플레이로 인해 회원 간의 분위기를 해치거나 비테원의 명예를 훼손한 경우

제3장 임원 및 조직
• 제6조 (임원 구성):
◦ 회장 (1명): 비테원을 대표하고 총괄 운영
◦ 총무 (1명): 회계 및 행정 업무 전반 담당
◦ 경기이사 (1명): 모임 경기 대진표 작성 및 규칙 관리

제4장 모임 및 운영
• 제7조 (모임):
◦ 모임은 매월 첫째 주 토요일에 진행한다. (일정 변경 시 사전 공지)
◦ 모임의 게임 배정은 경기 이사나 총무가 주관한다.
• 제8조 (매너 규칙):
◦ 코트 진입 전후 상호 간에 예의를 갖추고 인사한다.
◦ 판정(아웃/인)은 상대방 코트의 의견을 존중하는 테니스 에티켓을 준수한다.
◦ 레슨 회원 클럽 특성상 회원 간 과도한 지적은 지양하고 격려를 우선으로 한다.

제5장 회계 및 회비
• 제9조 (회비):
◦ 입회비: 추후 결정
◦ 월 회비: 매월 1일까지 납부
◦ 회비는 코트 대여료, 음료/공용 용품 구입, 행사 운영비 등으로 사용한다.

제6장 기타
• 회원들의 건의 사항이나 불만 사항은 총무를 통해 언제든지 건의할 수 있다.
$rules$) on conflict (key) do nothing;
