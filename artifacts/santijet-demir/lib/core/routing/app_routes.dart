abstract final class AppRoutes {
  static const splash = '/';
  static const dashboard = '/dashboard';
  static const orders = '/orders';
  static const newOrder = '/orders/new';
  static const incomingRebar = '/incoming-rebar';
  static const fieldCount = '/field-count';
  static const analysis = '/analysis';
  static const survey = '/survey';
  static String surveyDetail(String id) => '/survey/$id';
}
