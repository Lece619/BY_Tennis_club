# BY 테니스 클럽 사이트

달력에서 정기 모임과 번개를 만들고, 참가 신청과 복식 대진표, 결과 기록까지 되는 한 장짜리 웹 페이지입니다.

## 구성
- `index.html` : 페이지 전체 (화면 + 동작). 상단 `CLUB_NAME` 에서 모임 이름을 바꿀 수 있습니다.
- `schema.sql` : Supabase 테이블 생성 SQL

## 처음 한 번 할 일
1. Supabase 대시보드 → 왼쪽 메뉴 **SQL Editor** → `schema.sql` 내용을 붙여넣고 **Run**
2. `index.html` 을 브라우저로 열어서 동작 확인

## 공개 주소로 올리기 (GitHub Pages)
1. GitHub 에서 새 저장소 생성 (예: `tennis`)
2. 이 폴더의 `index.html` 을 업로드
3. 저장소 Settings → Pages → Branch 를 `main` 으로 선택 → Save
4. 잠시 뒤 `https://아이디.github.io/tennis/` 로 접속

## 현재 버전의 한계
- 로그인이 없고 이름만 입력해서 씁니다. 같은 이름을 쓰면 같은 사람으로 취급됩니다.
- 누구나 모임을 만들고 지울 수 있습니다. 운영진 전용 권한은 다음 단계에서 로그인과 함께 추가합니다.
