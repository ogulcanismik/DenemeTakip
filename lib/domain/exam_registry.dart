import 'package:deneme_takip/domain/exam_type.dart';

abstract final class ExamRegistry {
  static const yksTyt = ExamType(
    id: 'yks_tyt',
    name: 'TYT',
    penaltyDivisor: 4,
    defaultTargetNet: 90,
    sections: [
      SectionDefinition(id: 'tr', name: 'Türkçe', questionCount: 40),
      SectionDefinition(id: 'sos', name: 'Sosyal Bilimler', questionCount: 20),
      SectionDefinition(id: 'mat', name: 'Temel Matematik', questionCount: 40),
      SectionDefinition(id: 'fen', name: 'Fen Bilimleri', questionCount: 20),
    ],
  );

  static const yksAytSay = ExamType(
    id: 'yks_ayt_say',
    name: 'AYT SAY',
    penaltyDivisor: 4,
    defaultTargetNet: 70,
    sections: [
      SectionDefinition(id: 'mat', name: 'Matematik', questionCount: 40),
      SectionDefinition(id: 'fiz', name: 'Fizik', questionCount: 14),
      SectionDefinition(id: 'kim', name: 'Kimya', questionCount: 13),
      SectionDefinition(id: 'biyo', name: 'Biyoloji', questionCount: 13),
    ],
  );

  static const yksAytEa = ExamType(
    id: 'yks_ayt_ea',
    name: 'AYT EA',
    penaltyDivisor: 4,
    defaultTargetNet: 65,
    sections: [
      SectionDefinition(id: 'mat', name: 'Matematik', questionCount: 40),
      SectionDefinition(
        id: 'edebiyat',
        name: 'Türk Dili ve Edebiyatı',
        questionCount: 24,
      ),
      SectionDefinition(id: 'tarih1', name: 'Tarih-1', questionCount: 10),
      SectionDefinition(id: 'cogr1', name: 'Coğrafya-1', questionCount: 6),
    ],
  );

  static const yksAytSoz = ExamType(
    id: 'yks_ayt_soz',
    name: 'AYT SÖZ',
    penaltyDivisor: 4,
    defaultTargetNet: 60,
    sections: [
      SectionDefinition(
        id: 'edebiyat',
        name: 'Türk Dili ve Edebiyatı',
        questionCount: 24,
      ),
      SectionDefinition(id: 'tarih1', name: 'Tarih-1', questionCount: 10),
      SectionDefinition(id: 'cogr1', name: 'Coğrafya-1', questionCount: 6),
      SectionDefinition(id: 'tarih2', name: 'Tarih-2', questionCount: 11),
      SectionDefinition(id: 'cogr2', name: 'Coğrafya-2', questionCount: 11),
      SectionDefinition(
        id: 'felsefe_grubu',
        name: 'Felsefe Grubu',
        questionCount: 12,
      ),
      SectionDefinition(
        id: 'din',
        name: 'Din Kültürü ve Ahlak Bilgisi',
        questionCount: 6,
      ),
    ],
  );

  static const yksYdt = ExamType(
    id: 'yks_ydt',
    name: 'YKS - YDT (Yabancı Dil)',
    penaltyDivisor: 4,
    defaultTargetNet: 70,
    sections: [
      SectionDefinition(id: 'dil', name: 'Yabancı Dil', questionCount: 80),
    ],
  );

  static const kpssLisans = ExamType(
    id: 'kpss_lisans',
    name: 'KPSS Lisans (GY-GK)',
    penaltyDivisor: 4,
    defaultTargetNet: 80,
    sections: [
      SectionDefinition(id: 'tr', name: 'Türkçe', questionCount: 30),
      SectionDefinition(id: 'mat', name: 'Matematik', questionCount: 30),
      SectionDefinition(id: 'tarih', name: 'Tarih', questionCount: 27),
      SectionDefinition(id: 'cogr', name: 'Coğrafya', questionCount: 18),
      SectionDefinition(id: 'vatandaslik', name: 'Vatandaşlık', questionCount: 9),
      SectionDefinition(id: 'guncel', name: 'Güncel Bilgiler', questionCount: 6),
    ],
  );

  static const kpssOnlisans = ExamType(
    id: 'kpss_onlisans',
    name: 'KPSS Ön Lisans',
    penaltyDivisor: 4,
    defaultTargetNet: 75,
    sections: [
      SectionDefinition(id: 'tr', name: 'Türkçe', questionCount: 30),
      SectionDefinition(id: 'mat', name: 'Matematik', questionCount: 30),
      SectionDefinition(id: 'tarih', name: 'Tarih', questionCount: 27),
      SectionDefinition(id: 'cogr', name: 'Coğrafya', questionCount: 18),
      SectionDefinition(id: 'vatandaslik', name: 'Vatandaşlık', questionCount: 9),
      SectionDefinition(id: 'guncel', name: 'Güncel Bilgiler', questionCount: 6),
    ],
  );

  static const kpssOrtaogretim = ExamType(
    id: 'kpss_ortaogretim',
    name: 'KPSS Ortaöğretim',
    penaltyDivisor: 4,
    defaultTargetNet: 70,
    sections: [
      SectionDefinition(id: 'tr', name: 'Türkçe', questionCount: 30),
      SectionDefinition(id: 'mat', name: 'Matematik', questionCount: 30),
      SectionDefinition(id: 'tarih', name: 'Tarih', questionCount: 27),
      SectionDefinition(id: 'cogr', name: 'Coğrafya', questionCount: 18),
      SectionDefinition(id: 'vatandaslik', name: 'Vatandaşlık', questionCount: 9),
      SectionDefinition(id: 'guncel', name: 'Güncel Bilgiler', questionCount: 6),
    ],
  );

  static const lgs = ExamType(
    id: 'lgs',
    name: 'LGS',
    penaltyDivisor: 3,
    defaultTargetNet: 75,
    sections: [
      SectionDefinition(id: 'tr', name: 'Türkçe', questionCount: 20),
      SectionDefinition(id: 'mat', name: 'Matematik', questionCount: 20),
      SectionDefinition(id: 'fen', name: 'Fen Bilimleri', questionCount: 20),
      SectionDefinition(
        id: 'ink',
        name: 'T.C. İnkılap Tarihi',
        questionCount: 10,
      ),
      SectionDefinition(id: 'din', name: 'Din Kültürü', questionCount: 10),
      SectionDefinition(id: 'dil', name: 'Yabancı Dil', questionCount: 10),
    ],
  );

  static const msu = ExamType(
    id: 'msu',
    name: 'MSÜ',
    penaltyDivisor: 4,
    defaultTargetNet: 90,
    sections: [
      SectionDefinition(id: 'tr', name: 'Türkçe', questionCount: 40),
      SectionDefinition(id: 'sos', name: 'Sosyal Bilimler', questionCount: 20),
      SectionDefinition(id: 'mat', name: 'Temel Matematik', questionCount: 40),
      SectionDefinition(id: 'fen', name: 'Fen Bilimleri', questionCount: 20),
    ],
  );

  static const ales = ExamType(
    id: 'ales',
    name: 'ALES',
    penaltyDivisor: 4,
    defaultTargetNet: 70,
    sections: [
      SectionDefinition(id: 'say', name: 'Sayısal', questionCount: 50),
      SectionDefinition(id: 'soz', name: 'Sözel', questionCount: 50),
    ],
  );

  static const dgs = ExamType(
    id: 'dgs',
    name: 'DGS',
    penaltyDivisor: 4,
    defaultTargetNet: 70,
    sections: [
      SectionDefinition(id: 'say', name: 'Sayısal', questionCount: 50),
      SectionDefinition(id: 'soz', name: 'Sözel', questionCount: 50),
    ],
  );

  static const hmgs = ExamType(
    id: 'hmgs',
    name: 'HMGS',
    penaltyDivisor: 0,
    defaultTargetNet: 70,
    sections: [
      SectionDefinition(id: 'anayasa', name: 'Anayasa Hukuku', questionCount: 6),
      SectionDefinition(
        id: 'anayasa_yargisi',
        name: 'Anayasa Yargısı',
        questionCount: 3,
      ),
      SectionDefinition(id: 'idare', name: 'İdare Hukuku', questionCount: 7),
      SectionDefinition(
        id: 'iyuk',
        name: 'İdari Yargılama Usulü',
        questionCount: 5,
      ),
      SectionDefinition(id: 'medeni', name: 'Medeni Hukuk', questionCount: 12),
      SectionDefinition(id: 'borclar', name: 'Borçlar Hukuku', questionCount: 10),
      SectionDefinition(id: 'ticaret', name: 'Ticaret Hukuku', questionCount: 10),
      SectionDefinition(
        id: 'hmk',
        name: 'Hukuk Yargılama Usulü',
        questionCount: 10,
      ),
      SectionDefinition(
        id: 'iik',
        name: 'İcra ve İflas Hukuku',
        questionCount: 8,
      ),
      SectionDefinition(id: 'ceza', name: 'Ceza Hukuku', questionCount: 10),
      SectionDefinition(
        id: 'cmk',
        name: 'Ceza Yargılama Usulü',
        questionCount: 7,
      ),
      SectionDefinition(id: 'is_hukuku', name: 'İş Hukuku', questionCount: 7),
      SectionDefinition(
        id: 'vergi',
        name: 'Vergi Hukuku ve Usulü',
        questionCount: 7,
      ),
      SectionDefinition(
        id: 'avukatlik',
        name: 'Avukatlık Hukuku',
        questionCount: 6,
      ),
      SectionDefinition(
        id: 'felsefe_sosyoloji',
        name: 'Hukuk Felsefesi ve Sosyolojisi',
        questionCount: 6,
      ),
      SectionDefinition(
        id: 'hukuk_tarihi',
        name: 'Türk Hukuk Tarihi',
        questionCount: 6,
      ),
      SectionDefinition(
        id: 'moformatted',
        name: 'Milletlerarası Hukuk ve MÖHUK',
        questionCount: 5,
      ),
    ],
  );

  static const builtins = <ExamType>[
    yksTyt,
    yksAytSay,
    yksAytEa,
    yksAytSoz,
    yksYdt,
    kpssLisans,
    kpssOnlisans,
    kpssOrtaogretim,
    lgs,
    msu,
    ales,
    dgs,
    hmgs,
  ];

  static List<ExamType> _customs = const [];

  /// Runtime overlay of user-defined exams (`custom_<id>`). Synced from
  /// [AppSettings.customExams] whenever settings are loaded or updated.
  static List<ExamType> get customs => _customs;

  /// Built-ins plus loaded custom exams.
  static List<ExamType> get all => [...builtins, ..._customs];

  static void setCustomExams(List<ExamType> exams) {
    final cleaned = <ExamType>[];
    final seen = <String>{};
    for (final exam in exams) {
      if (!exam.isCustom) continue;
      if (exam.id.isEmpty || !seen.add(exam.id)) continue;
      cleaned.add(exam);
    }
    _customs = List.unmodifiable(cleaned);
  }

  static bool isBuiltinId(String id) {
    for (final exam in builtins) {
      if (exam.id == id) return true;
    }
    return false;
  }

  static bool isCustomId(String id) => id.startsWith('custom_');

  static ExamType? byId(String id) {
    for (final exam in builtins) {
      if (exam.id == id) return exam;
    }
    for (final exam in _customs) {
      if (exam.id == id) return exam;
    }
    return null;
  }

  static List<ExamType> enabledOf(Iterable<String> ids) {
    final wanted = ids.toSet();
    return [for (final exam in all) if (wanted.contains(exam.id)) exam];
  }
}
