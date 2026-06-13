-- Setzt das Passwort des App-Users auf den konfigurierten Wert.
-- Wird beim Install-Script via Flyway-Placeholder ${ASTER_APP_PASSWORD} übergeben.
-- Für bestehende Installationen: aktualisiert das Passwort auf den neuen Wert.
-- Für neue Installationen: überschreibt den Default aus V41.

ALTER ROLE aster_app WITH PASSWORD '${ASTER_APP_PASSWORD}';
