# 나중에 할 최적화

지금 하지 않는다. 사용자 요청 또는 측정으로 필요해졌을 때만 연다.

살아있는 게임 코드는 약 10개 스크립트 / 4천 줄. 병목은 ECS나 폴더 트리가 아니라 `game.gd` 매프레임 `changed.emit`와 `main.gd` 전체 새로고침이다.

## 지금 상태 (2026-08-16 점검)

| 파일 | 줄 | 역할 |
|---|---:|---|
| `scripts/main.gd` | ~1400 | 화면 전부 코드로 생성 |
| `scripts/game.gd` | ~1400 | 마력+전투+세이브 한 오토로드 |
| `scripts/data.gd` | ~500 | 테이블 |
| `scripts/anomaly_view.gd` | ~450 | 이상체 드로우 + VFX |
| `scripts/stage_3d.gd` | ~320 | **미연결. 켜지 말 것** |
| 나머지 뷰 + `fmt.gd` | ~350 | 배경/코어/글리프/숫자 |

확인된 문제 (수정은 해당 Phase에서):

- `Game._process` 끝마다 `changed.emit()` → `_refresh()`가 RELICS/SPACE를 60fps로 만질 수 있음
- 숨긴 탭의 `*_view.gd`도 `_process` → `queue_redraw`
- 세이브에 `enemy_id`만 있고 전투 진행(integrity/parts/shell)은 없음. 로드 시 전선 재동기화
- Pulse/Shooter 별칭 (`pulse_cd`, `lv_pulse`, `fire_pulse`)
- Lance/Prism/Collapse와 후반 적 데이터는 `playable: false`인데 전투 코드/CD는 돌아감
- `Data.*()`가 호출마다 새 Dictionary 리터럴을 만듦
- ARCHIVE는 자식 `queue_free` 후 전부 재생성

## Phase 0 — 측정

405×720 창 또는 기기에서:

- CORE 대기 / ANOMALY 사격 / RELICS 탭 FPS
- `_refresh`가 카탈로그를 실제로 다시 만드는지
- `Data.enemies()` 등 매틱 할당

기존 `user://telemetry.json`으로 페이스를 본다. 프로파일러 프레임워크를 새로 넣지 않는다.

## Phase 1 — 삭제·정리 (동작 동일)

- `stage_3d.gd`는 연결하지 않는다. 에이전트 혼선이 크면 `unused/`로 옮기거나 삭제
- 손대는 김에만 Pulse 별칭 / `TAP_SEC` / `SHOOTER_CD` 제거. 단독 리팩터 금지
- `playable: false` 무기 CD는 언락 전에는 틱하지 않게

## Phase 2 — 싼 성능 (폴더 분할 없음)

- UI 미터는 dirty-flag 또는 10Hz. 뷰 `queue_redraw`는 연출이므로 유지
- `_layout_relics` / `_layout_space`는 목록이 바뀔 때만
- `Data` 테이블은 기동 시 한 번 캐시
- 숨긴 화면은 `PROCESS_MODE_DISABLED`
- 오브젝트 풀, 새 셰이더, 파티클 시스템은 프레임 타임이 가리킬 때만

## Phase 3 — `game.gd` 분할 (필요할 때만)

조건: 파일이 ~1800–2000줄을 넘고 세이브/전투 버그가 겹치거나, 사람이 둘 동시에 고칠 때.

해도 **오토로드는 Game 하나**. `save.gd` 또는 `combat_tick.gd` helper. 소유는 계속 gameplay. Core+Combat 두 오토로드 금지.

## Phase 4 — `main.gd` 화면 씬

조건: 화면별 `.tscn`을 실제로 만들 때. 그때 화면당 스크립트 하나. 빈 `ui/` 폴더부터 만들지 말 것.

## 하지 말 것

- ECS, DI, 이벤트 버스, 서비스 로케이터
- 측정 없이 `scripts/core/**` / `scripts/combat/**`
- `stage_3d` 연결
- 정리 목적만으로 `data.gd` → Resource 전환
- 프레스티지, 광고, 서버, 오프라인 보상, 처치 마스터리
