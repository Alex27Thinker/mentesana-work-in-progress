// Mente sana — sentinel for nullable copyWith semantics.
//
// The default Dart pattern of writing `v: v ?? this.v` cannot clear a
// nullable field: passing `null` and passing nothing both look the
// same. Every extracted model uses this public sentinel so that:
//
//   * omitted argument        → preserve current value;
//   * explicit null           → clear the current value;
//   * non-null argument       → replace the current value.
//
// This sentinel is shared by all immutable models in the domain layer
// and is not part of any other public API surface.

const Object unset = Object();

/// True when the supplied [value] is the explicit "argument omitted"
/// sentinel used by immutable `copyWith` implementations.
bool isUnset(Object? value) => identical(value, unset);
