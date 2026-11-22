class ApiEndpoints {
  const ApiEndpoints._();

  // These paths are the initial contract placeholders. Confirm them against
  // the LoadBoard backend before connecting authentication.
  static const login = '/auth/login';
  static const refreshToken = '/auth/refresh';

  // Shipment workflow paths define the client-side API contract for the
  // repository adapter. Align these with the backend before switching it on.
  static const shipmentWorkflow = '/shipments/workflow';
  static String shipmentDetails(String id) =>
      '/shipments/${Uri.encodeComponent(id)}';
  static const latestLoadPostDraft = '/load-posts/drafts/latest';
  static const loadPostDrafts = '/load-posts/drafts';
  static const loadPostOptions = '/load-posts/options';
  static const contacts = '/contacts';

  static String submitLoadPost(String id) =>
      '/load-posts/${Uri.encodeComponent(id)}/submit';
  static String acceptBid(String shipmentId, String bidId) =>
      '/shipments/${Uri.encodeComponent(shipmentId)}/bids/${Uri.encodeComponent(bidId)}/accept';
}
