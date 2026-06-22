abstract final class AppRoutes {
  static const splash = '/';
  static const dashboard = '/dashboard';
  static const orders = '/orders';
  static const newOrder = '/orders/new';
  static const incomingRebar = '/incoming-rebar';
  static const deliveryList = '/incoming-rebar/list';
  static const newDelivery = '/incoming-rebar/new';
  static const supplierPerformance = '/incoming-rebar/suppliers';
  static String deliveryDetail(String id) => '/incoming-rebar/$id';
  static const fieldCount = '/field-count';
  static const reconciliation = '/field-count/reconciliation';
  static const newCount = '/field-count/new';
  static String countDetail(String id) => '/field-count/$id';
  static const analysis = '/analysis';
  static const survey = '/survey';
  static String surveyDetail(String id) => '/survey/$id';
}
