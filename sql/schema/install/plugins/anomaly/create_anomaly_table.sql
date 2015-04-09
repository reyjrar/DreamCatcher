CREATE OR REPLACE FUNCTION create_anomaly_table(
    in_source_table TEXT
)
RETURNS boolean AS $BODY$
DECLARE
    var_tablename TEXT := 'anomaly_' || in_source_table;
BEGIN

    -- Need the source table to exist
    IF NOT EXISTS (SELECT relname FROM pg_class where relname = in_source_table) THEN
        RAISE EXCEPTION 'Source table "%" does not exist.', in_source_table;
    END IF;

    -- Nothing to see here.
    IF EXISTS (SELECT relname FROM pg_class WHERE relname = var_tablename) THEN
        RETURN FALSE;
    END IF;

    EXECUTE format('CREATE TABLE %I (
            CHECK( source = % ),
            PRIMARY KEY (source, id)
        ) INHERITS (anomaly)',
        var_tablename, in_source_table
    );

    -- Standard Index
    EXECUTE format('CREATE INDEX %I ON %I (id)', 'idx_' || var_tablename || 'id', var_tablename);

    -- Functional Indexes
    EXECUTE format('CREATE INDEX %I ON %I USING gin (results)', 'gin_' || var_tablename, var_tablename);

    -- Foreign Keys
    EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (id)
                REFERENCES %I (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE',
            var_tablename,
            'fki_' || var_tablename || '_source',
            in_source_table
    );

    RETURN TRUE;
END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

