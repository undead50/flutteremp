enum ApprovalDecision {
  approve,
  requestRevision,
  decline;

  /// Rejecting or bouncing a memo must always be explained to its author.
  bool get requiresComment => this != approve;
}
