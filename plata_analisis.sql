-- ============================================================
-- PROYECTO: Análisis del rally histórico de la plata (2024-2026)
-- Autor: Jony
-- Fuente de datos: Stooq.com (XAG/USD, histórico diario)
-- ============================================================


-- ============================================================
-- 1. CREACIÓN DE LA BASE DE DATOS
-- ============================================================

CREATE DATABASE PLATA;
USE PLATA;


-- ============================================================
-- 2. DISEÑO DE TABLAS
-- ============================================================
-- precio_diario: histórico diario completo (OHLC) del precio de la plata.
-- eventos: hitos puntuales para dar contexto narrativo al dashboard
--          (máximos históricos, crashes, eventos geopolíticos...).
--
-- ============================================================

CREATE TABLE precio_diario (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL UNIQUE,
    apertura DECIMAL(10,4),
    maximo DECIMAL(10,4),
    minimo DECIMAL(10,4),
    cierre DECIMAL(10,4)
);

CREATE TABLE eventos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    descripcion VARCHAR(255),
    tipo VARCHAR(50)   -- 'record' | 'crash' | 'geopolitico' | 'contexto'
);


-- ============================================================
-- 3. CARGA DE DATOS (precio_diario)
-- ============================================================
-- El CSV descargado de Stooq trae los decimales con punto (23.831),
-- pero el Table Data Import Wizard de MySQL Workbench, al usar la
-- configuración regional del sistema, los interpretaba como texto no
-- convertible y los insertaba como NULL.
--
-- Solución: importar primero a una tabla "staging" en texto plano
-- (sin conversión de tipos), y luego pasar los datos ya convertidos
-- a la tabla final con CAST().
-- ============================================================

CREATE TABLE staging_precio (
    fecha VARCHAR(20),
    apertura VARCHAR(20),
    maximo VARCHAR(20),
    minimo VARCHAR(20),
    cierre VARCHAR(20)
);

-- (aquí se importó el CSV de Stooq a staging_precio
--  con el Table Data Import Wizard de MySQL Workbench)

INSERT INTO precio_diario (fecha, apertura, maximo, minimo, cierre)
SELECT
    STR_TO_DATE(fecha, '%Y-%m-%d'),
    CAST(apertura AS DECIMAL(10,4)),
    CAST(maximo AS DECIMAL(10,4)),
    CAST(minimo AS DECIMAL(10,4)),
    CAST(cierre AS DECIMAL(10,4))
FROM staging_precio;

DROP TABLE staging_precio;


-- ============================================================
-- 4. CARGA DE DATOS (eventos)
-- ============================================================

INSERT INTO eventos (fecha, descripcion, tipo) VALUES
('2025-01-01', 'La plata arranca 2025 en torno a los 29$/oz', 'contexto'),
('2025-09-18', 'La Fed inicia un ciclo de recortes de tipos; arranca el gran rally alcista', 'geopolitico'),
('2025-12-31', 'La plata cierra 2025 por encima de 70$/oz; mejor precio medio anual desde 1979', 'record'),
('2026-01-23', 'La plata supera por primera vez en la historia los 100$/oz', 'record'),
('2026-01-29', 'Máximo histórico intradiario: 121,64$/oz en el COMEX', 'record'),
('2026-01-30', 'Crash del 27% en un solo día tras el máximo histórico, por cierre masivo de posiciones largas', 'crash'),
('2026-02-28', 'Ataque de EE.UU. e Israel a Irán: rally de compra de activos refugio', 'geopolitico'),
('2026-04-27', 'La plata cotiza a 75,98$/oz, +129% interanual', 'contexto');


-- ============================================================
-- 5. CONSULTAS DE ANÁLISIS
-- ============================================================

-- 5.1 Máximo histórico y fecha en la que ocurrió
SELECT fecha, maximo
FROM precio_diario
ORDER BY maximo DESC
LIMIT 1;

-- 5.2 Mínimo histórico y fecha en la que ocurrió
SELECT fecha, minimo
FROM precio_diario
ORDER BY minimo ASC
LIMIT 1;

-- 5.3 Drawdown actual: caída porcentual del precio de hoy
--     respecto al máximo histórico
SELECT
    (
        (SELECT cierre FROM precio_diario ORDER BY fecha DESC LIMIT 1)
        -
        (SELECT maximo FROM precio_diario ORDER BY maximo DESC LIMIT 1)
    )
    /
    (SELECT maximo FROM precio_diario ORDER BY maximo DESC LIMIT 1)
    * 100
    AS drawdown_pct;

-- 5.4 Cierre del último día cotizado de cada mes
--     (para ver la tendencia mensual sin el ruido diario)
SELECT fecha, cierre
FROM precio_diario
WHERE fecha IN (
    SELECT MAX(fecha)
    FROM precio_diario
    GROUP BY YEAR(fecha), MONTH(fecha)
)
ORDER BY fecha;
