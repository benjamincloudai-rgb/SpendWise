/// Static, reusable merchant intelligence for the statement import preview.
///
/// Phase 6C: a single lightweight, in-memory mapping that turns a raw
/// description into a clean merchant name ([extractMerchant]) and a suggested
/// category ([categorize]). It never reads Firestore categories and nothing
/// here is persisted.
class MerchantCategorizer {
  const MerchantCategorizer();

  /// Fallback category for merchants that match no rule.
  static const String others = 'Others';

  /// Category name -> keywords. Matching is case-insensitive, word-boundary
  /// aware, and prefers the longest keyword so compound names such as
  /// "amazon pay" beat the shorter "amazon".
  static const List<(String, List<String>)> _rules = [
    (
      'Food',
      [
        'swiggy',
        'zomato',
        'dominos',
        'kfc',
        'mcdonald\'s',
        'burger king',
        'pizza hut',
        'foodpanda',
        'faasos',
      ],
    ),
    (
      'Transport',
      ['uber', 'ola', 'rapido', 'meru', 'metro', 'irctc'],
    ),
    (
      'Entertainment',
      ['netflix', 'spotify', 'hotstar', 'bookmyshow', 'prime video', 'jio cinema'],
    ),
    (
      'Shopping',
      ['amazon pay', 'amazon', 'flipkart', 'myntra', 'meesho', 'snapdeal', 'ajio', 'nykaa'],
    ),
    (
      'Salary',
      ['salary', 'payroll', 'wages', 'stipend', 'pension'],
    ),
  ];

  /// Categories whose keywords describe a payment purpose rather than a
  /// merchant name, so they are never extracted as the merchant itself.
  static const Set<String> _purposeCategories = {'Salary'};

  /// Single-word payment channels (strippable as leading words).
  static const List<String> _singleWordChannels = [
    'upi',
    'neft',
    'imps',
    'rtgs',
    'nach',
    'ecs',
    'atm',
    'pos',
    'cash',
    'cheque',
    'card',
    'wallet',
    'transfer',
    'gpay',
    'bhim',
    'mobikwik',
    'paytm',
    'phonepe',
  ];

  /// Multi-word payment channels, matched as whole leading phrases.
  static const List<String> _multiWordChannels = [
    'google pay',
    'credit card',
    'debit card',
    'bank transfer',
  ];

  static const List<String> _allChannels = [
    ..._singleWordChannels,
    ..._multiWordChannels,
  ];

  /// Acronyms (LTD, PVT, ...) and other all-caps words are preserved
  /// automatically because fallback casing only capitalises the first letter
  /// of each word and leaves the rest untouched.

  /// Suggests a category for [merchant], defaulting to [others].
  String categorize(String merchant) {
    final normalized = _normalize(merchant);
    if (normalized.isEmpty) return others;
    if (_isChannel(normalized)) return others;

    for (final (category, keywords) in _rules) {
      for (final keyword in keywords) {
        if (_matches(normalized, keyword)) return category;
      }
    }
    return others;
  }

  /// Produces a clean merchant string from a raw statement [description].
  ///
  /// Lightweight cleanup only:
  /// - "UPI-SWIGGY-ORDER123" -> "Swiggy"
  /// - "AMAZON PAY INDIA"    -> "Amazon Pay"
  /// - "NEFT SALARY ABC LTD" -> "Salary ABC LTD"
  String extractMerchant(String description) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) return '';

    // UPI-style token strings: "UPI-SWIGGY-ORDER123" or "UPI/P2A/REF".
    if (trimmed.contains('-') || trimmed.contains('/')) {
      final tokens = trimmed.split(RegExp(r'[/\-]'));
      String? known;
      for (final token in tokens) {
        final match = _bestMerchantMatch(_normalize(token));
        if (match != null && match.length > (known?.length ?? 0)) {
          known = match;
        }
      }
      if (known != null) return _titleCase(known);

      String? best;
      for (final token in tokens) {
        final value = token.trim();
        if (value.isEmpty) continue;
        if (_isChannelWord(_normalize(value))) continue;
        if (_isReferenceToken(value)) continue;
        if (value.length > (best?.length ?? 0)) best = value;
      }
      if (best == null) {
        return '';
      }
      return _titleCase(best);
    }

    // Space-separated text: strip leading channel phrases, then match a known
    // merchant, otherwise keep the remaining words.
    final remainder = _stripLeadingChannels(trimmed);
    if (remainder.isEmpty) return _titleCase(trimmed);

    final match = _bestMerchantMatch(_normalize(remainder));
    if (match != null) return _titleCase(match);
    return _titleCaseFirstWord(remainder);
  }

  /// Longest merchant-name keyword contained in [normalized], or `null`.
  String? _bestMerchantMatch(String normalized) {
    String? best;
    for (final (category, keywords) in _rules) {
      if (_purposeCategories.contains(category)) continue;
      for (final keyword in keywords) {
        if (keyword.length > (best?.length ?? 0) && _matches(normalized, keyword)) {
          best = keyword;
        }
      }
    }
    return best;
  }

  /// Word-boundary, case-insensitive keyword match.
  bool _matches(String normalized, String keyword) {
    return RegExp('\\b${RegExp.escape(keyword)}\\b').hasMatch(normalized);
  }

  /// Whether [normalized] is a payment channel (multi-word aware).
  bool _isChannel(String normalized) {
    for (final channel in _allChannels) {
      if (_matches(normalized, channel)) return true;
    }
    return false;
  }

  /// Whether a single [normalized] token is a payment channel word.
  bool _isChannelWord(String normalized) {
    return _singleWordChannels.contains(normalized);
  }

  /// Removes any leading sequence of channel phrases (UPI, NEFT, Google Pay...).
  String _stripLeadingChannels(String text) {
    var rest = text.trimLeft();
    var changed = true;
    while (changed) {
      changed = false;
      for (final channel in _allChannels) {
        if (_startsWithWord(rest, channel)) {
          rest = rest.substring(channel.length).trimLeft();
          changed = true;
          break;
        }
      }
    }
    return rest;
  }

  /// Whether [text] starts with [channel] at a word boundary.
  bool _startsWithWord(String text, String channel) {
    final lower = text.toLowerCase();
    if (!lower.startsWith(channel)) return false;
    if (lower.length == channel.length) return true;
    final next = lower[channel.length];
    return next == ' ' || next == '-' || next == '/';
  }

  /// Whether a token looks like a reference/order number rather than a name.
  bool _isReferenceToken(String token) {
    return RegExp(r'^\d+$').hasMatch(token) ||
        RegExp(r'^[a-zA-Z]{0,8}\d{3,}$').hasMatch(token);
  }

  /// Lowercases, trims and collapses whitespace for matching.
  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Title-cases every word: "amazon pay" -> "Amazon Pay".
  String _titleCase(String value) {
    final words = value.split(' ');
    return words.map(_capitalize).join(' ');
  }

  /// Title-cases only the first word and leaves the rest verbatim, which keeps
  /// all-caps bank descriptions readable without lowercasing acronyms or
  /// company names: "SALARY ABC LTD" -> "Salary ABC LTD".
  String _titleCaseFirstWord(String value) {
    final words = value.split(' ');
    if (words.isEmpty) return value;
    words[0] = _capitalize(words[0]);
    return words.join(' ');
  }

  String _capitalize(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }
}
