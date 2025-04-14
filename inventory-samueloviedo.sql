-- Establecer el esquema para que se busquen las tablas en el esquema "cc_user" por defecto
SET SEARCH_PATH TO CC_USER;

-- Prueba de consulta de las primeras 10 filas de la tabla PARTS
SELECT * FROM PARTS LIMIT 10;

-- Mejorando el Seguimiento de Piezas

-- 1. Validar y asegurar que el campo CODE sea único y obligatorio

-- A. Asegura que la columna CODE no permita valores nulos
ALTER TABLE PARTS
ALTER COLUMN CODE SET NOT NULL;

-- B. Asegura que no se repitan valores en la columna CODE
ALTER TABLE PARTS
ADD CONSTRAINT UNIQUE_CODE UNIQUE (CODE);

-- 2. Completar descripciones faltantes o vacías

-- A. Actualiza los registros con DESCRIPTION nula a un valor por defecto
UPDATE PARTS
SET DESCRIPTION = 'Sin descripción'
WHERE DESCRIPTION IS NULL;

-- B. Agrega una descripción genérica basada en el código para entradas sin descripción o en blanco
UPDATE PARTS
SET DESCRIPTION = 'Descripción de la pieza ' || CODE
WHERE DESCRIPTION IS NULL OR TRIM(DESCRIPTION) = '';

-- 3. Restringir que la columna DESCRIPTION esté vacía o nula
ALTER TABLE PARTS
ADD CONSTRAINT CHK_DESC_NOT_EMPTY CHECK (
	DESCRIPTION IS NOT NULL
	AND TRIM(DESCRIPTION) <> ''
);

-- 4. Pruebas de inserción

-- A. Intenta insertar una pieza sin descripción para probar restricciones (debe fallar si están bien definidas)
INSERT INTO PARTS (CODE, MANUFACTURER_ID)
VALUES ('TEST1', 1);

-- B. Inserta una pieza con descripción (debe funcionar si cumple todas las restricciones)
INSERT INTO PARTS (CODE, DESCRIPTION, MANUFACTURER_ID)
VALUES ('TEST01', 'Pieza de prueba con descripción', 1);

-- Mejorando las Opciones de Reordenamiento

-- 1. Asegurar que los campos PRICE_USD y QUANTITY no permitan nulos
ALTER TABLE REORDER_OPTIONS
ALTER COLUMN PRICE_USD SET NOT NULL;

ALTER TABLE REORDER_OPTIONS
ALTER COLUMN QUANTITY SET NOT NULL;

-- 2. Validar valores positivos

-- A. Restricción combinada: ambos campos deben ser mayores que 0
ALTER TABLE REORDER_OPTIONS
ADD CONSTRAINT CHK_PRICE_AND_QTY_POSITIVE CHECK (
	PRICE_USD > 0 AND QUANTITY > 0
);

-- B. Restricciones individuales: cada campo debe ser mayor que 0
ALTER TABLE REORDER_OPTIONS
ADD CONSTRAINT CHK_PRICE_POSITIVE CHECK (PRICE_USD > 0);

ALTER TABLE REORDER_OPTIONS
ADD CONSTRAINT CHK_QUANTITY_POSITIVE CHECK (QUANTITY > 0);

-- 3. Validar rango del precio unitario (precio por unidad entre $0.02 y $25.00)
ALTER TABLE REORDER_OPTIONS
ADD CONSTRAINT CHK_PRICE_PER_UNIT_RANGE CHECK (PRICE_USD / QUANTITY BETWEEN 0.02 AND 25.00);

-- 4. Crear una clave foránea desde REORDER_OPTIONS a PARTS
ALTER TABLE CC_USER.REORDER_OPTIONS
ADD CONSTRAINT FK_REORDER_PARTS FOREIGN KEY (PART_ID) REFERENCES CC_USER.PARTS (ID);

-- Mejorando el Seguimiento de Ubicaciones

-- 1. Asegurar que la cantidad de piezas en una ubicación sea positiva
ALTER TABLE CC_USER.LOCATIONS
ADD CONSTRAINT CHECK_QTY_POSITIVE CHECK (QTY > 0);

-- 2. Asegurar que no se repita la combinación de ubicación y parte
ALTER TABLE CC_USER.LOCATIONS
ADD CONSTRAINT UNIQUE_LOCATION_PART UNIQUE (LOCATION, PART_ID);

-- 3. Relacionar cada ubicación con una pieza existente (clave foránea)
ALTER TABLE CC_USER.LOCATIONS
ADD CONSTRAINT FK_LOCATIONS_PARTS FOREIGN KEY (PART_ID) REFERENCES CC_USER.PARTS (ID);

-- Mejorando el Seguimiento de Fabricantes

-- 1. Relacionar cada pieza con un fabricante existente (clave foránea)
ALTER TABLE CC_USER.PARTS
ADD CONSTRAINT FK_PARTS_MANUFACTURERS FOREIGN KEY (MANUFACTURER_ID) REFERENCES CC_USER.MANUFACTURERS (ID);

-- 2. Insertar un nuevo fabricante llamado 'Pip-NNC Industrial'
INSERT INTO MANUFACTURERS (ID, NAME)
VALUES (11, 'Pip-NNC Industrial');

-- 3. Actualizar las piezas con fabricantes 1 o 2, asignándolas al nuevo fabricante
UPDATE PARTS
SET MANUFACTURER_ID = 11
WHERE MANUFACTURER_ID IN (1, 2);