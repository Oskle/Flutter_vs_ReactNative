import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/entities/academic_entities.dart';
import 'academic_csv_parser.dart';
import 'roble_datasource.dart';

class AcademicRemoteDatasource {
  final RobleDatasource _robleDatasource;
  final AcademicCsvParser _csvParser;

  AcademicRemoteDatasource(this._robleDatasource)
    : _csvParser = AcademicCsvParser();

  static const String _coursesTable = 'courses';
  static const String _categoriesTable = 'group_categories';
  static const String _groupsTable = 'groups';
  static const String _enrollmentsTable = 'enrollments';
  static const String _importsTable = 'csv_imports';
  static const String _evaluationCyclesTable = 'evaluation_cycles';
  static const String _evaluationsTable = 'evaluations';

  void _log(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[ACADEMIC:$tag] $message');
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_robleDatasource.currentToken != null)
      'Authorization': 'Bearer ${_robleDatasource.currentToken}',
  };

  Uri _dbUri(String endpoint, [Map<String, String>? query]) {
    final raw =
        '${_robleDatasource.databaseUrl}/${_robleDatasource.dbName}/$endpoint';
    final uri = Uri.parse(raw);
    if (query == null || query.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: query);
  }

  String _asString(dynamic value) => value?.toString() ?? '';

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  Future<List<Map<String, dynamic>>> _readTable(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    final query = <String, String>{'tableName': tableName};
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          query[key] = value.toString();
        }
      });
    }

    final response = await _robleDatasource.client.get(
      _dbUri('read', query),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return data.whereType<Map>().map((e) {
        return Map<String, dynamic>.from(e);
      }).toList();
    }

    if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        return (data['data'] as List).whereType<Map>().map((e) {
          return Map<String, dynamic>.from(e);
        }).toList();
      }
      if (data.isNotEmpty && data.containsKey('_id')) {
        return [data];
      }
    }

    return [];
  }

  Future<Map<String, dynamic>?> _insertRecord(
    String tableName,
    Map<String, dynamic> record,
  ) async {
    final response = await _robleDatasource.client.post(
      _dbUri('insert'),
      headers: _headers,
      body: jsonEncode({
        'tableName': tableName,
        'records': [record],
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      return null;
    }

    final data = jsonDecode(response.body);
    _log('INSERT', 'table=$tableName status=${response.statusCode} body=${response.body}');
    if (data is Map<String, dynamic> && data['inserted'] is List) {
      final inserted = data['inserted'] as List;
      if (inserted.isNotEmpty && inserted.first is Map) {
        return Map<String, dynamic>.from(inserted.first as Map);
      }
    }

    return null;
  }

  Future<bool> _updateRecord(
    String tableName, {
    required Map<String, dynamic> where,
    required Map<String, dynamic> set,
  }) async {
    final uri = _dbUri('update');
    final payloads = [
      {'tableName': tableName, 'where': where, 'set': set},
      {'tableName': tableName, 'filters': where, 'updates': set},
    ];

    for (final payload in payloads) {
      final response = await _robleDatasource.client.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _deleteRecords(
    String tableName, {
    required Map<String, dynamic> where,
  }) async {
    final uri = _dbUri('delete');
    final payload = {'tableName': tableName, 'where': where};

    final response = await _robleDatasource.client.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<List<Map<String, dynamic>>> _readActiveEnrollmentsByGroupIds(
    Iterable<String> groupIds,
  ) async {
    final output = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (final groupId in groupIds) {
      if (groupId.trim().isEmpty) {
        continue;
      }

      final rows = await _readTable(
        _enrollmentsTable,
        filters: {'groupId': groupId, 'isActive': true},
      );

      for (final row in rows) {
        final id = _asString(row['_id']);
        if (id.isNotEmpty) {
          if (seenIds.contains(id)) {
            continue;
          }
          seenIds.add(id);
        }
        output.add(row);
      }
    }

    return output;
  }

  Future<List<Map<String, dynamic>>> _findActiveStudentInGroups({
    required String studentUid,
    required Iterable<String> groupIds,
  }) async {
    final rows = <Map<String, dynamic>>[];

    for (final groupId in groupIds) {
      if (groupId.trim().isEmpty) {
        continue;
      }

      final byStudentUId = await _readTable(
        _enrollmentsTable,
        filters: {
          'groupId': groupId,
          'studentUId': studentUid,
          'isActive': true,
        },
      );
      if (byStudentUId.isNotEmpty) {
        rows.addAll(byStudentUId);
        continue;
      }

      final byStudentUid = await _readTable(
        _enrollmentsTable,
        filters: {
          'groupId': groupId,
          'studentUid': studentUid,
          'isActive': true,
        },
      );
      rows.addAll(byStudentUid);
    }

    return rows;
  }

  Future<TeacherCourseOverview?> createCourse({
    required String name,
    required String nrc,
    required String term,
    required String teacherUid,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final inserted = await _insertRecord(_coursesTable, {
      'name': name,
      'nrc': nrc,
      'term': term,
      'createdBy': teacherUid,
      'createdAt': now,
    });

    if (inserted == null) {
      return null;
    }

    return TeacherCourseOverview(
      id: _asString(inserted['_id']),
      name: _asString(inserted['name']),
      nrc: _asString(inserted['nrc']),
      term: _asString(inserted['term']),
      categoriesCount: 0,
      groupsCount: 0,
      activeStudentsCount: 0,
      categories: const [],
    );
  }

  Future<List<TeacherCourseOverview>> getTeacherCourseOverviews(
    String teacherUid,
  ) async {
    final courses = await _readTable(
      _coursesTable,
      filters: {'createdBy': teacherUid},
    );

    return _buildCourseOverviews(courses);
  }

  Future<List<TeacherCourseOverview>> getStudentCourseOverviews({
    required String studentEmail,
    String? studentUid,
  }) async {
    final normalizedEmail = studentEmail.trim().toLowerCase();

    final enrollmentsByEmail = await _readTable(
      _enrollmentsTable,
      filters: {'studentEmail': normalizedEmail, 'isActive': true},
    );

    final enrollmentsByUid = <Map<String, dynamic>>[];
    final normalizedUid = (studentUid ?? '').trim();
    if (normalizedUid.isNotEmpty) {
      final byStudentUId = await _readTable(
        _enrollmentsTable,
        filters: {'studentUId': normalizedUid, 'isActive': true},
      );
      enrollmentsByUid.addAll(byStudentUId);

      if (byStudentUId.isEmpty) {
        final byStudentUid = await _readTable(
          _enrollmentsTable,
          filters: {'studentUid': normalizedUid, 'isActive': true},
        );
        enrollmentsByUid.addAll(byStudentUid);
      }
    }

    final enrollmentMap = <String, Map<String, dynamic>>{};
    for (final row in [...enrollmentsByEmail, ...enrollmentsByUid]) {
      final rowId = _asString(row['_id']);
      final dedupeKey = rowId.isNotEmpty
          ? rowId
          : '${_asString(row['groupId'])}-${_asString(row['studentEmail'])}-${_asString(row['studentUId'])}';
      enrollmentMap[dedupeKey] = row;
    }

    if (enrollmentMap.isEmpty) {
      return [];
    }

    final groupIds = enrollmentMap.values
        .map((row) => _asString(row['groupId']))
        .where((id) => id.isNotEmpty)
        .toSet();

    if (groupIds.isEmpty) {
      return [];
    }

    final groupsById = <String, Map<String, dynamic>>{};
    for (final groupId in groupIds) {
      final rows = await _readTable(_groupsTable, filters: {'_id': groupId});
      if (rows.isNotEmpty) {
        groupsById[groupId] = rows.first;
      }
    }

    final courseIds = groupsById.values
        .map((group) => _asString(group['courseId']))
        .where((id) => id.isNotEmpty)
        .toSet();

    if (courseIds.isEmpty) {
      return [];
    }

    final courses = <Map<String, dynamic>>[];
    for (final courseId in courseIds) {
      final rows = await _readTable(_coursesTable, filters: {'_id': courseId});
      if (rows.isNotEmpty) {
        courses.add(rows.first);
      }
    }

    return _buildCourseOverviews(courses);
  }

  Future<List<TeacherCourseOverview>> _buildCourseOverviews(
    List<Map<String, dynamic>> courses,
  ) async {

    final output = <TeacherCourseOverview>[];

    for (final course in courses) {
      final courseId = _asString(course['_id']);
      if (courseId.isEmpty) {
        continue;
      }

      final categories = await _readTable(
        _categoriesTable,
        filters: {'courseId': courseId},
      );
      final groups = await _readTable(
        _groupsTable,
        filters: {'courseId': courseId},
      );
      final groupIds = groups.map((group) => _asString(group['_id'])).where(
        (id) => id.isNotEmpty,
      );
      final activeEnrollments = await _readActiveEnrollmentsByGroupIds(groupIds);

      final groupsByCategory = <String, List<Map<String, dynamic>>>{};
      final categoryIdByGroupId = <String, String>{};
      for (final group in groups) {
        final categoryId = _asString(group['categoryId']);
        final groupId = _asString(group['_id']);
        if (categoryId.isEmpty) {
          continue;
        }
        if (groupId.isNotEmpty) {
          categoryIdByGroupId[groupId] = categoryId;
        }
        groupsByCategory.putIfAbsent(categoryId, () => []).add(group);
      }

      final studentsByGroup = <String, int>{};
      final studentsByCategory = <String, int>{};
      final studentRowsByGroup = <String, List<Map<String, dynamic>>>{};
      for (final enrollment in activeEnrollments) {
        final groupId = _asString(enrollment['groupId']);
        final categoryId = categoryIdByGroupId[groupId] ?? '';
        if (groupId.isNotEmpty) {
          studentsByGroup[groupId] = (studentsByGroup[groupId] ?? 0) + 1;
          studentRowsByGroup.putIfAbsent(groupId, () => []).add(enrollment);
        }
        if (categoryId.isNotEmpty) {
          studentsByCategory[categoryId] =
              (studentsByCategory[categoryId] ?? 0) + 1;
        }
      }

      final categoryOverview = categories.map((category) {
        final categoryId = _asString(category['_id']);
        final categoryName = _asString(category['name']);
        final categoryGroups = groupsByCategory[categoryId] ?? const [];

        final groupOverview = categoryGroups.map((group) {
          final groupId = _asString(group['_id']);
          final groupCode = _asString(group['groupName']).isNotEmpty
              ? _asString(group['groupName'])
              : _asString(group['groupCode']);
          final displayName = _asString(group['displayName']).isNotEmpty
              ? _asString(group['displayName'])
              : (_asString(group['name']).isNotEmpty
                    ? _asString(group['name'])
                    : groupCode);

          final studentList = (studentRowsByGroup[groupId] ?? const [])
              .map((enrollment) {
                return StudentOverview(
                  uid: _asString(enrollment['studentUId']).isNotEmpty
                      ? _asString(enrollment['studentUId'])
                      : _asString(enrollment['studentUid']),
                  name: _asString(enrollment['studentName']),
                  email: _asString(enrollment['studentEmail']),
                  studentId: _asString(enrollment['studentId']),
                );
              })
              .toList();

          return GroupOverview(
            id: groupId,
            code: groupCode,
            name: displayName,
            activeStudentsCount: studentsByGroup[groupId] ?? 0,
            students: studentList,
          );
        }).toList();

        return CategoryOverview(
          id: categoryId,
          name: categoryName,
          activeStudentsCount: studentsByCategory[categoryId] ?? 0,
          groups: groupOverview,
        );
      }).toList();

      output.add(
        TeacherCourseOverview(
          id: courseId,
          name: _asString(course['name']),
          nrc: _asString(course['nrc']),
          term: _asString(course['term']),
          categoriesCount: categories.length,
          groupsCount: groups.length,
          activeStudentsCount: activeEnrollments.length,
          categories: categoryOverview,
        ),
      );
    }

    return output;
  }

  Future<String?> _ensureCategory({
    required String courseId,
    required String categoryName,
  }) async {
    final existing = await _readTable(
      _categoriesTable,
      filters: {'courseId': courseId, 'name': categoryName},
    );
    if (existing.isNotEmpty) {
      return _asString(existing.first['_id']);
    }

    final inserted = await _insertRecord(_categoriesTable, {
      'courseId': courseId,
      'name': categoryName,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });

    return inserted == null ? null : _asString(inserted['_id']);
  }

  Future<String?> _ensureGroup({
    required String courseId,
    required String categoryId,
    required String groupName,
    required String displayName,
    String? nrc,
  }) async {
    final existingByGroupName = await _readTable(
      _groupsTable,
      filters: {
        'courseId': courseId,
        'categoryId': categoryId,
        'groupName': groupName,
      },
    );
    if (existingByGroupName.isNotEmpty) {
      return _asString(existingByGroupName.first['_id']);
    }

    final existingByName = await _readTable(
      _groupsTable,
      filters: {
        'courseId': courseId,
        'categoryId': categoryId,
        'name': displayName,
      },
    );
    if (existingByName.isNotEmpty) {
      return _asString(existingByName.first['_id']);
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final payloads = <Map<String, dynamic>>[
      {
        'courseId': courseId,
        'categoryId': categoryId,
        'groupName': groupName,
        'displayName': displayName,
        if (nrc != null && nrc.isNotEmpty) 'nrc': nrc,
        'createdAt': nowIso,
      },
      {
        'courseId': courseId,
        'categoryId': categoryId,
        'name': displayName,
        'groupCode': groupName,
        if (nrc != null && nrc.isNotEmpty) 'nrc': nrc,
        'createdAt': nowIso,
      },
      {
        'courseId': courseId,
        'categoryId': categoryId,
        'name': groupName,
        'code': groupName,
        'createdAt': nowIso,
      },
    ];

    Map<String, dynamic>? inserted;
    for (final payload in payloads) {
      inserted = await _insertRecord(_groupsTable, payload);
      if (inserted != null) {
        break;
      }
    }

    return inserted == null ? null : _asString(inserted['_id']);
  }

  Future<(Map<String, String>, int)> _ensureGroupsBulk({
    required String courseId,
    required String categoryId,
    required List<CsvStudentRow> rows,
  }) async {
    final uniqueRowsByGroup = <String, CsvStudentRow>{};
    for (final row in rows) {
      uniqueRowsByGroup.putIfAbsent(row.groupName, () => row);
    }

    final existing = await _readTable(
      _groupsTable,
      filters: {'courseId': courseId, 'categoryId': categoryId},
    );

    final result = <String, String>{};
    for (final group in existing) {
      final groupId = _asString(group['_id']);
      if (groupId.isEmpty) {
        continue;
      }

      final groupName = _asString(group['groupName']);
      final groupCode = _asString(group['groupCode']);
      final code = _asString(group['code']);
      final name = _asString(group['name']);
      final displayName = _asString(group['displayName']);

      if (groupName.isNotEmpty) {
        result[groupName] = groupId;
      }
      if (groupCode.isNotEmpty) {
        result[groupCode] = groupId;
      }
      if (code.isNotEmpty) {
        result[code] = groupId;
      }

      final fromName = uniqueRowsByGroup.values.firstWhere(
        (row) => row.groupDisplayName == name || row.groupDisplayName == displayName,
        orElse: () => CsvStudentRow(
          categoryName: '',
          groupDisplayName: '',
          groupName: '',
          studentId: '',
          studentName: '',
          studentEmail: '',
        ),
      );
      if (fromName.groupName.isNotEmpty) {
        result[fromName.groupName] = groupId;
      }
    }

    var createdGroups = 0;
    for (final row in uniqueRowsByGroup.values) {
      if (result.containsKey(row.groupName)) {
        continue;
      }

      final inserted = await _ensureGroup(
        courseId: courseId,
        categoryId: categoryId,
        groupName: row.groupName,
        displayName: row.groupDisplayName,
        nrc: row.groupName,
      );

      if (inserted != null && inserted.isNotEmpty) {
        result[row.groupName] = inserted;
        createdGroups++;
      }
    }

    return (result, createdGroups);
  }

  Future<String?> _findStudentUidByEmail(String email) async {
    final userRows = await _readTable('users', filters: {'email': email});
    if (userRows.isEmpty) {
      return null;
    }
    final user = userRows.first;
    return _asString(user['uid']).isNotEmpty
        ? _asString(user['uid'])
        : _asString(user['_id']);
  }

  String _normalizeCategoryString(String raw) {
    var normalized = _csvParser.normalizeText(raw);

    if (normalized.startsWith('categoria')) {
      normalized = normalized.substring('categoria'.length);
    }

    if (normalized.contains('_')) {
      // Usa la parte principal antes de primer underscore.
      normalized = normalized.split('_').first;
    }

    return normalized;
  }

  Future<CsvSyncResult> syncCategoryFromCsv({
    required String courseId,
    required String categoryName,
    required String csvContent,
    required String uploadedBy,
  }) async {
    final normalizedCategory = _normalizeCategoryString(categoryName);
    final parsedRows = _csvParser.parseRows(csvContent).where((row) {
      final rowCategory = _normalizeCategoryString(row.categoryName);

      return rowCategory == normalizedCategory ||
          rowCategory.contains(normalizedCategory);
    }).toList();

    if (parsedRows.isEmpty) {
      throw RobleException(
        'El CSV no tiene filas válidas para la categoría $categoryName',
      );
    }

    final categoryId = await _ensureCategory(
      courseId: courseId,
      categoryName: categoryName,
    );
    if (categoryId == null || categoryId.isEmpty) {
      throw RobleException('No se pudo crear/encontrar la categoría');
    }

    final fileHash = csvContent.hashCode.toString();
    final previousImports = await _readTable(
      _importsTable,
      filters: {
        'courseId': courseId,
        'categoryId': categoryId,
        'fileHash': fileHash,
        'status': 'completed',
      },
    );

    if (previousImports.isNotEmpty) {
      _log(
        'SYNC',
        'CSV ya procesado previamente para este curso/categoría (fileHash=$fileHash).',
      );
      return CsvSyncResult(
        createdGroups: 0,
        activatedEnrollments: 0,
        closedEnrollments: 0,
        totalRows: parsedRows.length,
      );
    }

    final importInserted = await _insertRecord(_importsTable, {
      'courseId': courseId,
      'categoryId': categoryId,
      'uploadedBy': uploadedBy,
      'uploadedAt': DateTime.now().toUtc().toIso8601String(),
      'fileHash': fileHash,
      'status': 'processing',
    });

    final importId = _asString(importInserted?['_id']);
    int createdGroups = 0;
    int activatedEnrollments = 0;
    int closedEnrollments = 0;

    final groupBulkResult = await _ensureGroupsBulk(
      courseId: courseId,
      categoryId: categoryId,
      rows: parsedRows,
    );
    final groupIdByName = groupBulkResult.$1;
    createdGroups = groupBulkResult.$2;

    final uidByEmail = <String, String>{};
    final desiredByStudentEmail = <String, CsvStudentRow>{};

    for (final row in parsedRows) {
      final ensuredGroupId = groupIdByName[row.groupName];

      if (ensuredGroupId == null || ensuredGroupId.isEmpty) {
        continue;
      }

      String studentUid = uidByEmail[row.studentEmail] ?? '';
      if (studentUid.isEmpty) {
        final found = await _findStudentUidByEmail(row.studentEmail);
        studentUid = (found != null && found.isNotEmpty)
            ? found
            : 'email:${row.studentEmail}';
        uidByEmail[row.studentEmail] = studentUid;
      }

      desiredByStudentEmail[row.studentEmail.toLowerCase()] = row;
    }

    if (groupIdByName.isEmpty) {
      throw RobleException(
        'No se pudieron crear/leer grupos en la tabla groups. Revisa nombres de columnas (ej: groupName/displayName o name/groupCode).',
      );
    }

    final groupsInCategory = await _readTable(
      _groupsTable,
      filters: {'courseId': courseId, 'categoryId': categoryId},
    );
    final groupIdsInCategory = groupsInCategory
        .map((row) => _asString(row['_id']))
        .where((id) => id.isNotEmpty)
        .toSet();

    final activeEnrollments = await _readActiveEnrollmentsByGroupIds(
      groupIdsInCategory,
    );

    final activeByStudentEmail = <String, Map<String, dynamic>>{};
    for (final enrollment in activeEnrollments) {
      final email = _asString(enrollment['studentEmail']).toLowerCase();
      final uid = _asString(enrollment['studentUId']).isNotEmpty
          ? _asString(enrollment['studentUId'])
          : _asString(enrollment['studentUid']);
      final key = email.isNotEmpty ? email : uid;
      if (key.isNotEmpty) {
        activeByStudentEmail[key] = enrollment;
      }
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();

    for (final entry in activeByStudentEmail.entries) {
      final studentKey = entry.key;
      final currentEnrollment = entry.value;
      final desiredRow = desiredByStudentEmail[studentKey];

      final currentGroupId = _asString(currentEnrollment['groupId']);
      final desiredGroupId = desiredRow == null
          ? ''
          : (groupIdByName[desiredRow.groupName] ?? '');

      if (desiredRow == null || desiredGroupId != currentGroupId) {
        final ok = await _updateRecord(
          _enrollmentsTable,
          where: {'_id': _asString(currentEnrollment['_id'])},
          set: {'isActive': false, 'validTo': nowIso},
        );
        if (ok) {
          closedEnrollments++;
        } else {
          _log(
            'SYNC',
            'No se pudo cerrar enrollment ${currentEnrollment['_id']}',
          );
        }
      }
    }

    for (final entry in desiredByStudentEmail.entries) {
      final studentEmail = entry.key;
      final row = entry.value;
      final existingActive = activeByStudentEmail[studentEmail];
      final desiredGroupId = groupIdByName[row.groupName] ?? '';
      final studentUid = uidByEmail[row.studentEmail] ?? 'email:${row.studentEmail}';

      final alreadyInSameGroup =
          existingActive != null &&
          _asString(existingActive['groupId']) == desiredGroupId;

      if (alreadyInSameGroup || desiredGroupId.isEmpty) {
        continue;
      }

      final inserted = await _insertRecord(_enrollmentsTable, {
        'groupId': desiredGroupId,
        'studentUId': studentUid,
        'studentName': row.studentName,
        'studentEmail': row.studentEmail,
        'enrolledAt': nowIso,
        'isActive': true,
        'validFrom': nowIso,
        'sourceImportId': importId,
        'createdAt': nowIso,
      });

      if (inserted != null) {
        activatedEnrollments++;
      }
    }

    if (importId.isNotEmpty) {
      await _updateRecord(
        _importsTable,
        where: {'_id': importId},
        set: {'status': 'completed'},
      );
    }

    if (activatedEnrollments == 0 && desiredByStudentEmail.isNotEmpty) {
      _log(
        'SYNC',
        'No se insertaron enrollments nuevos. Revisar columnas de la tabla enrollments.',
      );
    }

    return CsvSyncResult(
      createdGroups: createdGroups,
      activatedEnrollments: activatedEnrollments,
      closedEnrollments: closedEnrollments,
      totalRows: parsedRows.length,
    );
  }

  Future<EvaluationCycleData?> createEvaluationCycle({
    required String courseId,
    required String groupId,
    required String title,
    required String openedBy,
    required List<String> rubrics,
    DateTime? closesAt,
  }) async {
    final now = DateTime.now().toUtc();
    
    final inserted = await _insertRecord(_evaluationCyclesTable, {
      'courseId': courseId,
      'groupId': groupId,
      'title': title,
      'openedBy': openedBy,
      'openedAt': now.toIso8601String(),
      'closeAt': closesAt?.toUtc().toIso8601String(),
      'status': 'open',
      'criteria': {'rubrics': rubrics},
    });

    if (inserted == null) {
      return null;
    }

    return EvaluationCycleData(
      id: _asString(inserted['_id']),
      courseId: _asString(inserted['courseId']),
      groupId: _asString(inserted['groupId']),
      title: _asString(inserted['title']),
      status: _asString(inserted['status']),
      openedBy: _asString(inserted['openedBy']),
      openedAt: _parseDate(inserted['openedAt']),
      closesAt: inserted['closeAt'] == null
          ? null
          : _parseDate(inserted['closeAt']),
      rubrics: rubrics,
    );
  }

  Future<List<EvaluationCycleData>> getEvaluationCyclesByCourse(
    String courseId,
  ) async {
    final rows = await _readTable(
      _evaluationCyclesTable,
      filters: {'courseId': courseId},
    );

    return rows.map((row) => _mapRowToEvaluationCycle(row)).toList();
  }

  Future<List<EvaluationCycleData>> getEvaluationCyclesByGroup(
    String groupId,
  ) async {
    final rows = await _readTable(
      _evaluationCyclesTable,
      filters: {'groupId': groupId},
    );

    return rows.map((row) => _mapRowToEvaluationCycle(row)).toList();
  }

  EvaluationCycleData _mapRowToEvaluationCycle(Map<String, dynamic> row) {
    List<String> rubrics = [];
    final criteriaRaw = row['criteria'];
    if (criteriaRaw != null) {
      try {
        Map<String, dynamic> criteriaMap;
        if (criteriaRaw is String) {
          criteriaMap = jsonDecode(criteriaRaw);
        } else if (criteriaRaw is Map) {
          criteriaMap = Map<String, dynamic>.from(criteriaRaw);
        } else {
          criteriaMap = {};
        }
        if (criteriaMap['rubrics'] is List) {
          rubrics = (criteriaMap['rubrics'] as List)
              .map((e) => e.toString())
              .toList();
        }
      } catch (_) {
        rubrics = [];
      }
    }

    return EvaluationCycleData(
      id: _asString(row['_id']),
      courseId: _asString(row['courseId']),
      groupId: _asString(row['groupId']),
      title: _asString(row['title']),
      status: _asString(row['status']),
      openedBy: _asString(row['openedBy']),
      openedAt: _parseDate(row['openedAt']),
      closesAt: row['closeAt'] == null ? null : _parseDate(row['closeAt']),
      rubrics: rubrics,
    );
  }

  Future<List<PeerEvaluationData>> getSubmittedEvaluations({
    required String cycleId,
    required String evaluatorUid,
  }) async {
    final rowsByEvaluatorUid = await _readTable(
      _evaluationsTable,
      filters: {'cycleId': cycleId, 'evaluatorUid': evaluatorUid},
    );

    final rowsByEvaluatorUId = rowsByEvaluatorUid.isEmpty
        ? await _readTable(
            _evaluationsTable,
            filters: {'cycleId': cycleId, 'evaluatorUId': evaluatorUid},
          )
        : <Map<String, dynamic>>[];

    final unique = <String, Map<String, dynamic>>{};
    for (final row in [...rowsByEvaluatorUid, ...rowsByEvaluatorUId]) {
      final rowId = _asString(row['_id']);
      final key = rowId.isNotEmpty
          ? rowId
          : '${_asString(row['cycleId'])}-${_asString(row['evaluatorUid'])}-${_asString(row['evaluateeUid'])}';
      unique[key] = row;
    }

    return unique.values.map((row) => _mapRowToPeerEvaluation(row)).toList();
  }

  PeerEvaluationData _mapRowToPeerEvaluation(Map<String, dynamic> row) {
    List<int> scores = [];
    final resultsRaw = row['results'];
    if (resultsRaw != null) {
      try {
        Map<String, dynamic> resultsMap;
        if (resultsRaw is String) {
          resultsMap = jsonDecode(resultsRaw);
        } else if (resultsRaw is Map) {
          resultsMap = Map<String, dynamic>.from(resultsRaw);
        } else {
          resultsMap = {};
        }
        if (resultsMap['scores'] is List) {
          scores = (resultsMap['scores'] as List)
              .map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 0)
              .toList();
        }
      } catch (_) {
        scores = [];
      }
    }

    return PeerEvaluationData(
      id: _asString(row['_id']),
      cycleId: _asString(row['cycleId']),
      evaluatorUid: _asString(row['evaluatorUid']),
      evaluateeUid: _asString(row['evaluateeUid']),
      scores: scores,
      comments: _asString(row['comments']).isEmpty 
          ? null 
          : _asString(row['comments']),
      createdAt: _parseDate(row['createdAt']),
      updatedAt: row['updatedAt'] == null ? null : _parseDate(row['updatedAt']),
    );
  }

  Future<List<PendingEvaluationInfo>> getPendingEvaluationsForStudent({
    required String studentUid,
    required String studentEmail,
  }) async {
    final normalizedEmail = studentEmail.trim().toLowerCase();
    final normalizedUid = studentUid.trim();

    final enrollmentsByEmail = await _readTable(
      _enrollmentsTable,
      filters: {'studentEmail': normalizedEmail, 'isActive': true},
    );

    final enrollmentsByUid = <Map<String, dynamic>>[];
    if (normalizedUid.isNotEmpty) {
      final byUId = await _readTable(
        _enrollmentsTable,
        filters: {'studentUId': normalizedUid, 'isActive': true},
      );
      enrollmentsByUid.addAll(byUId);

      if (byUId.isEmpty) {
        final byUid = await _readTable(
          _enrollmentsTable,
          filters: {'studentUid': normalizedUid, 'isActive': true},
        );
        enrollmentsByUid.addAll(byUid);
      }
    }

    final enrollmentMap = <String, Map<String, dynamic>>{};
    for (final row in [...enrollmentsByEmail, ...enrollmentsByUid]) {
      final rowId = _asString(row['_id']);
      if (rowId.isNotEmpty) {
        enrollmentMap[rowId] = row;
      }
    }

    if (enrollmentMap.isEmpty) {
      return [];
    }

    final groupIds = enrollmentMap.values
        .map((e) => _asString(e['groupId']))
        .where((id) => id.isNotEmpty)
        .toSet();

    if (groupIds.isEmpty) {
      return [];
    }

    final groupsById = <String, Map<String, dynamic>>{};
    final categoryIds = <String>{};
    for (final groupId in groupIds) {
      final rows = await _readTable(_groupsTable, filters: {'_id': groupId});
      if (rows.isNotEmpty) {
        groupsById[groupId] = rows.first;
        final catId = _asString(rows.first['categoryId']);
        if (catId.isNotEmpty) {
          categoryIds.add(catId);
        }
      }
    }

    final categoriesById = <String, Map<String, dynamic>>{};
    for (final catId in categoryIds) {
      final rows = await _readTable(_categoriesTable, filters: {'_id': catId});
      if (rows.isNotEmpty) {
        categoriesById[catId] = rows.first;
      }
    }

    final openCycles = <EvaluationCycleData>[];
    for (final groupId in groupIds) {
      final cycleRows = await _readTable(
        _evaluationCyclesTable,
        filters: {'groupId': groupId, 'status': 'open'},
      );
      openCycles.addAll(cycleRows.map((r) => _mapRowToEvaluationCycle(r)));
    }

    if (openCycles.isEmpty) {
      return [];
    }

    final result = <PendingEvaluationInfo>[];

    for (final cycle in openCycles) {
      final groupId = cycle.groupId;
      final groupData = groupsById[groupId];
      
      if (groupData == null) {
        continue;
      }

      final categoryId = _asString(groupData['categoryId']);
      final category = categoriesById[categoryId];
      final categoryName = category != null 
          ? _asString(category['name']) 
          : '';

      final activeEnrollments = await _readActiveEnrollmentsByGroupIds([groupId]);

      final students = activeEnrollments.map((enrollment) {
        return StudentOverview(
          uid: _asString(enrollment['studentUId']).isNotEmpty
              ? _asString(enrollment['studentUId'])
              : _asString(enrollment['studentUid']),
          name: _asString(enrollment['studentName']),
          email: _asString(enrollment['studentEmail']),
          studentId: _asString(enrollment['studentId']),
        );
      }).toList();

      final peersToEvaluate = students.where((s) {
        final sEmail = s.email.trim().toLowerCase();
        final sUid = s.uid.trim();
        return sEmail != normalizedEmail && 
               (normalizedUid.isEmpty || sUid != normalizedUid);
      }).toList();

      if (peersToEvaluate.isEmpty) {
        continue;
      }

      final evaluatorKeys = <String>{};
      if (normalizedUid.isNotEmpty) {
        evaluatorKeys.add(normalizedUid);
      }
      if (normalizedEmail.isNotEmpty) {
        evaluatorKeys.add('email:$normalizedEmail');
        evaluatorKeys.add(normalizedEmail);
      }

      final submittedById = <String, PeerEvaluationData>{};
      for (final evaluatorKey in evaluatorKeys) {
        final submitted = await getSubmittedEvaluations(
          cycleId: cycle.id,
          evaluatorUid: evaluatorKey,
        );
        for (final item in submitted) {
          submittedById[item.id] = item;
        }
      }

      final alreadyEvaluatedPeerUids = <String>{};
      for (final peer in peersToEvaluate) {
        final peerUid = peer.uid.trim();
        final peerEmail = peer.email.trim().toLowerCase();
        final peerKeys = <String>{
          if (peerUid.isNotEmpty) peerUid,
          if (peerEmail.isNotEmpty) peerEmail,
          if (peerEmail.isNotEmpty) 'email:$peerEmail',
        };

        final matched = submittedById.values.any((evaluation) {
          final evaluateeUid = evaluation.evaluateeUid.trim().toLowerCase();
          return peerKeys.contains(evaluateeUid);
        });

        if (matched && peerUid.isNotEmpty) {
          alreadyEvaluatedPeerUids.add(peerUid);
        }
      }

      final groupCode = _asString(groupData['groupName']).isNotEmpty
          ? _asString(groupData['groupName'])
          : _asString(groupData['groupCode']);
      final displayName = _asString(groupData['displayName']).isNotEmpty
          ? _asString(groupData['displayName'])
          : (_asString(groupData['name']).isNotEmpty
                ? _asString(groupData['name'])
                : groupCode);

      final groupOverview = GroupOverview(
        id: groupId,
        code: groupCode,
        name: displayName,
        activeStudentsCount: students.length,
        students: students,
      );

      result.add(PendingEvaluationInfo(
        cycle: cycle,
        group: groupOverview,
        categoryName: categoryName,
        peersToEvaluate: peersToEvaluate,
        alreadyEvaluatedUids: alreadyEvaluatedPeerUids.toList(),
      ));
    }

    return result;
  }

  Future<bool> submitEvaluation({
    required String cycleId,
    required String evaluatorUid,
    required String evaluateeUid,
    required List<int> scores,
    String? comments,
  }) async {
    final cycles = await _readTable(
      _evaluationCyclesTable,
      filters: {'_id': cycleId},
    );
    if (cycles.isEmpty) {
      throw RobleException('El ciclo de coevaluación no existe');
    }

    final cycle = cycles.first;
    final status = _asString(cycle['status']).toLowerCase();
    if (status != 'open') {
      throw RobleException('El ciclo está cerrado');
    }

    final groupId = _asString(cycle['groupId']);
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final evaluatorEnrollment = await _findActiveStudentInGroups(
      studentUid: evaluatorUid,
      groupIds: [groupId],
    );
    final evaluateeEnrollment = await _findActiveStudentInGroups(
      studentUid: evaluateeUid,
      groupIds: [groupId],
    );

    final existing = await _readTable(
      _evaluationsTable,
      filters: {
        'cycleId': cycleId,
        'evaluatorUid': evaluatorUid,
        'evaluateeUid': evaluateeUid,
      },
    );

    final payload = {
      'cycleId': cycleId,
      'evaluatorUid': evaluatorUid,
      'evaluateeUid': evaluateeUid,
      'results': {'scores': scores},
      'comments': comments ?? '',
      'updatedAt': nowIso,
      'evaluatorGroupIdAtEval': evaluatorEnrollment.isEmpty
          ? groupId
          : _asString(evaluatorEnrollment.first['groupId']),
      'evaluateeGroupIdAtEval': evaluateeEnrollment.isEmpty
          ? groupId
          : _asString(evaluateeEnrollment.first['groupId']),
      'enrollmentIdAtEval': evaluateeEnrollment.isEmpty
          ? null
          : _asString(evaluateeEnrollment.first['_id']),
    };

    _log('SUBMIT_EVAL', 'Payload: ${jsonEncode(payload)}');

    if (existing.isNotEmpty) {
      return _updateRecord(
        _evaluationsTable,
        where: {'_id': _asString(existing.first['_id'])},
        set: payload,
      );
    }

    final inserted = await _insertRecord(_evaluationsTable, {
      ...payload,
      'createdAt': nowIso,
    });
    return inserted != null;
  }
}
