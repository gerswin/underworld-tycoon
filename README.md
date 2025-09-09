# 🏙️ Underworld Tycoon

> Simulador de gestión urbana con economía dual. Mantén la ciudad funcionando mientras construyes tu imperio en las sombras.

## 🎮 Concepto

Eres el alcalde de una ciudad. Tu objetivo es mantener los servicios públicos para conservar legitimidad, mientras te enriqueces mediante una red de negocios ilícitos y tapaderas.

### Bucle de Juego Principal

1. **Gestión Legal**: Administra servicios públicos (basura, transporte, policía)
2. **Red Criminal**: Construye bares, clubes nocturnos y talleres clandestinos
3. **Lavado de Dinero**: Usa ONGs pantalla y contratos públicos
4. **Control del Heat**: Evita auditorías, prensa hostil y facciones rivales
5. **Elecciones**: Mantén alta aprobación y baja sospecha para ganar

## 🛠️ Stack Tecnológico

- **Motor**: Godot 4.3+
- **Lenguaje**: GDScript
- **Arquitectura**: Singletons para sistemas core
- **Datos**: JSON para configuración de negocios y eventos

## 📁 Estructura del Proyecto

```
underworld-tycoon/
├── src/
│   ├── scenes/          # Escenas de Godot (.tscn)
│   ├── scripts/
│   │   ├── singletons/   # Sistemas globales (Economy, CitySim, etc.)
│   │   ├── buildings/    # Lógica de negocios y construcciones
│   │   ├── ui/          # Controladores de UI
│   │   └── systems/     # Sistemas de juego (heat, elecciones, etc.)
│   └── assets/
│       ├── sprites/     # Gráficos del juego
│       ├── ui/         # Elementos de interfaz
│       ├── fonts/      # Tipografías
│       └── data/       # JSONs de configuración
└── docs/               # Documentación adicional
```

## 🎯 Sistemas Principales

### 1. Economía Dual
- **Dinero Limpio**: Presupuesto oficial de la ciudad
- **Dinero Sucio**: Ganancias de negocios ilícitos
- **Lavado**: Conversión limitada a través de ONGs y contratos

### 2. Negocios Tapadera
| Tipo | Ingresos | Heat | Especial |
|------|----------|------|----------|
| Bar | Bajo | Bajo | Distribuye productos del taller |
| Club Nocturno | Alto (noche) | Alto | x2 ingresos de noche |
| Taller Clandestino | Medio | Medio | Produce insumos ilegales |

### 3. Sistema de Heat
- **Aumenta por**: Sobrefacturación, violencia en clubes, redadas fallidas
- **Disminuye con**: Sobornos, control institucional, tiempo
- **Umbral crítico**: >70% activa redadas y auditorías

### 4. Servicios Públicos
- Basura, Transporte, Policía, Obras Públicas
- Afectan directamente la legitimidad y aprobación ciudadana
- Requieren presupuesto del dinero limpio

## 🚀 Quick Start

### Requisitos
- Godot 4.3 o superior
- Git

### Instalación
```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/underworld-tycoon.git
cd underworld-tycoon

# Abrir con Godot
# File -> Import -> Seleccionar project.godot
```

### Controles (MVP)
- **Click Izquierdo**: Seleccionar/Construir
- **Click Derecho**: Cancelar
- **WASD/Flechas**: Mover cámara
- **Scroll**: Zoom
- **Espacio**: Pausar
- **Tab**: Cambiar entre panel legal/ilegal

## 📊 Fórmulas Base

```gdscript
# Ingreso de Bar
ingreso = base * demanda_distrito * (1 - heat_local * 0.1)

# Ingreso de Club Nocturno
ingreso = base * (2 if es_noche else 1) * multiplicador_evento
heat += 3 # por ciclo

# Aprobación Ciudadana
aprobacion = servicios_calidad * 0.6 + economia_local * 0.3 - escandalos * 0.1

# Condición de Victoria (Elecciones)
victoria = aprobacion > 50 and heat < 70
```

## 🎮 MVP - Sprint 1

### Características
- [ ] Mapa con 4 distritos (TileMap)
- [ ] Construcción de bares y clubes
- [ ] Ciclo día/noche (afecta ingresos)
- [ ] Sistema de heat global
- [ ] Redadas automáticas al superar umbral
- [ ] HUD con indicadores principales

### Entregable
Versión jugable donde puedas:
1. Colocar negocios en el mapa
2. Ver generación de ingresos
3. Experimentar redadas cuando el heat sube

## 🗓️ Roadmap

### Sprint 2
- Sistema de talleres clandestinos
- ONGs para lavado de dinero
- Panel de servicios públicos
- Primera elección (minuto 20)
- Eventos aleatorios (festival, crisis, redada dirigida)

### Sprint 3
- Facciones criminales rivales
- Sistema de sobornos
- Cadenas de producción
- Múltiples finales

## 🤝 Contribuir

1. Fork el proyecto
2. Crea tu feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add: nueva característica'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📝 Licencia

Este proyecto está bajo licencia MIT. Ver `LICENSE` para más detalles.

## 🎨 Créditos

- **Diseño y Desarrollo**: [Tu nombre]
- **Motor**: Godot Engine
- **Assets**: [Pendiente]

---

*"El poder corrompe, pero el poder absoluto es bastante entretenido"*