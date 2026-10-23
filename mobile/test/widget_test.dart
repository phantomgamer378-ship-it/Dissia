import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanket_ai/shared/models/incident_model.dart';
import 'package:sanket_ai/shared/models/report_model.dart';
import 'package:sanket_ai/shared/models/task_model.dart';
import 'package:sanket_ai/shared/models/user_model.dart';
import 'package:sanket_ai/shared/widgets/sanket_button.dart';
import 'package:sanket_ai/shared/widgets/status_badge.dart';
import 'package:sanket_ai/offline/draft_store/draft_model.dart';

void main() {
  group('SANKET AI Domain Models Tests', () {
    test('UserModel role permissions are enforced correctly', () {
      final coordinator = UserModel(
        id: 'u-1',
        email: 'coord@sanket.ai',
        displayName: 'John Coordinator',
        role: UserRole.coordinator,
        createdAt: DateTime.now(),
      );

      final responder = UserModel(
        id: 'u-2',
        email: 'resp@sanket.ai',
        displayName: 'Jane Responder',
        role: UserRole.responder,
        createdAt: DateTime.now(),
      );

      final citizen = UserModel(
        id: 'u-3',
        email: 'citizen@example.com',
        role: UserRole.public,
        createdAt: DateTime.now(),
      );

      expect(coordinator.role.canViewPrivateReports, isTrue);
      expect(coordinator.role.canManageIncidents, isTrue);
      expect(coordinator.role.canUpdateTasks, isTrue);
      expect(coordinator.initials, 'JC');

      expect(responder.role.canViewPrivateReports, isFalse);
      expect(responder.role.canManageIncidents, isFalse);
      expect(responder.role.canUpdateTasks, isTrue);

      expect(citizen.role.canViewPrivateReports, isFalse);
      expect(citizen.role.canManageIncidents, isFalse);
      expect(citizen.role.canUpdateTasks, isFalse);
      expect(citizen.initials, 'C');
    });

    test('ReportModel serialization and parsing', () {
      final now = DateTime.now();
      final report = ReportModel(
        id: 'rep-123',
        description: 'Flash flooding on highway 44',
        locationDescription: 'Highway 44, Mile 12',
        status: ReportStatus.processing,
        processingState: ProcessingState.extracting,
        submitterId: 'citizen-9',
        submittedAt: now,
        aiSummary: 'Trapped vehicles detected',
      );

      final json = report.toJson();
      expect(json['id'], 'rep-123');
      expect(json['status'], 'processing');
      expect(json['processing_state'], 'extracting');

      final fromJson = ReportModel.fromJson(json);
      expect(fromJson.id, report.id);
      expect(fromJson.description, report.description);
      expect(fromJson.aiSummary, report.aiSummary);
      expect(fromJson.status, ReportStatus.processing);
    });

    test('TaskModel status parsing and labels', () {
      final task = TaskModel(
        id: 'tsk-001',
        title: 'Dispatch sandbags to Sector 4',
        status: TaskStatus.inProgress,
        priority: TaskPriority.critical,
        assigneeId: 'unit-alpha',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(task.status.label, 'In Progress');
      expect(task.priority, TaskPriority.critical);
    });

    test('IncidentModel status and severity', () {
      final inc = IncidentModel(
        id: 'inc-999',
        title: 'Dam Wall Seepage',
        status: IncidentStatus.active,
        severity: IncidentSeverity.critical,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(inc.status, IncidentStatus.active);
      expect(inc.severity, IncidentSeverity.critical);
    });

    test('ReportDraft local offline storage serialization', () {
      final draft = ReportDraft(
        id: 'draft-xyz',
        description: 'Offline report during power outage',
        location: 'Zone B Grid 4',
        latitude: 18.5204,
        longitude: 73.8567,
        aiConsent: true,
        localAttachmentPaths: ['/tmp/photo1.jpg', '/tmp/photo2.jpg'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: 'pending_sync',
        retryCount: 2,
      );

      final map = draft.toMap();
      expect(map['id'], 'draft-xyz');
      expect(map['sync_status'], 'pending_sync');
      expect(map['retry_count'], 2);

      final recovered = ReportDraft.fromMap(map);
      expect(recovered.id, draft.id);
      expect(recovered.localAttachmentPaths.length, 2);
      expect(recovered.latitude, 18.5204);
      expect(recovered.aiConsent, isTrue);
    });
  });

  group('SANKET AI Shared Widgets Tests', () {
    testWidgets('StatusBadge renders correctly for various states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(label: 'QUEUED'),
                StatusBadge(label: 'PROCESSING'),
                StatusBadge(label: 'COMPLETED'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('QUEUED'), findsOneWidget);
      expect(find.text('PROCESSING'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
    });

    testWidgets('SanketButton triggers callback when clicked and disables on loading', (tester) async {
      var clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SanketButton(
              text: 'Submit Emergency',
              onPressed: () {
                clicked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Submit Emergency'), findsOneWidget);
      await tester.tap(find.byType(SanketButton));
      expect(clicked, isTrue);

      // Verify loading state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SanketButton(
              text: 'Submit Emergency',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit Emergency'), findsNothing);
    });
  });
}
