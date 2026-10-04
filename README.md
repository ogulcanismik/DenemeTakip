# Deneme Takip

Offline tracker for Turkish mock exams (deneme): YKS (TYT / AYT / YDT), KPSS, LGS, MSÜ, ALES, DGS, and HMGS. On first launch you multi-select which exams you use; the top switcher only lists those. Enter doğru and yanlış; boş and net are calculated. Records stay on the device in Hive. The interface is Turkish.

## Run

```bash
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 43123
```

Open http://localhost:43123.

## Net

- If `penaltyDivisor == 0` (HMGS): `net = correct` (no wrong penalty)
- Otherwise: `net = correct − (incorrect / penaltyDivisor)`
- YKS / KPSS / MSÜ / ALES / DGS: divisor 4
- LGS: divisor 3

`empty = questionCount − correct − incorrect`

`totalNet = sum of section nets`

Intermediate values are not rounded. The UI shows at most 2 decimal places, uses a Turkish decimal comma, and trims trailing zeros.

## Test

```bash
flutter test test/net_engine_test.dart
```
