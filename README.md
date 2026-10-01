# 🛒 SICOTI - Sistema de Control de Inventario para Tienda Minorista

![Version](https://img.shields.io/badge/version-1.0.0--alpha-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Status](https://img.shields.io/badge/status-en_desarrollo-orange)

**SICOTI** es una solución tecnológica integral orientada a automatizar y optimizar la gestión de inventario, la facturación en el punto de venta (POS) y el monitoreo de stock en tiempo real para microempresas y tiendas minoristas. El sistema está diseñado bajo una arquitectura ágil, de alta disponibilidad y segura para garantizar respuestas ágiles en caja.

---

## 📌 Tabla de Contenidos

- [Características Principales](#-características-principales)
- [Arquitectura y Tecnologías](#-arquitectura-y-tecnologías)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Prerrequisitos](#-prerrequisitos)
- [Instalación y Configuración Local](#-instalación-y-configuración-local)
- [Base de Datos](#-base-de-datos)
- [Nota Técnica de Versión](#-nota-técnica-de-versión)
- [Datos del Proyecto Académico](#-datos-del-proyecto-académico)
- [Licencia](#-licencia)

---

## ✨ Características Principales

- **Gestión de Catálogo y Productos (RF-001):** Registro y edición de mercancía con datos clave (SKU, código de barras, nombre, categoría, costo, precio de venta y umbral de stock mínimo).
- **Punto de Venta POS e Integración Hardware (RF-002):** Lectura e integración directa con escáneres de códigos de barras USB/inalámbricos para descontar existencias automáticamente.
- **Alertas de Stock Mínimo (RF-003):** Indicador visual en tiempo real en la pantalla del cajero y almacenista cuando un producto alcanza su nivel crítico ($stock\_actual \le stock\_minimo$).
- **Filtros por Categoría (RF-004):** Búsqueda ágil y visualización organizada por categorías de productos.
- **Facturación Transaccional (RF-006):** Procesamiento de cobros, cálculo de impuestos (ITBIS) y generación de recibos/comprobantes digitales únicos.
- **Anulación con Reversión de Inventario (RF-007):** Reingreso automático de productos al stock disponible en caso de anulaciones autorizadas.

---

## 🛠️ Arquitectura y Tecnologías

El sistema sigue el principio de **Separación de Responsabilidades (SoC)** bajo una **Arquitectura Cliente-Servidor Desacoplada** estructurada en tres capas:

| Capa | Tecnología | Descripción |
| :--- | :--- | :--- |
| **Frontend (Presentación)** | React.js / HTML5 / CSS3 | Interfaz de usuario intuitiva (POS) optimizada para usabilidad y tiempos de respuesta subsegundo ($t < 1\text{s}$). |
| **Backend (Lógica)** | Node.js / Express.js | API RESTful que procesa las reglas de negocio, validación de existencias y transacciones. |
| **Persistencia (Datos)** | MySQL 8.0 | Base de datos relacional que asegura atomicidad e integridad transaccional (ACID). |

---

## 📁 Estructura del Proyecto

```text
SICOTI-Sistema-Control-Inventario/
├── backend/
│   ├── src/
│   │   ├── config/          # Configuración de base de datos MySQL
│   │   ├── controllers/     # Controladores de la API REST
│   │   ├── models/          # Modelos de datos y consultas SQL
│   │   ├── routes/          # Definición de endpoints /api/v1
│   │   └── app.js           # Servidor principal de Express
│   ├── .env.example         # Variables de entorno de muestra
│   └── package.json
├── frontend/
│   ├── src/
│   │   ├── components/      # Componentes reutilizables de React (POS, Alertas)
│   │   ├── views/           # Pantallas principales (Inventario, Ventas)
│   │   ├── services/        # Cliente API HTTP (Axios / Fetch)
│   │   └── App.js           # Enrutamiento de la interfaz
│   └── package.json
├── database/
│   └── schema.sql           # Script de creación de tablas en MySQL 8.0
├── docs/                    # Diagramas UML y documentación técnica
├── README.md
└── LICENSE
