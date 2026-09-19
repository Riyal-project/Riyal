import 'demo_mode.dart';
import 'home_data.dart';

class AnalyticsItem {
  const AnalyticsItem(
    this.name,
    this.category,
    this.amount,
    this.days,
    this.group,
  );
  final String name;
  final String category;
  final double amount;
  final int days;
  final String group;
}

// Monthly demo amounts reconcile with the Home overview (950 + 1,823 + 7,000).
final _demoAnalyticsItems = <AnalyticsItem>[
  const AnalyticsItem('Netflix', 'Subscriptions', 45, 3, 'Streaming'),
  const AnalyticsItem('ChatGPT Plus', 'Subscriptions', 80, 10, 'Productivity'),
  const AnalyticsItem('Duolingo', 'Subscriptions', 30, 12, 'Productivity'),
  const AnalyticsItem(
    'Fitness membership',
    'Subscriptions',
    295,
    18,
    'Fitness',
  ),
  const AnalyticsItem(
    'Learning membership',
    'Subscriptions',
    500,
    22,
    'Learning',
  ),
  const AnalyticsItem('Electricity', 'Utilities', 1189, 5, 'Electricity'),
  const AnalyticsItem('Home internet', 'Utilities', 250, 8, 'Internet'),
  const AnalyticsItem('Water', 'Utilities', 234, 16, 'Water'),
  const AnalyticsItem('Mobile', 'Utilities', 150, 25, 'Mobile'),
  const AnalyticsItem('Housekeeper allowance', 'People', 1800, 2, 'Household'),
  const AnalyticsItem('Driver allowance', 'People', 2200, 7, 'Transport'),
  const AnalyticsItem('Nanny allowance', 'People', 3000, 22, 'Household'),
];

// Combined budget is independent of category caps.
const overallAnalyticsBudget = 12000.0;
const analyticsBudgets = {
  'Subscriptions': subscriptionsBudget,
  'Utilities': 2400.0,
  'People': 9000.0,
};
const _demoAnalyticsHistory = <String, List<double>>{
  'Subscriptions': [760, 820, 850, 880, 900, subscriptionsSpent],
  'Utilities': [1070, 1172, 1275, 1384, 1426, 1823],
  'People': [7000, 7000, 7000, 7000, 7000, 7000],
};

// A new sign-up has no items or history yet; the Analytics tab shows an
// empty state instead of charts.
List<AnalyticsItem> get analyticsItems =>
    DemoMode.enabled ? _demoAnalyticsItems : const [];

Map<String, List<double>> get analyticsHistory => DemoMode.enabled
    ? _demoAnalyticsHistory
    : const {
        'Subscriptions': [0, 0, 0, 0, 0, 0],
        'Utilities': [0, 0, 0, 0, 0, 0],
        'People': [0, 0, 0, 0, 0, 0],
      };
