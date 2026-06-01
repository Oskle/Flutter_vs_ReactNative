# 🎓 Homepage Dinámico - CoevaL

## 📋 Descripción

Se ha creado un homepage completamente dinámico para la aplicación CoevaL que se adapta automáticamente dependiendo del rol del usuario (Profesor o Estudiante).

## 🏗️ Estructura Creada

```
lib/presentation/home/
├── controllers/
│   └── home_controller.dart      # Lógica del homepage con GetX
├── views/
│   ├── home_view.dart            # Vista principal (contenedor dinámico)
│   ├── teacher_home_view.dart    # Dashboard de profesor
│   └── student_home_view.dart    # Dashboard de estudiante
└── bindings/
    └── home_binding.dart          # Inyección de dependencias

lib/domain/entities/
└── user.dart                      # Modelo de usuario con enum de roles

lib/data/models/
└── user_model.dart               # Modelo de datos con serialización

lib/main.dart                      # App configurado con GetX
```

## 🎨 Características

### Dashboard de Profesor 🧑‍🏫
- ✅ Banner de bienvenida personalizado con gradiente azul
- 📊 Estadísticas rápidas (Cursos, Estudiantes, Evaluaciones Pendientes)
- 📚 Lista de cursos con información de estudiantes
- 🚨 Evaluaciones pendientes con prioridades
- ⚡ Acciones rápidas (Nueva Evaluación, Reportes)
- 👤 Menú de perfil con opción de logout

### Dashboard de Estudiante 👨‍🎓
- ✅ Banner de bienvenida personalizado con gradiente verde
- 📈 Métricas académicas (Promedio, Participación, Tareas)
- 📚 Lista de cursos con calificaciones codificadas por color
- 📋 Evaluaciones pendientes con botones de acción
- 💬 Retroalimentación reciente de compañeros
- 👤 Menú de perfil con opción de logout

## 🔄 Cómo Cambiar Entre Vistas (para Testing)

En el archivo `lib/presentation/home/controllers/home_controller.dart`, en el método `loadCurrentUser()`, cambia el rol del usuario (línea ~23):

```dart
// Para ver el dashboard de ESTUDIANTE (actual):
currentUser.value = UserModel(
  id: '1',
  email: 'usuario@ejemplo.com',
  name: 'Juan Pérez',
  role: UserRole.student,  // ← Estudiante
  // ...
);

// Para ver el dashboard de PROFESOR, cambia a:
role: UserRole.teacher,  // ← Profesor
```

## 🎯 Colores Personalizados

- **Profesor**: Gradiente Índigo/Púrpura (`#6366F1` a `#8B5CF6`)
- **Estudiante**: Gradiente Verde (`#10B981` a `#059669`)
- Cada rol tiene su paleta de colores distintiva en AppBar y componentes

## 🛠️ Tecnologías Utilizadas

- **GetX**: State Management y Navigation
- **Flutter**: Framework principal
- **Dart**: Lenguaje de programación
- **Material Design 3**: Diseño de componentes

## 📱 Componentes Reutilizables

El código define widgets reutilizables privados que pueden extraerse:
- `_buildStatCard()`: Tarjetas de estadísticas
- `_buildSectionTitle()`: Títulos de secciones
- `_buildCoursesList()`: Listas de cursos
- Y más...

## 🚀 Próximas Mejoras

1. **Integrar datos reales**:
   - Conectar con API backend
   - Cargar datos del usuario autenticado

2. **Datos dinámicos**:
   - Reemplazar datos mock con stream/observables
   - Notificaciones en tiempo real

3. **Navegación**:
   - Crear rutas para cada sección
   - Implementar deep linking

4. **Animaciones**:
   - Agregar transiciones suaves
   - Efectos de carga más atractivos

5. **Temas**:
   - Soporte para dark mode
   - Personalización de colores por usuario

## ✅ Checklist de Testing

- [ ] Verificar que el dashboard de profesor se carga correctamente
- [ ] Verificar que el dashboard de estudiante se carga correctamente
- [ ] Probar que los botones y menús son interactivos
- [ ] Verificar responsive design en diferentes tamaños
- [ ] Probar la opción de logout
- [ ] Cambiar rol en el controller y verificar cambio dinámico

---

**Creado con ❤️ para CoevaL**
