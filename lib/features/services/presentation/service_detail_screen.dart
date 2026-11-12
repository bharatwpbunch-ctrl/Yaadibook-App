import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/communication_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/service_activity.dart';
import '../../../../shared/models/service_attachment.dart';
import '../../../../shared/models/service_entry.dart';
import '../../../../shared/providers/backend_providers.dart';
import '../../../../core/widgets/yb_error_state.dart';
import '../../../../core/widgets/yb_loading_state.dart';
import '../../communications/presentation/widgets/communication_composer_sheet.dart';
import '../../communications/providers/communication_providers.dart';
import '../providers/service_providers.dart';

/// Screen displaying full details, actions, attachments, and timeline for a single service entry.
class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String serviceId;

  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingAttachment = false;

  void _invalidateAll(String serviceId, String customerId) {
    ref.invalidate(serviceDetailProvider(serviceId));
    ref.invalidate(serviceActivitiesProvider(serviceId));
    ref.invalidate(servicesListProvider);
    ref.invalidate(servicesSummaryProvider);
    ref.invalidate(pendingServicesListProvider);
    ref.invalidate(recentServicesProvider);
    ref.invalidate(customerServiceHistoryProvider(customerId));
    ref.invalidate(customerServiceCountsProvider(customerId));
  }

  Future<void> _handleStatusUpdate(
    BuildContext context,
    ServiceEntry service,
    String targetStatus, {
    String? workPerformed,
    String? notes,
  }) async {
    final repo = ref.read(serviceRepositoryProvider);
    try {
      await repo.updateServiceStatus(
        serviceId: service.id,
        businessId: service.businessId,
        newStatus: targetStatus,
        oldStatus: service.status,
        workPerformed: workPerformed,
        finalNotes: notes,
      );

      _invalidateAll(service.id, service.customerId);

      if (!context.mounted) return;
      final l10n = context.l10n;
      String statusLabel;
      switch (targetStatus) {
        case 'in_progress':
          statusLabel = l10n.serviceStatusInProgress;
          break;
        case 'completed':
          statusLabel = l10n.serviceStatusCompleted;
          break;
        case 'cancelled':
          statusLabel = l10n.serviceStatusCancelled;
          break;
        default:
          statusLabel = l10n.serviceStatusPending;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.serviceStatusUpdateSuccess(statusLabel)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCompletionDialog(BuildContext context, ServiceEntry service) {
    final l10n = context.l10n;
    final workController = TextEditingController(
      text: service.workPerformed ?? '',
    );
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success),
            AppSpacing.gapH8,
            Expanded(
              child: Text(
                l10n.serviceMarkCompletedTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.serviceMarkCompletedMessage,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              AppSpacing.gapV16,
              TextField(
                controller: workController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.serviceWorkPerformedLabel,
                  hintText: l10n.serviceWorkPerformedHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              ),
              AppSpacing.gapV12,
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Completion Notes (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleStatusUpdate(
                context,
                service,
                'completed',
                workPerformed: workController.text.trim().isNotEmpty
                    ? workController.text.trim()
                    : null,
                notes: notesController.text.trim().isNotEmpty
                    ? notesController.text.trim()
                    : null,
              );
            },
            child: Text(l10n.serviceActionMarkCompleted),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, ServiceEntry service) {
    final l10n = context.l10n;
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.error),
            AppSpacing.gapH8,
            Expanded(
              child: Text(
                l10n.serviceCancelTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.serviceCancelMessage,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            AppSpacing.gapV16,
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Cancellation Reason (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleStatusUpdate(
                context,
                service,
                'cancelled',
                notes: reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : null,
              );
            },
            child: Text(l10n.serviceActionCancel),
          ),
        ],
      ),
    );
  }

  void _showResumeDialog(BuildContext context, ServiceEntry service) {
    final l10n = context.l10n;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.serviceResumeTitle),
        content: Text(l10n.serviceResumeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleStatusUpdate(context, service, 'in_progress');
            },
            child: Text(l10n.serviceActionResume),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAttachment(
    ImageSource source,
    ServiceEntry service,
  ) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file == null) return;

      setState(() => _isUploadingAttachment = true);

      final bytes = await file.readAsBytes();
      final fileName = file.name;
      final mimeType = file.mimeType ?? 'image/jpeg';

      final repo = ref.read(serviceRepositoryProvider);
      await repo.addServiceAttachment(
        businessId: service.businessId,
        serviceId: service.id,
        fileName: fileName,
        fileBytes: bytes,
        mimeType: mimeType,
      );

      _invalidateAll(service.id, service.customerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attachment uploaded successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload attachment: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAttachment = false);
      }
    }
  }

  void _showAttachmentPickerSheet(BuildContext context, ServiceEntry service) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.serviceAddPhoto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapV16,
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: Text(l10n.serviceTakePhoto),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadAttachment(ImageSource.camera, service);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: Text(l10n.serviceChooseGallery),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadAttachment(ImageSource.gallery, service);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _viewOrDownloadAttachment(ServiceAttachment attachment) async {
    try {
      final repo = ref.read(serviceRepositoryProvider);
      final signedUrl = await repo.getAttachmentDownloadUrl(
        attachment.filePath,
      );
      if (signedUrl != null) {
        final uri = Uri.parse(signedUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open attachment file')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
      }
    }
  }

  Future<void> _deleteAttachment(
    ServiceAttachment attachment,
    ServiceEntry service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Attachment?'),
        content: Text(
          'Are you sure you want to remove "${attachment.fileName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(serviceRepositoryProvider);
        await repo.deleteServiceAttachment(
          attachmentId: attachment.id,
          filePath: attachment.filePath,
        );
        _invalidateAll(service.id, service.customerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attachment deleted'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete attachment: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceId));

    return serviceAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(l10n.serviceDetailTitle),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: const Center(child: YbLoadingState()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.serviceDetailTitle),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: YbErrorState(
          title: 'Could not load service details',
          message: err.toString(),
          onRetry: () => ref.refresh(serviceDetailProvider(widget.serviceId)),
        ),
      ),
      data: (service) {
        if (service == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.serviceDetailTitle)),
            body: const Center(child: Text('Service entry not found')),
          );
        }

        final activitiesAsync = ref.watch(
          serviceActivitiesProvider(service.id),
        );
        final business = ref.watch(currentBusinessProvider).valueOrNull;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              service.serviceNumber.isNotEmpty
                  ? service.serviceNumber
                  : l10n.serviceDetailTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                tooltip: l10n.actionEdit,
                onPressed: () => context.push('/services/${service.id}/edit'),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'complete') {
                    _showCompletionDialog(context, service);
                  } else if (value == 'cancel') {
                    _showCancelDialog(context, service);
                  } else if (value == 'resume') {
                    _showResumeDialog(context, service);
                  } else if (value == 'in_progress') {
                    _handleStatusUpdate(context, service, 'in_progress');
                  }
                },
                itemBuilder: (ctx) => [
                  if (service.isPending)
                    PopupMenuItem(
                      value: 'in_progress',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.play_arrow_outlined,
                            color: AppColors.info,
                            size: 20,
                          ),
                          AppSpacing.gapH8,
                          Text('Mark In Progress'),
                        ],
                      ),
                    ),
                  if (!service.isCompleted && !service.isCancelled)
                    PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                            size: 20,
                          ),
                          AppSpacing.gapH8,
                          Text(l10n.serviceActionMarkCompleted),
                        ],
                      ),
                    ),
                  if (!service.isCancelled)
                    PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cancel_outlined,
                            color: AppColors.error,
                            size: 20,
                          ),
                          AppSpacing.gapH8,
                          Text(l10n.serviceActionCancel),
                        ],
                      ),
                    ),
                  if (service.isCancelled)
                    PopupMenuItem(
                      value: 'resume',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.replay_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          AppSpacing.gapH8,
                          Text(l10n.serviceActionResume),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              _invalidateAll(service.id, service.customerId);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Hero / Status Card
                  _buildStatusHeroCard(context, service),
                  AppSpacing.gapV16,

                  // Customer Details Card
                  _buildCustomerCard(context, service, business?.businessName),
                  AppSpacing.gapV16,

                  // Equipment Card (if linked)
                  if (service.equipment != null) ...[
                    _buildEquipmentCard(context, service),
                    AppSpacing.gapV16,
                  ],

                  // Work Details Card
                  _buildWorkDetailsCard(context, service),
                  AppSpacing.gapV16,

                  // Charges Breakdown Card
                  _buildChargesCard(context, service),
                  AppSpacing.gapV16,

                  // Attachments Card
                  _buildAttachmentsCard(context, service),
                  AppSpacing.gapV16,

                  // Follow-up Maintenance & AMC Shortcuts Card
                  _buildFollowupAndContractsCard(context, service),
                  AppSpacing.gapV16,

                  // Activity Timeline Card
                  _buildActivityTimelineCard(context, activitiesAsync),
                  AppSpacing.gapV32,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowupAndContractsCard(
    BuildContext context,
    ServiceEntry service,
  ) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.update_rounded, size: 20, color: AppColors.primary),
              AppSpacing.gapH8,
              Text(
                'Future Actions & Contracts',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.gapV12,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  icon: const Icon(
                    Icons.event_repeat_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    l10n.maintenanceScheduleFutureShortcut,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () => context.push(
                    '/maintenance/add?customerId=${service.customerId}&equipmentId=${service.equipmentId ?? ''}',
                  ),
                ),
              ),
              AppSpacing.gapH8,
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    side: const BorderSide(color: AppColors.secondary),
                  ),
                  icon: const Icon(
                    Icons.assignment_outlined,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  label: Text(
                    l10n.amcCreateShortcut,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () => context.push(
                    '/amc/create?customerId=${service.customerId}&equipmentId=${service.equipmentId ?? ''}',
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapV8,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.notification_add_outlined, size: 16),
              label: Text(l10n.remindersCreateFollowupShortcut),
              onPressed: () => context.push(
                '/reminders/create?customerId=${service.customerId}&serviceId=${service.id}&category=customer_followup',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeroCard(BuildContext context, ServiceEntry service) {
    final l10n = context.l10n;

    Color statusColor;
    Color statusBg;
    String statusText;

    switch (service.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
        statusBg = AppColors.successBg;
        statusText = l10n.serviceStatusCompleted;
        break;
      case 'in_progress':
        statusColor = AppColors.info;
        statusBg = AppColors.infoBg;
        statusText = l10n.serviceStatusInProgress;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusBg = AppColors.errorBg;
        statusText = l10n.serviceStatusCancelled;
        break;
      case 'pending':
      default:
        statusColor = AppColors.warning;
        statusBg = AppColors.warningBg;
        statusText = l10n.serviceStatusPending;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Reference pill + Status chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (service.serviceNumber.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    service.serviceNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppSpacing.gapH6,
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapV12,

          // Title
          Text(
            service.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          AppSpacing.gapV8,

          // Metadata row: Service Type & Date
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.handyman_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  AppSpacing.gapH6,
                  Text(
                    service.serviceTypeDisplay,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  AppSpacing.gapH6,
                  Text(
                    DateFormatter.formatShort(service.serviceDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.gapV16,

          // Quick status action buttons
          if (service.isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: const BorderSide(color: AppColors.info),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.play_arrow_outlined, size: 18),
                    label: const Text('Start Work'),
                    onPressed: () =>
                        _handleStatusUpdate(context, service, 'in_progress'),
                  ),
                ),
                AppSpacing.gapH12,
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(l10n.serviceActionMarkCompleted),
                    onPressed: () => _showCompletionDialog(context, service),
                  ),
                ),
              ],
            )
          else if (service.isInProgress)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(l10n.serviceActionMarkCompleted),
                onPressed: () => _showCompletionDialog(context, service),
              ),
            )
          else if (service.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                  AppSpacing.gapH8,
                  Expanded(
                    child: Text(
                      'Completed on ${service.completedAt != null ? DateFormatter.formatDateTime(service.completedAt!) : DateFormatter.formatShort(service.updatedAt)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (service.isCancelled)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'This service entry is cancelled.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: Text(l10n.serviceActionResume),
                  onPressed: () => _showResumeDialog(context, service),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    ServiceEntry service,
    String? businessName,
  ) {
    final l10n = context.l10n;
    final customer = service.customer;

    if (customer == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Text('Customer information not available'),
      );
    }

    final address = service.customerAddress ?? customer.primaryAddress;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              AppSpacing.gapH8,
              const Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/customers/${customer.id}'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'View Profile',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          AppSpacing.gapV8,

          Text(
            customer.fullName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV4,

          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              AppSpacing.gapH6,
              Text(
                customer.primaryPhone,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          if (address != null && address.formattedAddress.isNotEmpty) ...[
            AppSpacing.gapV4,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                AppSpacing.gapH6,
                Expanded(
                  child: Text(
                    address.formattedAddress,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          AppSpacing.gapV12,

          // Call & WhatsApp quick actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  label: Text(l10n.customerActionCall),
                  onPressed: () =>
                      CommunicationService.makePhoneCall(customer.primaryPhone),
                ),
              ),
              AppSpacing.gapH12,
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsApp,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.chat_rounded, size: 16),
                  label: Text(l10n.customerActionWhatsApp),
                  onPressed: () async {
                    final bName = businessName ?? 'our service team';
                    final sRef = service.serviceNumber.isNotEmpty
                        ? ' (${service.serviceNumber})'
                        : '';
                    final msg =
                        'Hello ${customer.fullName}, regarding your service "${service.title}"$sRef with $bName.';
                    await ref
                        .read(communicationComposerControllerProvider.notifier)
                        .sendOrOpenWhatsApp(
                          businessId: service.businessId,
                          customerId: customer.id,
                          serviceId: service.id,
                          recipientPhone: customer.primaryPhone,
                          recipientName: customer.fullName,
                          messageBody: msg,
                        );
                  },
                ),
              ),
            ],
          ),
          AppSpacing.gapV8,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send Status Update to Customer'),
              onPressed: () {
                CommunicationComposerSheet.show(
                  context,
                  customer: customer,
                  serviceId: service.id,
                  serviceReference: service.serviceNumber,
                  serviceTitle: service.title,
                  serviceStatus: service.status,
                  amount: service.computedTotal > 0
                      ? service.computedTotal.toStringAsFixed(0)
                      : null,
                  preferredCategory: 'service_update',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(BuildContext context, ServiceEntry service) {
    final eq = service.equipment!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.precision_manufacturing_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              AppSpacing.gapH8,
              const Text(
                'Linked Equipment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.gapV8,
          Text(
            eq.displayName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (eq.serialNumber != null && eq.serialNumber!.isNotEmpty) ...[
            AppSpacing.gapV4,
            Text(
              'S/N: ${eq.serialNumber}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkDetailsCard(BuildContext context, ServiceEntry service) {
    final l10n = context.l10n;
    final hasDesc =
        service.description != null && service.description!.trim().isNotEmpty;
    final hasWork =
        service.workPerformed != null &&
        service.workPerformed!.trim().isNotEmpty;
    final hasNotes = service.notes != null && service.notes!.trim().isNotEmpty;

    if (!hasDesc && !hasWork && !hasNotes) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              AppSpacing.gapH8,
              Text(
                l10n.serviceWorkDetailsSection,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (hasDesc) ...[
            AppSpacing.gapV12,
            const Text(
              'Description / Issue:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            AppSpacing.gapV4,
            Text(
              service.description!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
          if (hasWork) ...[
            AppSpacing.gapV12,
            const Text(
              'Work Performed:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            AppSpacing.gapV4,
            Text(
              service.workPerformed!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
          if (hasNotes) ...[
            AppSpacing.gapV12,
            const Text(
              'Internal Notes:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            AppSpacing.gapV4,
            Text(
              service.notes!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChargesCard(BuildContext context, ServiceEntry service) {
    final l10n = context.l10n;
    final base = service.serviceAmount ?? 0.0;
    final additional = service.additionalCharges;
    final discount = service.discountAmount;
    final total = service.totalAmount ?? service.computedTotal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.currency_rupee_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              AppSpacing.gapH8,
              Text(
                l10n.serviceChargesSection,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.gapV12,

          _buildChargeRow('Service Charge', CurrencyFormatter.format(base)),
          if (additional > 0) ...[
            AppSpacing.gapV4,
            _buildChargeRow(
              'Additional Charges',
              '+ ${CurrencyFormatter.format(additional)}',
            ),
          ],
          if (discount > 0) ...[
            AppSpacing.gapV4,
            _buildChargeRow(
              'Discount',
              '- ${CurrencyFormatter.format(discount)}',
              valueColor: AppColors.success,
            ),
          ],

          AppSpacing.gapV12,
          const Divider(height: 1, color: AppColors.borderSubtle),
          AppSpacing.gapV12,

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.serviceTotalAmountLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargeRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsCard(BuildContext context, ServiceEntry service) {
    final l10n = context.l10n;
    final attachments = service.attachments;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.attach_file_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  AppSpacing.gapH8,
                  Text(
                    l10n.serviceAttachmentsSection,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (_isUploadingAttachment)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton.icon(
                  onPressed: () => _showAttachmentPickerSheet(context, service),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: const Text(
                    'Add Photo',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          AppSpacing.gapV8,

          if (attachments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No photos or documents attached yet.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attachments.length,
              separatorBuilder: (ctx, i) =>
                  const Divider(height: 1, color: AppColors.borderSubtle),
              itemBuilder: (ctx, index) {
                final att = attachments[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      att.isImage
                          ? Icons.image_outlined
                          : Icons.insert_drive_file_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    att.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    att.formattedFileSize,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        tooltip: 'Open / Download',
                        onPressed: () => _viewOrDownloadAttachment(att),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        tooltip: 'Delete',
                        onPressed: () => _deleteAttachment(att, service),
                      ),
                    ],
                  ),
                  onTap: () => _viewOrDownloadAttachment(att),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityTimelineCard(
    BuildContext context,
    AsyncValue<List<ServiceActivity>> activitiesAsync,
  ) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
              AppSpacing.gapH8,
              Text(
                l10n.serviceActivityHeader,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.gapV12,

          activitiesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => Text(
              'Could not load activity timeline',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
            data: (activities) {
              if (activities.isEmpty) {
                return const Text(
                  'No activity recorded yet.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                separatorBuilder: (ctx, i) => AppSpacing.gapV12,
                itemBuilder: (ctx, index) {
                  final act = activities[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getActivityColor(act.activityType),
                          shape: BoxShape.circle,
                        ),
                      ),
                      AppSpacing.gapH12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (act.description != null &&
                                act.description!.isNotEmpty) ...[
                              AppSpacing.gapV2,
                              Text(
                                act.description!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            AppSpacing.gapV2,
                            Text(
                              DateFormatter.formatDateTime(act.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return AppColors.primary;
      case 'status_updated':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'attachment_added':
        return AppColors.secondary;
      default:
        return AppColors.textMuted;
    }
  }
}
