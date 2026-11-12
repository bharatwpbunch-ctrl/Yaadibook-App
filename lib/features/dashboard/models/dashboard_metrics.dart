/// Model representing the four key daily metrics shown on the Today Dashboard.
class DashboardMetrics {
  final int totalCustomers;
  final int pendingServices;
  final int maintenanceDue;
  final int amcExpiringSoon;

  const DashboardMetrics({
    this.totalCustomers = 0,
    this.pendingServices = 0,
    this.maintenanceDue = 0,
    this.amcExpiringSoon = 0,
  });

  static const DashboardMetrics zero = DashboardMetrics();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardMetrics &&
          runtimeType == other.runtimeType &&
          totalCustomers == other.totalCustomers &&
          pendingServices == other.pendingServices &&
          maintenanceDue == other.maintenanceDue &&
          amcExpiringSoon == other.amcExpiringSoon;

  @override
  int get hashCode =>
      totalCustomers.hashCode ^
      pendingServices.hashCode ^
      maintenanceDue.hashCode ^
      amcExpiringSoon.hashCode;

  DashboardMetrics copyWith({
    int? totalCustomers,
    int? pendingServices,
    int? maintenanceDue,
    int? amcExpiringSoon,
  }) {
    return DashboardMetrics(
      totalCustomers: totalCustomers ?? this.totalCustomers,
      pendingServices: pendingServices ?? this.pendingServices,
      maintenanceDue: maintenanceDue ?? this.maintenanceDue,
      amcExpiringSoon: amcExpiringSoon ?? this.amcExpiringSoon,
    );
  }
}
