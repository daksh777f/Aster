-- Datenbank-Härtung: Eingeschränkter App-User für RLS-Erzwingung
-- Flyway läuft weiterhin als 'postgres' (Superuser), um Schema-Änderungen vorzunehmen.
-- Das Backend sollte diesen neuen User nutzen, damit RLS-Regeln garantiert greifen.

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'aster_app') THEN
        -- Erstelle den User (Passwort sollte in der .env überschrieben werden)
        CREATE ROLE aster_app WITH LOGIN PASSWORD 'aster_app_pwd_123';
    END IF;
END
$$;

-- 1. Zugriff auf Schemata gewähren
GRANT USAGE ON SCHEMA app TO aster_app;
GRANT USAGE ON SCHEMA vector TO aster_app;

-- 2. Berechtigungen auf bestehende Tabellen und Sequenzen
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app TO aster_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app TO aster_app;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA vector TO aster_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA vector TO aster_app;

-- 3. Berechtigungen für zukünftige Tabellen (erstellt durch Flyway/postgres)
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA app 
    GRANT ALL PRIVILEGES ON TABLES TO aster_app;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA app 
    GRANT ALL PRIVILEGES ON SEQUENCES TO aster_app;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA vector 
    GRANT ALL PRIVILEGES ON TABLES TO aster_app;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA vector 
    GRANT ALL PRIVILEGES ON SEQUENCES TO aster_app;

-- 4. Sicherstellen, dass der User RLS nicht umgehen kann (NOBYPASSRLS ist Standard, hier explizit)
ALTER ROLE aster_app NOBYPASSRLS;

COMMENT ON ROLE aster_app IS 'Eingeschränkter Anwendungsbenutzer für Aster Backend (erzwingt RLS).';
