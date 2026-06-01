import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/dashboard/controllers/dashboard_controller.dart';
import 'package:coeval/domain/entities/dashboard_stats.dart';

class MockDashboardController extends GetxService with Mock implements DashboardController {}
