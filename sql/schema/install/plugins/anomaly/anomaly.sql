CREATE TABLE anomaly (
    id BIGINT NOT NULL,
    source TEXT NOT NULL,
    score integer NOT NULL DEFAULT 0,
    checks TEXT[],
    results JSONB
) WITH ( OIDS = FALSE );
