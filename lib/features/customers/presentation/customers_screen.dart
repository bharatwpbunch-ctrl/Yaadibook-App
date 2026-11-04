import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/widgets.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customersTitle),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add_outlined,
              color: AppColors.primary,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l10n.actionAdd} ${l10n.customersTitle}'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: YbSearchInput(
              hint: l10n.searchPlaceholder,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
            ),
          ),
          Expanded(
            child:
                _searchQuery.isNotEmpty &&
                    !l10n.sampleCustomerName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    )
                ? YbEmptyState(
                    title: l10n.noDataFound,
                    message: l10n.noDataSubtitle,
                    actionLabel: l10n.actionAdd,
                    onAction: () {},
                  )
                : ListView(
                    padding: AppSpacing.screenPadding,
                    children: [
                      YbCustomerCard(
                        name: l10n.sampleCustomerName,
                        phone: l10n.sampleCustomerPhone,
                        address: l10n.sampleCustomerAddress,
                        tag: 'VIP AMC',
                        onTap: () {},
                        onCall: () {},
                        onWhatsApp: () {},
                      ),
                      AppSpacing.gapV12,
                      YbCustomerCard(
                        name: 'Bhavin Shah',
                        phone: '+91 97240 56789',
                        address: 'Satellite Road, Ahmedabad',
                        tag: 'RO Purifier',
                        onTap: () {},
                        onCall: () {},
                        onWhatsApp: () {},
                      ),
                      AppSpacing.gapV12,
                      YbCustomerCard(
                        name: 'Shree Krishna Jewellers',
                        phone: '+91 94260 99887',
                        address: 'C.G. Road, Ahmedabad',
                        tag: 'CCTV Annual Contract',
                        onTap: () {},
                        onCall: () {},
                        onWhatsApp: () {},
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
