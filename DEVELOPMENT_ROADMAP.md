# 🎮 Underworld Tycoon - Development Roadmap

## 📊 **Estado Actual del Proyecto**
- ✅ Sistemas base implementados y funcionando
- ✅ Construcción de edificios operativa 
- ✅ Economía dual (dinero limpio/sucio)
- ✅ Ciclo día/noche con efectos
- ✅ Sistema de heat básico
- ✅ Interfaz funcional con notificaciones

---

## 🎯 **FASE 1: MECÁNICAS CRÍTICAS** 
*Prioridad: Alta - Hacen el juego completo y jugable*

### 🚨 Sistema de Raids y Consecuencias
- [ ] **Implementar raids automáticos cuando heat > umbral crítico**
  - [ ] Crear sistema de detección policial basado en heat acumulado
  - [ ] Raids que destruyen edificios aleatorios
  - [ ] Confiscación de dinero sucio durante raids
  - [ ] Cooldown entre raids para evitar spam
  - [ ] Notificaciones de advertencia antes de raids

- [ ] **Sistema de investigaciones activas**
  - [ ] Detectores investigando negocios específicos
  - [ ] Posibilidad de sobornar investigadores
  - [ ] Investigaciones que escalan con el tiempo
  - [ ] Evidence system (pruebas acumulándose)

### 💾 Sistema de Guardado
- [ ] **Save/Load básico**
  - [ ] Guardar estado completo del juego
  - [ ] Múltiples slots de guardado (3-5 slots)
  - [ ] Auto-guardado cada X minutos
  - [ ] Validación de integridad de archivos guardados
  - [ ] UI para gestionar partidas guardadas

### 🎯 Sistema de Objetivos/Misiones
- [ ] **Misiones dinámicas**
  - [ ] "Construir 5 bares en 10 días"
  - [ ] "Sobrevivir 3 raids consecutivos"
  - [ ] "Alcanzar $100K en dinero limpio"
  - [ ] "Mantener heat bajo 50% por 7 días"
  - [ ] Recompensas por completar misiones

- [ ] **Sistema de logros**
  - [ ] Logros desbloqueables con beneficios
  - [ ] "Primer Millón", "Superviviente", "Empresario Limpio"
  - [ ] Unlockeable content por logros
  - [ ] Estadísticas persistentes entre partidas

---

## 🎯 **FASE 2: PROFUNDIDAD ESTRATÉGICA**
*Prioridad: Media - Añaden complejidad y rejugabilidad*

### 🗳️ Sistema Electoral
- [ ] **Ciclo electoral cada 4 años**
  - [ ] Timer de elecciones visible en UI
  - [ ] Gastos de campaña obligatorios
  - [ ] Sistema de aprobación pública (0-100%)
  - [ ] Game Over si pierdes elecciones
  - [ ] Eventos que afectan aprobación

- [ ] **Mecánicas electorales**
  - [ ] Promesas de campaña que debes cumplir
  - [ ] Debates públicos (mini-juegos)
  - [ ] Escándalos que reducen aprobación
  - [ ] Inversión en publicidad vs servicios públicos

### 🏛️ Gestión Municipal Avanzada
- [ ] **Efectos reales de inversiones**
  - [ ] Inversión en policía → reduce heat más efectivamente
  - [ ] Inversión en transporte → aumenta ingresos de negocios
  - [ ] Inversión en obras públicas → aumenta aprobación
  - [ ] Balances presupuestarios visibles

- [ ] **Eventos aleatorios de ciudad**
  - [ ] Apagones que afectan negocios
  - [ ] Huelgas que requieren negociación
  - [ ] Desastres naturales que cuestan dinero
  - [ ] Oportunidades de inversión especiales

### 💰 Economía Avanzada
- [ ] **Métodos de lavado múltiples**
  - [ ] Bancos offshore (mayor capacidad, mayor riesgo)
  - [ ] Empresas fantasma (lavado lento pero seguro)
  - [ ] Inversiones inmobiliarias legales
  - [ ] Casino propio para lavado masivo

- [ ] **Mercados financieros**
  - [ ] Fluctuaciones de precios en materiales
  - [ ] Inversiones en bolsa con dinero limpio
  - [ ] Préstamos bancarios para expansión
  - [ ] Competencia con otros "empresarios"

### 🏢 Negocios Avanzados
- [ ] **Nuevos tipos de negocio**
  - [ ] Casino (alto income, altísimo heat)
  - [ ] Red de prostitución (income medio, heat alto)
  - [ ] Tráfico de armas (income por eventos)
  - [ ] Laboratorios de drogas (supply chain complejo)

- [ ] **Cadenas de negocio**
  - [ ] Workshop → Distribution Center → Retail
  - [ ] Materias primas → Procesamiento → Venta
  - [ ] Bonificaciones por cadenas completas
  - [ ] Vulnerabilidades en cadenas (raids interrumpen flujo)

---

## 🎯 **FASE 3: POLISH Y EXPERIENCIA**
*Prioridad: Baja - Mejoran la experiencia pero no son esenciales*

### 🎨 Mejoras Visuales
- [ ] **Animaciones de transición**
  - [ ] Animaciones de construcción de edificios
  - [ ] Transiciones día/noche suaves
  - [ ] Efectos de raids (explosiones, humo)
  - [ ] Floating damage/income numbers mejorados

- [ ] **Efectos visuales avanzados**
  - [ ] Partículas para efectos especiales
  - [ ] Shader effects para heat visual
  - [ ] Dynamic lighting para día/noche
  - [ ] Weather effects (lluvia afecta income)

### 🔊 Sistema de Audio
- [ ] **Música adaptativa**
  - [ ] Música tensa durante raids
  - [ ] Música tranquila durante día
  - [ ] Música de suspense con heat alto
  - [ ] Jingles para logros/eventos importantes

- [ ] **Efectos de sonido**
  - [ ] SFX para clicks, construcción, dinero
  - [ ] Ambient sounds de ciudad
  - [ ] Sirenas durante raids
  - [ ] Voice-over para notificaciones críticas

### 🎮 UX/UI Improvements
- [ ] **Interface modernizada**
  - [ ] Dashboard con gráficos de progreso
  - [ ] Tooltips informativos en todo
  - [ ] Drag & drop para algunas acciones
  - [ ] Temas de color/skins desbloqueables

- [ ] **Accessibility features**
  - [ ] Subtítulos para audio
  - [ ] Colorblind-friendly palette
  - [ ] Keyboard shortcuts para todo
  - [ ] Text scaling options

### 📚 Tutorial y Onboarding
- [ ] **Tutorial interactivo completo**
  - [ ] Guided tour de todas las mecánicas
  - [ ] Practice mode sin consecuencias
  - [ ] Contextual tips durante gameplay
  - [ ] Video tutorials opcionales

- [ ] **Help system**
  - [ ] Manual en-game consultable
  - [ ] FAQ integrada
  - [ ] Tips context-sensitive
  - [ ] Community wiki integration

---

## 🎯 **FASE 4: CONTENIDO EXTENDIDO**
*Prioridad: Futura - Expandir después del lanzamiento*

### 🌍 Expansión de Mundo
- [ ] **Múltiples ciudades**
  - [ ] Diferentes layouts de distrito
  - [ ] Características únicas por ciudad
  - [ ] Travel entre ciudades
  - [ ] Networks criminales inter-ciudad

### 🧩 Modos de Juego
- [ ] **Sandbox mode** (recursos infinitos)
- [ ] **Challenge mode** (objetivos específicos)
- [ ] **Speed run mode** (completar en tiempo límite)
- [ ] **Hardcore mode** (una sola vida, sin saves)

### 👥 Multijugador (Futuro Lejano)
- [ ] **Co-op local** (2 jugadores, 1 ciudad)
- [ ] **Competitivo async** (leaderboards globales)
- [ ] **Trading system** (intercambio de recursos)

---

## 📈 **MÉTRICAS DE PROGRESO**

### Fase 1: ⏳ **0/15 completadas**
- Raids: 0/6 tareas
- Save/Load: 0/5 tareas  
- Objetivos: 0/4 tareas

### Fase 2: ⏳ **0/20 completadas**
- Electoral: 0/8 tareas
- Municipal: 0/6 tareas
- Economía: 0/6 tareas

### Fase 3: ⏳ **0/18 completadas**
- Visual: 0/8 tareas
- Audio: 0/4 tareas
- UX: 0/6 tareas

### **TOTAL PROGRESO: 0/53 tareas completadas (0%)**

---

## 🚀 **PRÓXIMOS PASOS SUGERIDOS**

1. **Implementar sistema de raids** (impacto inmediato en gameplay)
2. **Crear save/load básico** (essential para testing extenso)
3. **Añadir primeras misiones** (da dirección al jugador)
4. **Implementar efectos de inversiones municipales** (hace decisiones más meaningful)

---

*Última actualización: $(date)*  
*Versión actual: MVP Funcional*