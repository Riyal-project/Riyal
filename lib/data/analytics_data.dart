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

// Monthly demo amounts reconcile with the Home overview (950 + 1,623 + 7,000).
final analyticsItems = <AnalyticsItem>[
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
  const AnalyticsItem('Home internet', 'Utilities', 200, 8, 'Internet'),
  const AnalyticsItem('Water', 'Utilities', 234, 16, 'Water'),
  const AnalyticsItem('Housekeeper allowance', 'People', 1800, 2, 'Household'),
  const AnalyticsItem('Driver allowance', 'People', 2200, 7, 'Transport'),
  const AnalyticsItem('Nanny allowance', 'People', 3000, 22, 'Household'),
];

// Combined budget is independent of category caps.
const overallAnalyticsBudget = 12000.0;
const analyticsBudgets = {
  'Subscriptions': subscriptionsBudget,
  'Utilities': 2000.0,
  'People': 9000.0,
};
const analyticsHistory = <String, List<double>>{
  'Subscriptions': [760, 820, 850, 880, 900, subscriptionsSpent],
  'Utilities': [870, 972, 1076, 1176, 1233, 1623],
  'People': [7000, 7000, 7000, 7000, 7000, 7000],
};
