// Mentesana — on-device crisis language detection.
// Canonical pattern shared by every surface so screening is consistent.

/// Canonical on-device crisis phrase detector, shared by every surface
/// (journal editor, weekly insight, and the AI post-check) so screening is
/// consistent and never depends on the AI layer being reachable. Broadened
/// from the prototype's original short list.
final kCrisisRe = RegExp(
  r"\b(kill(ing)? myself|suicide|suicidal|self[- ]?harm|hurt myself|harm myself|end my life|end it all|want to die|wanna die|better off dead|no reason to (live|go on)|can'?t go on|don'?t want to (be here|live|wake up)|give up on everything|nothing left for me)\b",
  caseSensitive: false,
);

/// True when any of the given texts contains crisis language.
bool containsCrisisLanguage(Iterable<String> texts) =>
    texts.any((t) => t.isNotEmpty && kCrisisRe.hasMatch(t));
