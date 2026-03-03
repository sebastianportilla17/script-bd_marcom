-- *******************************
-- * MÓDULO: MARKETING Y COMERCIAL (MARCOM)
-- * Basado en el patrón ADSO 3171727
-- * Versión: 2.0 - CORREGIDA Y OPTIMIZADA
-- *******************************
-----------------------------------------------------------
-- 1. ELIMINACIÓN DE TABLAS EXISTENTES (ORDEN INVERSO)
-----------------------------------------------------------
DROP TABLE IF EXISTS marcom.tab_contactos_adicionales;
DROP TABLE IF EXISTS marcom.tab_medicion_kpi;
DROP TABLE IF EXISTS marcom.tab_prod_camp;
DROP TABLE IF EXISTS marcom.tab_even_lead;
DROP TABLE IF EXISTS marcom.tab_interacciones_lead;
DROP TABLE IF EXISTS marcom.tab_lead_camp;
DROP TABLE IF EXISTS marcom.tab_segmentacion_tercero;
DROP TABLE IF EXISTS marcom.tab_plantillas_correo;
DROP TABLE IF EXISTS marcom.tab_presupuesto;

-- Tablas intermedias
DROP TABLE IF EXISTS marcom.tab_leads;
DROP TABLE IF EXISTS marcom.tab_evento;
DROP TABLE IF EXISTS marcom.tab_campana_canal;
DROP TABLE IF EXISTS marcom.tab_campanas;
DROP TABLE IF EXISTS marcom.tab_reglas_segmentacion;
DROP TABLE IF EXISTS marcom.tab_valores_segmentacion;

-- Tablas padre (paramétricas sin dependencias)
DROP TABLE IF EXISTS marcom.tab_kpis_campana;
DROP TABLE IF EXISTS marcom.tab_motivos_perdida;
DROP TABLE IF EXISTS marcom.tab_criterios_segmentacion;
DROP TABLE IF EXISTS marcom.tab_etapas_funnel;
DROP TABLE IF EXISTS marcom.tab_canales;
DROP TABLE IF EXISTS marcom.tab_pmtros_marcom;

DROP SCHEMA IF EXISTS marcom;
-----------------------------------------------------------
-- 2. CREACIÓN DEL ESQUEMA (como en los otros módulos)
-----------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS marcom;
-----------------------------------------------------------
-- 3. TABLAS PARAMÉTRICAS (Maestros)
-----------------------------------------------------------
-- ============================================================
-- TABLA DE PARÁMETROS DEL MÓDULO MARKETING Y COMERCIAL
-- Una sola fila por empresa.
-- Solo aplica a leads — clientes tienen sus parámetros en FACCAR.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_pmtros_marcom
(
    id_empresa                  DECIMAL(10,0)   NOT NULL CHECK(id_empresa >= 10000000 AND id_empresa <= 9999999999),
    val_dias_sin_interaccion    DECIMAL(3,0)    NOT NULL CHECK(val_dias_sin_interaccion >= 1 AND val_dias_sin_interaccion <= 365) DEFAULT 15, -- Días sin actividad antes de alertar al vendedor sobre ese lead
    val_dias_expiracion_lead    DECIMAL(3,0)    NOT NULL CHECK(val_dias_expiracion_lead >= 1 AND val_dias_expiracion_lead <= 365) DEFAULT 90, -- Días máximos de vida de un lead antes de marcarse como perdido automáticamente
    val_score_min_tibio         DECIMAL(3,0)    NOT NULL CHECK(val_score_min_tibio >= 1 AND val_score_min_tibio <= 99) DEFAULT 40,-- Score mínimo para que PHP clasifique un lead como tibio
    val_score_min_caliente      DECIMAL(3,0)    NOT NULL CHECK(val_score_min_caliente >= 2 AND val_score_min_caliente <= 100) DEFAULT 70, -- Score mínimo para que PHP clasifique un lead como caliente
    val_max_contactos_adic      DECIMAL(1,0)    NOT NULL CHECK(val_max_contactos_adic >= 1 AND val_max_contactos_adic <= 20) DEFAULT 2, -- Número máximo de contactos adicionales permitidos por tercero
    val_presupuesto_defecto     DECIMAL(12,0)   NOT NULL CHECK(val_presupuesto_defecto >= 0) DEFAULT 0, --Presupuesto inicial sugerido al crear una campaña nueva
    val_por_apertura_exito      DECIMAL(3,0)    NOT NULL CHECK(val_por_apertura_exito >= 1 AND val_por_apertura_exito <= 100) DEFAULT 20,

    PRIMARY KEY(id_empresa),
    FOREIGN KEY(id_empresa) REFERENCES public.tab_pmtros_grales(id_empresa),
    CONSTRAINT chk_score_coherente CHECK(val_score_min_caliente > val_score_min_tibio)
);

-- ------------------------------------------------
-- TABLA DE ETAPAS DEL FUNNEL DE VENTAS
-- Define las etapas por las que atraviesa un lead
-- desde el primer contacto hasta el cierre.
-- Configurable para adaptarse al negocio.
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS marcom.tab_etapas_funnel
(
    id_etapa            DECIMAL(2,0)    NOT NULL CHECK(id_etapa > 0 AND id_etapa <= 99),
    nom_etapa           VARCHAR(30)     NOT NULL CHECK(LENGTH(nom_etapa) >= 3),
    des_etapa           TEXT            NOT NULL,
    num_orden           DECIMAL(2,0)    NOT NULL CHECK(num_orden > 0 AND num_orden <= 99),
    ind_etapa_final     BOOLEAN         NOT NULL, -- TRUE = etapa de cierre (ganado/perdido)
    ind_estado          BOOLEAN         NOT NULL, -- TRUE = activa / FALSE = inactiva
    PRIMARY KEY(id_etapa)
);

INSERT INTO marcom.tab_etapas_funnel VALUES(1, 'Prospecto',         'Lead identificado pero aún sin contacto',              1, FALSE, TRUE);
INSERT INTO marcom.tab_etapas_funnel VALUES(2, 'Contactado',        'Se realizó el primer contacto con el lead',            2, FALSE, TRUE);
INSERT INTO marcom.tab_etapas_funnel VALUES(3, 'Interesado',        'El lead mostró interés en el producto o servicio',     3, FALSE, TRUE);
INSERT INTO marcom.tab_etapas_funnel VALUES(4, 'Propuesta enviada', 'Se envió una propuesta comercial formal',              4, FALSE, TRUE);
INSERT INTO marcom.tab_etapas_funnel VALUES(5, 'Negociación',       'En proceso de negociación de condiciones',             5, FALSE, TRUE);
INSERT INTO marcom.tab_etapas_funnel VALUES(6, 'Ganado',            'Lead convertido en cliente, primera factura emitida',  6, TRUE,  TRUE);
INSERT INTO marcom.tab_etapas_funnel VALUES(7, 'Perdido',           'Lead que no convirtió, negocio no cerrado',            7, TRUE,  TRUE);

-- ------------------------------------------------
-- TABLA DE CANALES DE DIFUSIÓN DE CAMPAÑAS
-- Define los medios digitales por los que se puede
-- lanzar y difundir una campaña de marketing.
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS marcom.tab_canales
(
    id_canal            DECIMAL(2,0)    NOT NULL CHECK(id_canal > 0 AND id_canal <= 99),
    nom_canal           VARCHAR(30)     NOT NULL CHECK(LENGTH(nom_canal) >= 3),
    des_canal           TEXT            NOT NULL,
    ind_estado          BOOLEAN         NOT NULL, -- TRUE = activo / FALSE = inactivo
    PRIMARY KEY(id_canal)
);

INSERT INTO marcom.tab_canales VALUES(1, 'Email',     'Campañas enviadas por correo electrónico masivo',          TRUE);
INSERT INTO marcom.tab_canales VALUES(2, 'Instagram', 'Publicaciones y anuncios en Instagram',                    TRUE);
INSERT INTO marcom.tab_canales VALUES(3, 'Facebook',  'Publicaciones y anuncios en Facebook',                     TRUE);
INSERT INTO marcom.tab_canales VALUES(4, 'LinkedIn',  'Publicaciones y anuncios en LinkedIn',                     TRUE);
INSERT INTO marcom.tab_canales VALUES(5, 'WhatsApp',  'Mensajes promocionales masivos por WhatsApp Business',     TRUE);

-- ------------------------------------------------
-- TABLA DE CRITERIOS DE SEGMENTACIÓN
-- Define los aspectos estratégicos por los que se 
-- clasifican leads y clientes. Solo modificable 
-- por el rol administrador via módulo SECURE.
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS marcom.tab_criterios_segmentacion
(
    id_criterio         DECIMAL(2,0)    NOT NULL CHECK(id_criterio > 0 AND id_criterio <= 99),
    nom_criterio        VARCHAR(30)     NOT NULL CHECK(LENGTH(nom_criterio) >= 3),
    des_criterio        TEXT            NOT NULL,
    ind_estado          BOOLEAN         NOT NULL, -- TRUE = activo / FALSE = inactivo
    PRIMARY KEY(id_criterio)
);

INSERT INTO marcom.tab_criterios_segmentacion VALUES(1, 'Origen',             'Define de dónde proviene el lead o cliente',                       TRUE);
INSERT INTO marcom.tab_criterios_segmentacion VALUES(2, 'Temperatura',        'Indica qué tan cerca está el lead de tomar una decisión de compra', TRUE);
INSERT INTO marcom.tab_criterios_segmentacion VALUES(3, 'Tamaño de empresa',  'Clasifica según el tamaño de la empresa del lead o cliente',        TRUE);
INSERT INTO marcom.tab_criterios_segmentacion VALUES(4, 'Personalizado',      'Criterio configurable según las necesidades del negocio',           TRUE);

-- ------------------------------------------------
-- TABLA DE VALORES DE SEGMENTACIÓN
-- Define las opciones específicas de cada criterio
-- e incluye un peso para calcular Lead Scoring.
-- Solo modificable por el rol administrador.
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS marcom.tab_valores_segmentacion
(
    id_valor            DECIMAL(3,0)    NOT NULL CHECK(id_valor > 0 AND id_valor <= 999),
    id_criterio         DECIMAL(2,0)    NOT NULL,
    nom_valor           VARCHAR(30)     NOT NULL CHECK(LENGTH(nom_valor) >= 3),
    des_valor           TEXT            NOT NULL,
    val_peso            DECIMAL(2,0)    NOT NULL CHECK(val_peso >= 1 AND val_peso <= 10),
    ind_estado          BOOLEAN         NOT NULL, -- TRUE = activo / FALSE = inactivo
    PRIMARY KEY(id_valor),
    FOREIGN KEY(id_criterio) REFERENCES marcom.tab_criterios_segmentacion(id_criterio)
);

-- Valores para Origen (id_criterio = 1)
INSERT INTO marcom.tab_valores_segmentacion VALUES(1,  1, 'Redes Sociales',    'Lead captado por redes sociales',              2, TRUE);
INSERT INTO marcom.tab_valores_segmentacion VALUES(2,  1, 'Referido',          'Lead recomendado por otro cliente',            3, TRUE);
INSERT INTO marcom.tab_valores_segmentacion VALUES(3,  1, 'Búsqueda Orgánica', 'Lead captado por búsqueda en internet',        1, TRUE);
INSERT INTO marcom.tab_valores_segmentacion VALUES(4,  1, 'Email',             'Lead captado por campaña de email',            2, TRUE);

-- Valores para Temperatura (id_criterio = 2)
INSERT INTO marcom.tab_valores_segmentacion VALUES(5,  2, 'Frío',              'Sin interés claro aún',                        1, TRUE);
INSERT INTO marcom.tab_valores_segmentacion VALUES(6,  2, 'Tibio',             'Mostró algún interés pero no decide',          2, TRUE);
INSERT INTO marcom.tab_valores_segmentacion VALUES(7,  2, 'Caliente',          'Listo para tomar una decisión de compra',      3, TRUE);

-- Valores para Tamaño de empresa (id_criterio = 3)
INSERT INTO marcom.tab_valores_segmentacion VALUES(8,  3, 'Pequeña',           'Empresa con menos de 50 empleados',            1, TRUE);
INSERT INTO marcom.tab_valores_segmentacion VALUES(9,  3, 'Mediana',           'Empresa entre 50 y 200 empleados',             2, TRUE);
INSERT INTO marcom.tab_valores_segmentacion VALUES(10, 3, 'Grande',            'Empresa con más de 200 empleados',             3, TRUE);

-- ------------------------------------------------
-- TABLA DE REGLAS DE SEGMENTACIÓN AUTOMÁTICA
-- Define las condiciones que disparan la asignación
-- automática de valores de segmentación a leads y 
-- clientes. Solo modificable por el administrador.
-- Versión 1.0 - condición simple por regla.
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS marcom.tab_reglas_segmentacion
(
    id_regla                DECIMAL(3,0)    NOT NULL CHECK(id_regla > 0 AND id_regla <= 999),
    id_valor                DECIMAL(3,0)    NOT NULL,
    nom_campo_condicion     VARCHAR(30)     NOT NULL, -- se queda VARCHAR porque es el nombre del campo
    val_condicion           DECIMAL(5,0)    NOT NULL CHECK(val_condicion > 0), -- cambia a número
    ind_aplica_lead         BOOLEAN         NOT NULL, -- TRUE = aplica a leads
    ind_aplica_cliente      BOOLEAN         NOT NULL, -- TRUE = aplica a clientes
    ind_estado              BOOLEAN         NOT NULL, -- TRUE = activa / FALSE = inactiva
    PRIMARY KEY(id_regla),
    FOREIGN KEY(id_valor) REFERENCES marcom.tab_valores_segmentacion(id_valor)
);

-- Si el lead vino por LinkedIn, asignar Redes Sociales
INSERT INTO marcom.tab_reglas_segmentacion VALUES(1, 1, 'id_canal', 4, TRUE,  FALSE, TRUE);
-- Si el lead vino por Instagram, asignar Redes Sociales
INSERT INTO marcom.tab_reglas_segmentacion VALUES(2, 1, 'id_canal', 2, TRUE,  FALSE, TRUE);
-- Si el lead vino por Facebook, asignar Redes Sociales
INSERT INTO marcom.tab_reglas_segmentacion VALUES(3, 1, 'id_canal', 3, TRUE,  FALSE, TRUE);
-- Si el lead vino por Email, asignar origen Email
INSERT INTO marcom.tab_reglas_segmentacion VALUES(4, 4, 'id_canal', 1, TRUE,  TRUE,  TRUE);
-- Si entra en etapa Negociación, asignar temperatura Caliente
INSERT INTO marcom.tab_reglas_segmentacion VALUES(5, 7, 'id_etapa', 5, TRUE,  FALSE, TRUE);
-- Si entra en etapa Contactado, asignar temperatura Tibio
INSERT INTO marcom.tab_reglas_segmentacion VALUES(6, 6, 'id_etapa', 2, TRUE,  FALSE, TRUE);

-- ============================================================
-- TABLA DE SEGMENTACIÓN DE TERCEROS
-- Conecta leads y clientes con sus valores de segmentación.
-- Una sola tabla para ambos usando ind_tipo como diferenciador.
-- PHP inserta aquí después de evaluar tab_reglas_segmentacion
-- y luego actualiza val_score en tab_leads.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_segmentacion_tercero
(
    id_tercero          DECIMAL(10,0)   NOT NULL CHECK(id_tercero >= 10000000 AND id_tercero <= 9999999999),
    id_valor            DECIMAL(3,0)    NOT NULL CHECK(id_valor > 0 AND id_valor <= 999),
    ind_tipo            BOOLEAN         NOT NULL, -- TRUE = lead / FALSE = cliente
    fec_asignacion      DATE            NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY(id_tercero, id_valor),
    FOREIGN KEY(id_tercero) REFERENCES public.tab_terceros(id_tercero),
    FOREIGN KEY(id_valor)   REFERENCES marcom.tab_valores_segmentacion(id_valor)
);

-- ============================================================
-- TABLA DE CAMPAÑAS
-- Núcleo del módulo. Cada fila es una campaña digital.
-- La asignación de vendedores ocurre en tab_lead_camp.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_campanas
(
    id_campana          DECIMAL(6,0)    NOT NULL CHECK(id_campana > 0 AND id_campana <= 999999),
    nom_campana         VARCHAR(120)    NOT NULL CHECK(LENGTH(nom_campana) >= 3),
    des_objetivo        VARCHAR(250)    NULL,
    fec_inicio          DATE            NOT NULL,
    fec_fin             DATE            NOT NULL,
    ind_estado          BOOLEAN         NOT NULL, -- TRUE = activa / FALSE = inactiva
    PRIMARY KEY(id_campana),
    CONSTRAINT chk_fechas_campana CHECK(fec_fin >= fec_inicio)
);

-- ============================================================
-- TABLA CAMPAÑA CANAL
-- Relación muchos a muchos entre campañas y canales.
-- Define por qué canales se difunde cada campaña.
-- v2.0: agregar presupuesto por canal.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_campana_canal
(
    id_campana      DECIMAL(6,0)    NOT NULL CHECK(id_campana > 0 AND id_campana <= 999999),
    id_canal        DECIMAL(2,0)    NOT NULL CHECK(id_canal > 0 AND id_canal <= 99),
    PRIMARY KEY(id_campana, id_canal),
    FOREIGN KEY(id_campana) REFERENCES marcom.tab_campanas(id_campana),
    FOREIGN KEY(id_canal)   REFERENCES marcom.tab_canales(id_canal)
);

-- ============================================================
-- TABLA DE MOTIVOS DE PÉRDIDA
-- Registra las razones por las que un lead no convirtió.
-- Da inteligencia al negocio para mejorar la estrategia comercial.
-- Debe ir antes de tab_leads en el script final.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_motivos_perdida
(
    id_motivo_perdida   DECIMAL(2,0)    NOT NULL CHECK(id_motivo_perdida > 0 AND id_motivo_perdida <= 99),
    nom_motivo          VARCHAR(60)     NOT NULL CHECK(LENGTH(nom_motivo) >= 3),
    des_motivo          TEXT            NOT NULL,
    ind_estado          BOOLEAN         NOT NULL, -- TRUE = activo / FALSE = inactivo
    PRIMARY KEY(id_motivo_perdida)
);

INSERT INTO marcom.tab_motivos_perdida VALUES(1, 'Precio muy alto',          'El lead consideró que el precio no se ajustaba a su presupuesto',          TRUE);
INSERT INTO marcom.tab_motivos_perdida VALUES(2, 'Eligió la competencia',    'El lead decidió contratar con un competidor',                               TRUE);
INSERT INTO marcom.tab_motivos_perdida VALUES(3, 'Sin presupuesto',          'El lead no contaba con presupuesto disponible en ese momento',              TRUE);
INSERT INTO marcom.tab_motivos_perdida VALUES(4, 'No era el momento',        'El lead mostró interés pero no estaba listo para decidir',                 TRUE);
INSERT INTO marcom.tab_motivos_perdida VALUES(5, 'Sin respuesta',            'El lead no respondió tras varios intentos de contacto',                    TRUE);
INSERT INTO marcom.tab_motivos_perdida VALUES(6, 'Producto no se ajusta',    'El producto o servicio no cubría la necesidad del lead',                   TRUE);

-- ============================================================
-- TABLA DE LEADS
-- Extiende tab_terceros del public. Todo lead debe estar
-- primero registrado en tab_terceros con id_cat_tercero = 4.
-- El score lo calcula y actualiza PHP sumando los pesos
-- de tab_valores_segmentacion. El motivo de pérdida es NULL
-- mientras el lead esté activo en el funnel.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_leads
(
    id_lead             DECIMAL(10,0)   NOT NULL CHECK(id_lead >= 10000000 AND id_lead <= 9999999999),
    fec_registro        DATE            NOT NULL DEFAULT CURRENT_DATE,
    val_score           DECIMAL(3,0)    NOT NULL CHECK(val_score >= 0 AND val_score <= 100) DEFAULT 0,
    id_etapa            DECIMAL(2,0)    NOT NULL,
    id_motivo_perdida   DECIMAL(2,0)    NULL, -- NULL mientras el lead esté activo
    ind_estado          BOOLEAN         NOT NULL, -- TRUE = activo / FALSE = inactivo
    PRIMARY KEY(id_lead),
    FOREIGN KEY(id_lead)            REFERENCES public.tab_terceros(id_tercero),
    FOREIGN KEY(id_etapa)           REFERENCES marcom.tab_etapas_funnel(id_etapa),
    FOREIGN KEY(id_motivo_perdida)  REFERENCES marcom.tab_motivos_perdida(id_motivo_perdida)
);

-- ============================================================
-- TABLA LEAD CAMPAÑA
-- Relación muchos a muchos entre leads y campañas.
-- Guarda cómo y cuándo entró ese lead a esa campaña.
-- El vendedor no va aquí — se asigna en tab_interacciones_lead.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_lead_camp
(
    id_lead             DECIMAL(10,0)   NOT NULL CHECK(id_lead >= 10000000 AND id_lead <= 9999999999),
    id_campana          DECIMAL(6,0)    NOT NULL CHECK(id_campana > 0 AND id_campana <= 999999),
    fec_asignacion      DATE            NOT NULL DEFAULT CURRENT_DATE,
    id_etapa            DECIMAL(2,0)    NOT NULL CHECK(id_etapa > 0 AND id_etapa <= 99),
    ind_origen          DECIMAL(1,0)    NOT NULL CHECK(ind_origen >= 1 AND ind_origen <= 3),-- 1 = Manual / 2 = Automático / 3 = Importado
    ind_estado          BOOLEAN         NOT NULL, -- TRUE = activo / FALSE = inactivo
    PRIMARY KEY(id_lead, id_campana),
    FOREIGN KEY(id_lead)    REFERENCES marcom.tab_leads(id_lead),
    FOREIGN KEY(id_campana) REFERENCES marcom.tab_campanas(id_campana),
    FOREIGN KEY(id_etapa)   REFERENCES marcom.tab_etapas_funnel(id_etapa)
);

-- ============================================================
-- TABLA DE INTERACCIONES DEL LEAD
-- Historial completo de cada contacto vendedor-lead.
-- Cada llamada, email, WhatsApp, visita o reunión queda aquí.
-- PHP usa fec_proxima_accion para enviar recordatorios al vendedor.
-- La etapa del funnel la gestiona tab_lead_camp.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_interacciones_lead
(
    id_interaccion      DECIMAL(6,0)    NOT NULL CHECK(id_interaccion > 0 AND id_interaccion <= 999999),
    id_lead             DECIMAL(10,0)   NOT NULL CHECK(id_lead >= 10000000 AND id_lead <= 9999999999),
    id_vendedor         DECIMAL(10,0)   NOT NULL CHECK(id_vendedor >= 10000000 AND id_vendedor <= 9999999999),
    id_canal            DECIMAL(2,0)    NOT NULL CHECK(id_canal > 0 AND id_canal <= 99),
    fec_interaccion     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ind_tipo            DECIMAL(1,0)    NOT NULL CHECK(ind_tipo >= 1 AND ind_tipo <= 5),-- 1=Llamada / 2=Email / 3=WhatsApp / 4=Visita / 5=Reunión
    des_resultado       VARCHAR(250)    NOT NULL CHECK(LENGTH(des_resultado) >= 3),
    fec_proxima_accion  DATE            NULL, -- NULL si no hay próxima acción agendada
    PRIMARY KEY(id_interaccion),
    FOREIGN KEY(id_lead)        REFERENCES marcom.tab_leads(id_lead),
    FOREIGN KEY(id_vendedor)    REFERENCES public.tab_terceros(id_tercero),
    FOREIGN KEY(id_canal)       REFERENCES marcom.tab_canales(id_canal)
);

-- ============================================================
-- TABLA DE EVENTOS
-- Acciones presenciales o virtuales puntuales como ferias,
-- webinars o lanzamientos. La campaña es opcional.
-- El responsable es cualquier tercero registrado en public.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_evento
(
    id_evento           DECIMAL(6,0)    NOT NULL CHECK(id_evento > 0 AND id_evento <= 999999),
    id_campana          DECIMAL(6,0)    NULL, -- NULL si el evento no pertenece a una campaña       
    id_responsable      DECIMAL(10,0)   NOT NULL CHECK(id_responsable >= 10000000 AND id_responsable <= 9999999999),
    nom_evento          VARCHAR(120)    NOT NULL CHECK(LENGTH(nom_evento) >= 3),
    des_evento          TEXT            NOT NULL,
    lug_evento          VARCHAR(150)    NOT NULL CHECK(LENGTH(lug_evento) >= 3),
    val_cupo            DECIMAL(4,0)    NOT NULL CHECK(val_cupo > 0 AND val_cupo <= 9999),
    fec_evento          DATE            NOT NULL,
    ind_estado          BOOLEAN         NOT NULL, -- TRUE = activo / FALSE = inactivo
    PRIMARY KEY(id_evento),
    FOREIGN KEY(id_campana)     REFERENCES marcom.tab_campanas(id_campana),
    FOREIGN KEY(id_responsable) REFERENCES public.tab_terceros(id_tercero)
);

-- ============================================================
-- TABLA EVENTO LEAD
-- Registra qué leads están vinculados a qué eventos.
-- Maneja el ciclo completo: invitación, confirmación y asistencia.
-- Los NULL son justificados — un lead invitado puede no confirmar
-- y uno confirmado puede no asistir.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_even_lead
(
    id_evento           DECIMAL(6,0)    NOT NULL CHECK(id_evento > 0 AND id_evento <= 999999),
    id_lead             DECIMAL(10,0)   NOT NULL CHECK(id_lead >= 10000000 AND id_lead <= 9999999999),
    fec_invitacion      DATE            NOT NULL DEFAULT CURRENT_DATE,
    fec_confirmacion    DATE            NULL, -- NULL si el lead no ha confirmado
    fec_asistencia      DATE            NULL, -- NULL si el lead no asistió
    ind_estado          DECIMAL(1,0)    NOT NULL CHECK(ind_estado >= 1 AND ind_estado <= 4),-- 1=Invitado / 2=Confirmado / 3=Asistió / 4=No asistió
    PRIMARY KEY(id_evento, id_lead),
    FOREIGN KEY(id_evento)  REFERENCES marcom.tab_evento(id_evento),
    FOREIGN KEY(id_lead)    REFERENCES marcom.tab_leads(id_lead)
);

-- ============================================================
-- TABLA PRODUCTO CAMPAÑA
-- Relación muchos a muchos entre productos y campañas.
-- Define qué productos o servicios se promocionan en cada campaña.
-- v2.0: agregar metas de unidades e ingresos por producto.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_prod_camp
(
    id_campana          DECIMAL(6,0)    NOT NULL CHECK(id_campana > 0 AND id_campana <= 999999),
    id_producto         DECIMAL(3,0)    NOT NULL CHECK(id_producto > 0 AND id_producto <= 999),
    PRIMARY KEY(id_campana, id_producto),
    FOREIGN KEY(id_campana)     REFERENCES marcom.tab_campanas(id_campana),
    FOREIGN KEY(id_producto)    REFERENCES compro.tab_productos(id_producto)
);

-- ============================================================
-- TABLA DE PRESUPUESTO
-- Registra el presupuesto asignado y ejecutado por campaña o evento.
-- Nunca puede pertenecer a campaña Y evento al mismo tiempo.
-- val_ejecutado empieza en NULL y PHP lo actualiza conforme
-- se van registrando los gastos reales.
-- El flujo de aprobación por SECURE se integra en v1.1.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_presupuesto
(
    id_presupuesto      DECIMAL(6,0)    NOT NULL CHECK(id_presupuesto > 0 AND id_presupuesto <= 999999),
    id_campana          DECIMAL(6,0)    NULL     CHECK(id_campana > 0 AND id_campana <= 999999),
    id_evento           DECIMAL(6,0)    NULL     CHECK(id_evento > 0 AND id_evento <= 999999),
    val_aprobado        DECIMAL(12,0)   NOT NULL CHECK(val_aprobado >= 0),
    val_ejecutado       DECIMAL(12,0)   NULL     CHECK(val_ejecutado >= 0), -- NULL al inicio, PHP lo actualiza
    des_presupuesto     VARCHAR(200)    NULL     CHECK(LENGTH(des_presupuesto) >= 3),
    fec_presupuesto     DATE            NOT NULL DEFAULT CURRENT_DATE,
    ind_estado          DECIMAL(1,0)    NOT NULL CHECK(ind_estado >= 1 AND ind_estado <= 3) DEFAULT 1,-- 1=Pendiente / 2=Aprobado / 3=Rechazado
    PRIMARY KEY(id_presupuesto),
    FOREIGN KEY(id_campana) REFERENCES marcom.tab_campanas(id_campana),
    FOREIGN KEY(id_evento)  REFERENCES marcom.tab_evento(id_evento),
    CONSTRAINT chk_campana_o_evento CHECK(
        (id_campana IS NOT NULL AND id_evento IS NULL) OR
        (id_evento IS NOT NULL AND id_campana IS NULL)
    )
);

-- ============================================================
-- TABLA DE KPIs DE CAMPAÑA
-- Define qué KPIs se miden en el módulo MARCOM.
-- Para agregar un KPI nuevo solo se inserta una fila aquí
-- sin alterar ninguna estructura. Totalmente escalable.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_kpis_campana
(
    id_kpi              DECIMAL(2,0)    NOT NULL CHECK(id_kpi > 0 AND id_kpi <= 99),
    nom_kpi             VARCHAR(60)     NOT NULL CHECK(LENGTH(nom_kpi) >= 3),
    des_kpi             TEXT            NOT NULL,
    ind_estado          BOOLEAN         NOT NULL, -- TRUE = activo / FALSE = inactivo
    PRIMARY KEY(id_kpi)
);

INSERT INTO marcom.tab_kpis_campana VALUES(1, 'Leads Generados',    'Cantidad de leads nuevos captados en el período',                          TRUE);
INSERT INTO marcom.tab_kpis_campana VALUES(2, 'Correos Abiertos',   'Cantidad de correos abiertos por los destinatarios',                       TRUE);
INSERT INTO marcom.tab_kpis_campana VALUES(3, 'Clics en Correo',    'Cantidad de clics en enlaces dentro del correo',                           TRUE);
INSERT INTO marcom.tab_kpis_campana VALUES(4, 'Conversiones',       'Leads que se convirtieron en clientes en el período',                      TRUE);
INSERT INTO marcom.tab_kpis_campana VALUES(5, 'Alcance',            'Cantidad de personas que vieron la campaña en el período',                 TRUE);
INSERT INTO marcom.tab_kpis_campana VALUES(6, 'Costo por Lead',     'Presupuesto ejecutado dividido entre leads generados en el período',       TRUE);
INSERT INTO marcom.tab_kpis_campana VALUES(7, 'ROI',                'Retorno sobre inversión expresado en porcentaje',                          TRUE);

-- ============================================================
-- TABLA DE MEDICIÓN DE KPIs
-- Guarda los valores de cada KPI por campaña y por período.
-- PHP inserta una fila por KPI por mes por campaña.
-- PK compuesta garantiza una sola medición por KPI por mes.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_medicion_kpi
(
    id_campana          DECIMAL(6,0)    NOT NULL CHECK(id_campana > 0 AND id_campana <= 999999),
    id_kpi              DECIMAL(2,0)    NOT NULL CHECK(id_kpi > 0 AND id_kpi <= 99),
    num_anio            DECIMAL(4,0)    NOT NULL CHECK(num_anio >= 2000 AND num_anio <= 9999),
    num_mes             DECIMAL(2,0)    NOT NULL CHECK(num_mes >= 1 AND num_mes <= 12),
    val_medicion        DECIMAL(12,2)   NOT NULL CHECK(val_medicion >= 0),
    PRIMARY KEY(id_campana, id_kpi, num_anio, num_mes),
    FOREIGN KEY(id_campana) REFERENCES marcom.tab_campanas(id_campana),
    FOREIGN KEY(id_kpi)     REFERENCES marcom.tab_kpis_campana(id_kpi)
);

-- ============================================================
-- TABLA DE PLANTILLAS DE CORREO
-- Plantillas reutilizables para email y WhatsApp.
-- Genéricas, no atadas a ninguna campaña específica.
-- PHP las consulta al momento de crear un envío.
-- La IA puede generar o mejorar el contenido desde PHP.
-- des_asunto es NULL justificado cuando el canal es WhatsApp.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_plantillas_correo
(
    id_plantilla        DECIMAL(4,0)    NOT NULL CHECK(id_plantilla > 0 AND id_plantilla <= 9999),
    id_canal            DECIMAL(2,0)    NOT NULL CHECK(id_canal > 0 AND id_canal <= 99),
    nom_plantilla       VARCHAR(120)    NOT NULL CHECK(LENGTH(nom_plantilla) >= 3),
    des_asunto          VARCHAR(150)    NULL, -- NULL justificado cuando el canal es WhatsApp
    des_contenido       TEXT            NOT NULL,
    ind_generada_ia     BOOLEAN         NOT NULL DEFAULT FALSE, -- TRUE si la generó la IA
    ind_estado          BOOLEAN         NOT NULL, -- TRUE = activa / FALSE = inactiva
    PRIMARY KEY(id_plantilla),
    FOREIGN KEY(id_canal) REFERENCES marcom.tab_canales(id_canal)
);

-- ============================================================
-- TABLA DE CONTACTOS ADICIONALES
-- Guarda contactos adicionales de terceros jurídicos (empresas).
-- Ejemplos: gerente, contador, representante legal.
-- PHP valida que id_tercero sea jurídico (ind_tipo_tercero = TRUE)
-- antes de insertar. El máximo de contactos por tercero lo
-- controla val_max_contactos_adic en tab_pmtros_marcom.
-- ============================================================
CREATE TABLE IF NOT EXISTS marcom.tab_contactos_adicionales
(
    id_contacto         DECIMAL(6,0)    NOT NULL CHECK(id_contacto > 0 AND id_contacto <= 999999),
    id_tercero          DECIMAL(10,0)   NOT NULL CHECK(id_tercero >= 10000000 AND id_tercero <= 9999999999),
    nom_contacto        VARCHAR(120)    NOT NULL CHECK(LENGTH(nom_contacto) >= 3),
    car_contacto        VARCHAR(60)     NOT NULL CHECK(LENGTH(car_contacto) >= 2),
    tel_contacto        DECIMAL(10,0)   NOT NULL CHECK(tel_contacto >= 1000000000),
    email_contacto      VARCHAR(120)    NOT NULL CHECK(LENGTH(email_contacto) >= 6),
    ind_estado          BOOLEAN         NOT NULL, -- TRUE = activo / FALSE = inactivo
    PRIMARY KEY(id_contacto),
    FOREIGN KEY(id_tercero) REFERENCES public.tab_terceros(id_tercero)
);