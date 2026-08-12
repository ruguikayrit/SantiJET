import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_puantaj/core/utils/puantaj_date.dart';
import 'package:santijet_puantaj/data/providers/tasks_provider.dart';
import 'package:santijet_puantaj/domain/entities/person.dart';
import 'package:santijet_puantaj/domain/entities/site_task.dart';
import 'package:santijet_puantaj/domain/enums/task_status.dart';
import 'package:santijet_puantaj/domain/permissions/role_degree.dart';

void main() {
  group('RoleDegree', () {
    test('saha mühendisi 1. derece, formen değil', () {
      expect(RoleDegree.forProfession('Saha Mühendisi'), RoleDegree.first);
      expect(RoleDegree.forProfession('Saha Formeni'), RoleDegree.field);
      expect(RoleDegree.forProfession('Makine Formeni'), RoleDegree.field);
      expect(RoleDegree.canAssignTasks(
        Person(id: '1', projectId: 'p', name: 'A', profession: 'Şantiye Şefi'),
      ), isTrue);
      expect(RoleDegree.canAssignTasks(
        Person(id: '2', projectId: 'p', name: 'B', profession: 'Saha Formeni'),
      ), isFalse);
    });

    test('sortRank meslek rütbesine göre önem sırası verir', () {
      expect(
        RoleDegree.sortRank('Şantiye Şefi') <
            RoleDegree.sortRank('Saha Formeni'),
        isTrue,
      );
      expect(
        RoleDegree.sortRank('Saha Mühendisi') <
            RoleDegree.sortRank('Usta'),
        isTrue,
      );
      expect(
        RoleDegree.sortRank('Usta') < RoleDegree.sortRank('Saha Düz İşçi'),
        isTrue,
      );
      expect(
        RoleDegree.sortRank('Düz İşçi') < RoleDegree.sortRank(''),
        isTrue,
      );
    });
  });

  group('SiteTask.isVisibleTo', () {
    final muhendis = Person(
      id: 'm1',
      projectId: 'p',
      name: 'Ali',
      profession: 'Saha Mühendisi',
    );
    final formen = Person(
      id: 'f1',
      projectId: 'p',
      name: 'Veli',
      profession: 'Saha Formeni',
    );
    final usta = Person(
      id: 'u1',
      projectId: 'p',
      name: 'Can',
      profession: 'Usta',
    );

    test('formen, mühendise atanan görevi görmez', () {
      const task = SiteTask(
        id: 't1',
        projectId: 'p',
        title: 'Metraj kontrol',
        assignerPersonId: 'm1',
        assignerName: 'Ali',
        assigneePersonId: 'u1',
        assignee: 'Can',
      );
      expect(task.isVisibleTo(muhendis), isTrue);
      expect(task.isVisibleTo(usta), isTrue);
      expect(task.isVisibleTo(formen), isFalse);
    });
  });

  group('TasksNotifier.applyStatus', () {
    test('tamamlanınca gerçek teslim tarihi yazar', () {
      const task = SiteTask(
        id: 't1',
        projectId: 'p',
        title: 'WC aksesuar',
        status: TaskStatus.todo,
      );
      final done = TasksNotifier.applyStatus(task, TaskStatus.done);
      expect(done.status, TaskStatus.done);
      expect(done.actualDeliveryDate, PuantajDate.today());

      final again = TasksNotifier.applyStatus(
        done.copyWith(actualDeliveryDate: '10.08.2026'),
        TaskStatus.done,
      );
      expect(again.actualDeliveryDate, '10.08.2026');

      final reopen = TasksNotifier.applyStatus(again, TaskStatus.todo);
      expect(reopen.status, TaskStatus.todo);
      expect(reopen.actualDeliveryDate, isEmpty);
    });
  });
}
