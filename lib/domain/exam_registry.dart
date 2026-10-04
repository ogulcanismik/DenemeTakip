import 'package:deneme_takip/domain/exam_type.dart';

abstract final class ExamRegistry {
  static const yksTyt = ExamType(
    id: 'yks-tyt',
    name: 'YKS · TYT',
    penaltyDivisor: 4,
    defaultTargetNet: 90,
    sections: [
      SectionDefinition(id: 'turkce', name: 'Türkçe', questionCount: 40),
      SectionDefinition(
        id: 'sosyal',
        name: 'Sosyal Bilimler',
        questionCount: 20,
      ),
      SectionDefinition(
        id: 'matematik',
        name: 'Temel Matematik',
        questionCount: 40,
      ),
      SectionDefinition(id: 'fen', name: 'Fen Bilimleri', questionCount: 20),
    ],
  );

  static const lgs = ExamType(
    id: 'lgs',
    name: 'LGS',
    penaltyDivisor: 3,
    defaultTargetNet: 75,
    sections: [
      SectionDefinition(id: 'turkce', name: 'Türkçe', questionCount: 20),
      SectionDefinition(id: 'matematik', name: 'Matematik', questionCount: 20),
      SectionDefinition(id: 'fen', name: 'Fen Bilimleri', questionCount: 20),
      SectionDefinition(
        id: 'inkilap',
        name: 'T.C. İnkılap Tarihi ve Atatürkçülük',
        questionCount: 10,
      ),
      SectionDefinition(
        id: 'din',
        name: 'Din Kültürü ve Ahlak Bilgisi',
        questionCount: 10,
      ),
      SectionDefinition(id: 'yabanci', name: 'Yabancı Dil', questionCount: 10),
    ],
  );

  static const kpssLisans = ExamType(
    id: 'kpss-lisans',
    name: 'KPSS Lisans',
    penaltyDivisor: 4,
    defaultTargetNet: 80,
    sections: [
      SectionDefinition(id: 'gy', name: 'Genel Yetenek', questionCount: 60),
      SectionDefinition(id: 'gk', name: 'Genel Kültür', questionCount: 60),
    ],
  );

  static const all = <ExamType>[yksTyt, lgs, kpssLisans];

  static ExamType? byId(String id) {
    for (final exam in all) {
      if (exam.id == id) return exam;
    }
    return null;
  }
}
