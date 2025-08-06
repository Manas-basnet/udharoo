class BulkOperationResult {
  final List<String> successfulIds;
  final List<String> failedIds;
  final Map<String, String> failureReasons;

  const BulkOperationResult({
    required this.successfulIds,
    required this.failedIds,
    required this.failureReasons,
  });

  bool get hasFailures => failedIds.isNotEmpty;
  bool get hasSuccesses => successfulIds.isNotEmpty;
  int get totalProcessed => successfulIds.length + failedIds.length;
  
  String getSummaryMessage() {
    if (hasFailures && hasSuccesses) {
      return '${successfulIds.length} successful, ${failedIds.length} failed';
    } else if (hasSuccesses) {
      return '${successfulIds.length} transaction${successfulIds.length == 1 ? '' : 's'} processed successfully';
    } else {
      return 'All operations failed';
    }
  }
}