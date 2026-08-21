# Mana Core

세로형 증분 게임 (Godot 4.7). Cyan → Violet 캠페인.

빛나는 인공 코어가 유물을 가동해 공간 침식체를 제거하고, 마력 위계를 올린다.

## 실행

Godot 4.7에서 이 폴더를 연다.

```
godot --path .
```

창은 1080×1920 비율(미리보기 405×720). 세로 고정.

## 플레이

기본 시작은 **CORE**.

- **CORE** — 탭·자동 생산, Output/Capacity, Tap/Auto 분기, 위계 합성
- **ANOMALY** — 전투만. 처음엔 UNKNOWN ENTITY. Cyan은 단발 사격, 연사는 RELICS 업그레이드
- **RELICS** — 사용형/패시브 장착·강화 (슬라이스: Shooter, 이후 Beam)
- **SPACE** — 선형 전선 (저궤도 → 대기권)
- **ARCHIVE** — 처치 기록. 보너스 없음

Violet 코어는 Cyan 보스 클리어와 별개다. Beam은 재구성체 공백 회복을 본 뒤 연속 방전으로 연다.

Flutter 프로토타입(`Documents/Lete/Incremental`)은 폐기 설계. 이 프로젝트를 기준으로 한다.
