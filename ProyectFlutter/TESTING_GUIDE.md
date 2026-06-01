# 🔧 Guía de Testing - Homepage Dinámico

## Para cambiar entre Dashboard de Profesor y Estudiante

### Opción 1: Cambio en el Controller (Recomendado para Testing)

Abre: `lib/presentation/home/controllers/home_controller.dart`

En el método `loadCurrentUser()` (línea ~16), busca:

```dart
loadCurrentUser() async {
  try {
    isLoading(true);
    error('');

    // TODO: Get current user from AuthController or API
    // For now, using mock data
    currentUser.value = UserModel(
      id: '1',
      email: 'usuario@ejemplo.com',
      name: 'Juan Pérez',
      role: UserRole.student,  // ← CAMBIAR AQUÍ
      profileImage: null,
      department: 'Ingeniería en Sistemas',
    );
```

**Cambia `UserRole.student` a `UserRole.teacher` para ver el dashboard de profesor:**

```dart
role: UserRole.teacher,  // Profesor
// o
role: UserRole.student,  // Estudiante (por defecto)
```

## 📊 Comparación de Dashboards

| Aspecto | Profesor | Estudiante |
|---------|----------|-----------|
| **Color Principal** | Índigo (#6366F1) | Verde (#10B981) |
| **Gradiente AppBar** | Índigo a Púrpura | Verde a Verde oscuro |
| **Banner Title** | "Bienvenido, [Nombre]" | "Hola, [Nombre]" |
| **Subtitle** | "Panel de control de profesor" | "Tu panel académico" |
| **Stat 1** | 12 Cursos | Promedio (3.8) |
| **Stat 2** | 345 Estudiantes | Participación (92%) |
| **Stat 3** | 8 Pendientes | Tareas (18/20) |
| **Sección 2** | Mis Cursos | Desempeño Académico |
| **Sección 3** | Evaluaciones Pendientes | Mis Cursos |
| **Sección 4** | Acciones Rápidas | Evaluaciones Pendientes |
| **Sección 5** | - | Retroalimentación Reciente |

## 🎯 Archivos Clave

1. **Controllers**:
   - `lib/presentation/home/controllers/home_controller.dart` - Lógica principal

2. **Views**:
   - `lib/presentation/home/views/home_view.dart` - Contenedor que decide cual vista mostrar
   - `lib/presentation/home/views/teacher_home_view.dart` - Dashboard profesor
   - `lib/presentation/home/views/student_home_view.dart` - Dashboard estudiante

3. **Modelos**:
   - `lib/domain/entities/user.dart` - Entidad User con enum UserRole
   - `lib/data/models/user_model.dart` - Modelo serializable

## 🚀 Flujo de la Aplicación

```
main.dart (GetMaterialApp)
    ↓
HomeBinding (inyecta HomeController)
    ↓
HomeView (contenedor principal)
    ↓
    ├─→ TeacherHomeView (si role == UserRole.teacher)
    └─→ StudentHomeView (si role == UserRole.student)
```

## 🔍 Cómo Funciona GetX

1. **HomeController** se inicializa automáticamente en el binding
2. El controller carga los datos del usuario en `onInit()`
3. **HomeView** se redibuja automáticamente cuando cambian los datos (Obx)
4. Dependiendo del rol, muestra una vista u otra
5. Ambas vistas llaman a `Get.find<HomeController>()` para acceder al controller

## 🛠️ Hot Reload Funciona

Cuando cambies el rol en el controller y guardes (Ctrl+S):
1. Flutter hace hot rebuild
2. El controller vuelve a cargar los datos
3. La vista se actualiza automáticamente
4. ¡Ves el dashboard diferente sin reiniciar!

## ✨ Próximas Integraciones

Cuando integres con backend:

```dart
// Reemplaza el TODO con:
final user = await authRepository.getCurrentUser();
currentUser.value = user;
```

## 📝 Notas de Diseño

- **Coherencia visual**: Ambos dashboards siguen Material Design 3
- **Colores por rol**: Diferencia visual clara entre profesor y estudiante
- **Responsive**: Funciona en móvil, tablet y web
- **Datos mock**: Listos para ser reemplazados con datos reales

---

¿Necesitas ayuda para integrar datos reales del backend?
