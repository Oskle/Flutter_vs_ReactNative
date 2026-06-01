# Reporte Técnico Comparativo: Flutter vs. React Native (Expo) en CoEval

Este documento presenta un análisis comparativo y cuantitativo detallado del desarrollo, rendimiento y arquitectura de la plataforma *CoEval* (gestión de usuarios, cursos y dashboards educativos), implementada de manera independiente en dos de los frameworks multiplataforma más robustos del mercado: *Flutter (Dart)* y *React Native con Expo (TypeScript)*.

El objetivo fundamental es evaluar de forma empírica y cualitativa la eficiencia de ambas tecnologías bajo un mismo conjunto de requerimientos de negocio y un patrón arquitectónico homogéneo.

---

## 1. Arquitectura de Software e Implementación

Para asegurar la validez del benchmark, ambas aplicaciones se desarrollaron bajo los lineamientos de *Clean Architecture*, aislando de forma estricta las reglas de negocio de los detalles de infraestructura.

### Estructura de Capas
Ambas bases de código se organizaron en una estructura de tres niveles principales:
* *Domain:* Contiene las entidades esenciales de CoEval, las abstracciones de los repositorios y la definición de los casos de uso nativos. Es completamente agnóstica de frameworks o librerías externas.
* *Data:* Implementación concreta de los repositorios y datasources. Aquí se encuentra el cliente HTTP encargado de mapear la información desde el endpoint remoto (sistema "Roble") hacia modelos de datos internos, incorporando políticas de caché local.
* *Presentation:* Controladores de estado, configuraciones de navegación y el árbol de componentes/widgets que renderizan la interfaz del estudiante, incluyendo vistas como el Login, Dashboard de Cursos, Detalle de Evaluaciones por categoryId y la pantalla de diagnósticos.

### Comparativa Tecnológica de Infraestructura

| Componente | Implementación en Flutter | Implementación en React Native (Expo) |
| :--- | :--- | :--- |
| *Lenguaje* | Dart 3.x (Compilación AOT/JIT) | TypeScript 5.x (Tipado estático sobre JS) |
| *Manejo de Estado* | *GetX* (Controladores reactivos y DI acoplado) | *React Context API* (AuthContext, StudentContext) |
| *Enrutamiento* | GetMaterialApp (Sistema basado en rutas nombradas) | *React Navigation* (native-stack + bottom-tabs) |
| *Cliente de Red* | package:http con wrapper personalizado _timed | axios complementado con interceptores de solicitud |

---

## 2. Metodología de Instrumentación y Telemetría

Para evitar sesgos subjetivos, se integró un sistema de telemetría directamente en el ciclo de vida de la red y las interfaces de usuario de ambas aplicaciones:

1.  *Monitoreo HTTP In-App:* Se modificó la capa de red (roble_datasource) mediante envoltorios de tiempo en Flutter e interceptores asíncronos en React Native. Cada petición saliente hacia el endpoint de la tabla users registra la marca de tiempo exacta en milisegundos (_requestTimings / requestTimings) antes de ser procesada por la capa de UI.
2.  *Diagnostics UI:* Se programó una vista dedicada (/diagnostics) en ambos sistemas. Esta interfaz expone métricas operacionales como el contador acumulado de peticiones, la latencia promedio en milisegundos y un desglose histórico de cada RTT (Round Trip Time), permitiendo disparar ráfagas de prueba bajo demanda.
3.  *Auditoría de Red Externa:* Se diseñó y ejecutó un script automatizado en PowerShell que disparó un muestreo de $N=20$ solicitudes consecutivas hacia el endpoint de la base de datos "Roble" (https://roble-api.openlab.uninorte.edu.co/database/read?tableName=users). Esto permitió aislar y cuantificar la latencia inherente del servidor y el canal de red.

---

## 3. Matriz de Métricas de Rendimiento (Benchmark)

La siguiente tabla consolida las mediciones técnicas reales recopiladas en los entornos de desarrollo, compilación y pruebas locales:

| Dimensión de Rendimiento | Flutter (Dart) | React Native (Expo) | Origen del Dato |
| :--- | :--- | :--- | :--- |
| *Tamaño Final del APK (Release)* | *52.41 MB* | *58.00 MB* | Medición de archivos binarios finales  |
| *Tiempo de Arranque (Cold Start)* | *0.90 s* | *2.20 s* | Tiempo promedio de ejecución en frío  |
| *Tiempo de Compilación Release* | *24.05 s* | *3.50 min* | Medido localmente en máquina de desarrollo |
| *Latencia de Red Promedio (API)* | *195.65 ms* | *195.65 ms* | ]Muestreo por script de red externo ($N=20$)  |
| *Eficiencia de Recarga de Código* | < 1.00 s | 0.3 - 1.5 s | Latencias de respuesta de recarga en tiempo real  |

### Análisis Detallado de los Resultados

#### A. Peso del Binario (APK Release)
El ejecutable compilado en Flutter arrojó un peso de *52.41 MB* ejecutando el comando nativo de Gradle. En el ecosistema de React Native con Expo (Managed Workflow), el peso final se situó en *58.00 MB*.
La variación se fundamenta en sus respectivos esquemas de empaquetado: Expo incluye un runtime nativo preconfigurado con las librerías del SDK principal necesarias para dar soporte a APIs nativas comunes (como almacenamiento en caché y contextos seguros), elevando el piso del archivo base. Flutter, en contraposición, utiliza su compilador AOT (Ahead-of-Time) para remover agresivamente código muerto (tree shaking), aislando exclusivamente los elementos requeridos por el árbol de widgets nativo.

#### B. Ciclo de Arranque (Cold Start)
Los registros de inicialización en frío reflejan *0.9 segundos* para Flutter y *2.2 segundos* para React Native con Expo.
La diferencia es una consecuencia directa de la arquitectura de ejecución de bajo nivel. Flutter se compila directamente a código binario nativo (ARM), reduciendo el paso de inicialización a un puente gráfico directo con el sistema operativo. React Native, en cambio, debe arrancar primero el motor JavaScript Hermes, cargar el bundle sintáctico a memoria RAM, establecer el canal de comunicación JSI (JavaScript Interface) y mapear dinámicamente dichos componentes hacia vistas nativas de Android, lo que incrementa el retardo inicial.

#### C. Pipelines de Compilación y Tiempos de Build
El comando flutter build apk --release finalizó el empaquetado completo en un tiempo óptimo de *24.05 segundos* empleando Measure-Command. Por su parte, la compilación de React Native mediante el proceso local de Bare-Gradle (assembleRelease) tomó un promedio de *3.5 minutos*. 
Esto expone que la cadena de herramientas de Flutter procesa de manera más eficiente la optimización de código fuente a binario sin requerir configuraciones previas complebas, mientras que el ecosistema de Android/Gradle en React Native arrastra una carga superior al tener que enlazar dependencias en C++ (vía NDK), módulos NPM nativos y orquestar múltiples daemons concurrentes de Gradle.

#### D. Comportamiento y Análisis de Latencia de Red
El script automatizado arrojó una latencia promedio de *195.65 ms*, con un comportamiento de red estable que registró un mínimo de 163 ms y un pico aislado de 747 ms bajo congestión estándar de red. 
Dado que ambas aplicaciones fueron probadas bajo la misma interfaz de red local hacia el endpoint de "Roble", su desempeño neto es idéntico (~196 ms). Esto confirma que las abstracciones asíncronas de alto nivel (package:http en Dart y axios en TypeScript) no introducen un cuello de botella artificial y delegan el tráfico de red de forma transparente a los sockets del Kernel de Android.

---

## 4. Gestión de Operaciones CRUD en Memoria RAM

Cumpliendo con los requerimientos técnicos fijados para CoEval, los datos recuperados del API no utilizan persistencia local en base de datos (SQLite/Room), sino que se mantienen estrictamente en memoria RAM a través de las capas de negocio. Las mutaciones (Creación, Actualización y Eliminación) se ejecutan de manera simulada localmente.

### Implementación en Flutter (GetX)
La reactividad de GetX permitió implementar el flujo CRUD con un enfoque puramente imperativo y reactivo. Las listas dinámicas de cursos y evaluaciones se tiparon utilizando variables observables (RxList<Evaluation>).
* *Creación/Actualización:* Los controladores GetX interceptan los datos de la UI y alteran los índices de la lista en memoria empleando métodos reactivos. Al mutar el estado de la lista observable, los widgets vinculados mediante un contenedor Obx se redibujan de forma quirúrgica en la interfaz, garantizando un scroll fluido.
* *Eliminación:* Se remueve el objeto de la lista en memoria RAM instantáneamente. GetX notifica a los stream listeners de forma síncrona, eliminando el elemento visual del listado sin necesidad de reconstruir la pantalla entera.

### Implementación en React Native (Context API)
En React Native, el CRUD en memoria se gestiona a través de los Hooks nativos useState y useReducer encapsulados dentro del árbol del StudentContext.
* *Creación/Actualización:* Para respetar el principio de inmutabilidad de React, cada operación CRUD requiere clonar el estado previo de la lista en memoria RAM (ej. setEvaluations(prev => [...prev, newEvaluation])). 
* *Eliminación:* Se aplica un filtro inmutable (.filter()) sobre el arreglo en memoria RAM. Al despachar el nuevo estado, React propaga el cambio hacia abajo en el árbol de componentes. Esto exige memorizar componentes de listas dinámicas utilizando React.memo o controlar el renderizado de la lista nativa (FlatList) para mitigar picos de uso de CPU que puedan degradar la fluidez visual de la app.

---

## 5. Análisis Cualitativo: Experiencia de Desarrollo

Esta sección evalúa el comportamiento ergonómico y técnico de los dos frameworks desde la perspectiva práctica de la implementación de flujos reales de UI y lógica corporativa.

### A. Modularidad y Manejo de Dependencias
* *Flutter (GetX):* Ofrece una experiencia unificada de desarrollo. Al resolver la inyección de dependencias en una sola línea de código sin contexto global (Get.put()), GetX facilitó la instanciación directa de los casos de uso y repositorios de Clean Architecture, reduciendo el código repetitivo de forma drástica.
* *React Native (Context API):* Provee una separación de responsabilidades limpia a nivel conceptual utilizando el flujo unidireccional tradicional de React. Sin embargo, conforme se añadieron más módulos (Auth, Students, Teachers), el árbol de componentes raíz en App.tsx comenzó a poblarse de envoltorios de contextos (Context Nesting), incrementando la complejidad sintáctica en comparación con la inyección desacoplada de Flutter.

### B. Productividad de Lenguaje: Dart vs. TypeScript
* *Dart* demostró ser un lenguaje altamente robusto para la estructuración de layouts. Su tipado estático estricto y la inmutabilidad mandatoria en los parámetros de los Widgets previenen errores en tiempo de diseño. El mecanismo *Hot Reload* (<1.0 s) demostró una consistencia superior, reteniendo el estado de las variables y formularios de evaluaciones en memoria RAM aun cuando se modificaba el diseño visual de la interfaz de usuario.
* *TypeScript* brilla por su extrema flexibilidad y velocidad de codificación. El tipado dinámico-estático agiliza el modelado de las respuestas HTTP provenientes de Axios mediante interfaces directas. El sistema *Fast Refresh* es sumamente veloz para cambios lógicos (0.3 s - 1.5 s), aunque tiende a limpiar el estado en memoria RAM con mayor frecuencia que Flutter si el desarrollador altera la estructura de los Hooks del componente durante la recarga.

### C. Experiencia en Interfaz de Usuario y Fluidez Visual
* *Flutter:* Al pintar pixel por pixel directamente sobre su propio lienzo gráfico utilizando su motor nativo, ofrece un control absoluto sobre el refresco de la UI. El scroll de las listas dinámicas de evaluaciones mantiene una tasa de cuadros estable y fluida, sin importar la complejidad del árbol de widgets interno.
* *React Native:* Expo delega el renderizado directamente a las vistas nativas de la plataforma Android. Las listas dinámicas se sienten completamente integradas con el sistema operativo y responden de forma natural a las físicas del hilo de UI nativo, siempre y cuando se optimice correctamente la reconciliación del DOM virtual de React.
