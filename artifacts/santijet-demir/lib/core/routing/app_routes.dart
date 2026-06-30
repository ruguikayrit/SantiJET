abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/login/forgot-password';
  static const register = '/register';
  static const projects = '/projects';
  static const joinProject = '/projects/join';
  static String projectMembers(String id) => '/projects/$id/members';
  static const dashboard = '/dashboard';
  static const orders = '/orders';
  static const newOrder = '/orders/new';
  static const incomingRebar = '/incoming-rebar';
  static const deliveryList = '/incoming-rebar/list';
  static const newDelivery = '/incoming-rebar/new';
  static const selectInTransitOrder = '/incoming-rebar/select-order';
  static const supplierPerformance = '/incoming-rebar/suppliers';
  static const performanceAnalysis = '/incoming-rebar/performance';
  static String deliveryDetail(String id) => '/incoming-rebar/$id';
  static String newDeliveryForOrder(String orderId) =>
      '/incoming-rebar/new?orderId=$orderId';
  static const fieldCount = '/field-count';
  static const reconciliation = '/field-count/reconciliation';
  static const newCount = '/field-count/new';
  static const countRecords = '/field-count/records';
  static String countDetail(String id) => '/field-count/detail/$id';
  static const analysis = '/analysis';
  static const reports = '/reports';
  static String reportDetail(String id) => '/reports/$id';
  static const survey = '/survey';
  static const surveyMetraj = '/survey?tab=cad';
  static const surveyMetrajRecords = '/survey?tab=records';
  static String surveyDetail(String id) => '/survey/$id';
  static String savedMetrajDetail(String id) => '/survey/metraj/$id';
  static const settings = '/settings';
  static const companySettings = '/settings/company';
  static const projectSettings = '/settings/project';
  static const notificationSettings = '/settings/notifications';
  static const about = '/settings/about';
}
