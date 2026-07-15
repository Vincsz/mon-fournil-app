-- Procédure 2 : création de la table de travail à partir de la table
-- d'origine import_test1 (supposée existante).
--   CALL create_travail();
-- Règles rules.md — comparaisons insensibles à la casse :
--   Lignes APSQL / TOTO2I : chercher les lignes TOTBAS ayant le même
--   asset_dmzr (7 premiers caractères).
--     - trouvées avec un codeBusiness unique  -> ce codeBusiness
--     - trouvées avec plusieurs codes         -> ERROR_MULTIPLE_CODES_APP
--     - aucune ligne trouvée                  -> codeBusiness d'origine
--   Autres lignes : codeBusinessNew = codeBusiness d'origine.
--   codeBusinessNew est toujours inséré en MAJUSCULES.

CREATE OR REPLACE PROCEDURE create_travail()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS travail_test1;

    CREATE TABLE travail_test1 (
        id                BIGINT PRIMARY KEY REFERENCES import_test1(id) ON DELETE CASCADE,
        "codeBusiness"    TEXT,
        "cost center"     TEXT,
        "metrique code"   TEXT,
        "offre"           TEXT,
        "asset_dmzr"      TEXT,
        "database"        TEXT,
        "volume"          TEXT,
        "prix"            TEXT,
        "env"             TEXT,
        "codeBusinessNew" TEXT
    );

    INSERT INTO travail_test1
    SELECT
        i.id,
        i."codeBusiness",
        i."cost center",
        i."metrique code",
        i."offre",
        i."asset_dmzr",
        i."database",
        i."volume",
        i."prix",
        i."env",
        UPPER(CASE
            WHEN UPPER(i."codeBusiness") = 'APSQL' AND UPPER(i."cost center") = 'TOTO2I'
                THEN COALESCE(m.code, i."codeBusiness")
            ELSE i."codeBusiness"
        END)
    FROM import_test1 i
    LEFT JOIN (
        SELECT UPPER(LEFT("asset_dmzr", 7)) AS asset7,
               CASE WHEN COUNT(DISTINCT UPPER("codeBusiness")) = 1 THEN MIN("codeBusiness")
                    ELSE 'ERROR_MULTIPLE_CODES_APP'
               END AS code
        FROM import_test1
        WHERE UPPER("cost center") = 'TOTBAS'
        GROUP BY UPPER(LEFT("asset_dmzr", 7))
    ) m ON m.asset7 = UPPER(LEFT(i."asset_dmzr", 7));

    RAISE NOTICE 'Table de travail créée : % lignes',
        (SELECT count(*) FROM travail_test1);
END;
$$;
