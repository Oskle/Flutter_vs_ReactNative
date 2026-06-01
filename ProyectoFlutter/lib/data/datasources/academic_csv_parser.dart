import 'package:csv/csv.dart';

class CsvStudentRow {
  final String categoryName;
  final String groupDisplayName;
  final String groupName;
  final String studentId;
  final String studentName;
  final String studentEmail;

  CsvStudentRow({
    required this.categoryName,
    required this.groupDisplayName,
    required this.groupName,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
  });
}

class AcademicCsvParser {
  String normalizeText(String value) {
    final trimmed = value.trim().toLowerCase();
    const replacements = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
    };

    var normalized = trimmed;
    replacements.forEach((key, replacement) {
      normalized = normalized.replaceAll(key, replacement);
    });

    return normalized.replaceAll(RegExp(r'\s+'), '');
  }

  String _asString(dynamic value) => value?.toString() ?? '';

  List<CsvStudentRow> parseRows(String csvContent) {
    final rows = csv.decode(csvContent);
    final parsed = <CsvStudentRow>[];

    for (final raw in rows) {
      if (raw.length < 7) {
        continue;
      }

      final categoryName = _asString(raw[0]).trim();
      final groupDisplayName = _asString(raw[1]).trim();
      final groupName = _asString(raw[2]).trim();

      final normalizedCategoryName = normalizeText(categoryName);
      final normalizedGroupName = normalizeText(groupName);

      if ((normalizedCategoryName == 'groupcategoryname' ||
              normalizedCategoryName == 'categoria') &&
          (normalizedGroupName == 'groupcode' ||
              normalizedGroupName == 'groupname')) {
        continue;
      }

      if (categoryName.toLowerCase().contains('categoria') &&
          groupName.toLowerCase().contains('group name')) {
        continue;
      }

      final possibleEmailA = _asString(raw[3]).trim();
      final possibleEmailB = raw.length > 7 ? _asString(raw[7]).trim() : '';
      final possibleEmailC = raw.length > 6 ? _asString(raw[6]).trim() : '';
      final studentEmail = possibleEmailB.contains('@')
          ? possibleEmailB
          : (possibleEmailA.contains('@') ? possibleEmailA : possibleEmailC);

      if (!studentEmail.contains('@')) {
        continue;
      }

      final col4 = raw.length > 4 ? _asString(raw[4]).trim() : '';
      final col5 = raw.length > 5 ? _asString(raw[5]).trim() : '';
      final col6 = raw.length > 6 ? _asString(raw[6]).trim() : '';

      String studentId = '';
      String studentName = '';

      if (RegExp(r'^\d+$').hasMatch(col4)) {
        studentId = col4;
        studentName = [col5, col6]
            .where((part) => part.trim().isNotEmpty)
            .join(' ')
            .trim();
      } else {
        final match = RegExp(r'^(\d+)\s*(.*)$').firstMatch(col4);
        if (match != null) {
          studentId = match.group(1) ?? '';
          final firstNames = (match.group(2) ?? '').trim();
          studentName = [firstNames, col5]
              .where((part) => part.trim().isNotEmpty)
              .join(' ')
              .trim();
        } else {
          studentName = [col4, col5]
              .where((part) => part.trim().isNotEmpty)
              .join(' ')
              .trim();
        }
      }

      parsed.add(
        CsvStudentRow(
          categoryName: categoryName,
          groupDisplayName: groupDisplayName,
          groupName: groupName,
          studentId: studentId,
          studentName: studentName,
          studentEmail: studentEmail.toLowerCase(),
        ),
      );
    }

    return parsed;
  }
}
