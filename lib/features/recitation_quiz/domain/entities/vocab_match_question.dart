/// Satu pasangan kosa kata Arab dan artinya untuk permainan mencocokkan.
class VocabMatchPair {
  final String arabic;
  final String meaning;

  const VocabMatchPair({required this.arabic, required this.meaning});
}

/// Empat pasangan kosa kata yang harus dicocokkan satu per satu.
class VocabMatchQuestion {
  final List<VocabMatchPair> pairs;

  const VocabMatchQuestion({required this.pairs}) : assert(pairs.length >= 2);
}
