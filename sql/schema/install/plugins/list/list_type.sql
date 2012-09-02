CREATE TABLE list_type
(
  id serial NOT NULL,
  "name" character varying(80) NOT NULL,
  score smallint NOT NULL DEFAULT 0 CONSTRAINT list_type_score CHECK ( score >= 0 AND score <= 10 ),
  CONSTRAINT list_type_pkey PRIMARY KEY (id),
  CONSTRAINT list_type_uniq UNIQUE (name)
)
WITH (
  OIDS=FALSE
);

INSERT INTO list_type ( "name", score ) VALUES ( 'safe', 0 );
INSERT INTO list_type ( "name", score ) VALUES ( 'adware', 5 );
INSERT INTO list_type ( "name", score ) VALUES ( 'malicious', 10 );
