# Deneme Takip

Offline tracker for Turkish mock exams (deneme): YKS TYT, LGS, and KPSS Lisans. Enter doğru and yanlış; boş and net are calculated. Records stay on the device in Hive. The interface is Turkish.

## Run

```bash
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 43123
```

Open http://localhost:43123.

## Net

`net = correct − (incorrect / penalty divisor)`

- YKS TYT and KPSS Lisans: divisor 4
- LGS: divisor 3

`empty = questionCount − correct − incorrect`

`totalNet = sum of section nets`

Intermediate values are not rounded. The UI shows at most 2 decimal places, uses a Turkish decimal comma, and trims trailing zeros.

## Test

```bash
flutter test test/net_engine_test.dart
```
