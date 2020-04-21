CREATE DATABASE IF NOT EXISTS traininig_akka_java_3_persistence;
USE traininig_akka_java_3_persistence;

DROP TABLE IF EXISTS journal;

CREATE TABLE IF NOT EXISTS journal (
  ordering SERIAL,
  persistence_id VARCHAR(255) NOT NULL,
  sequence_number BIGINT NOT NULL,
  deleted BOOLEAN DEFAULT FALSE NOT NULL,
  tags VARCHAR(255) DEFAULT NULL,
  message BLOB NOT NULL,
  PRIMARY KEY(persistence_id, sequence_number)
);

DROP TABLE IF EXISTS snapshot;

CREATE TABLE IF NOT EXISTS snapshot (
  persistence_id VARCHAR(255) NOT NULL,
  sequence_number BIGINT NOT NULL,
  created BIGINT NOT NULL,
  snapshot BLOB NOT NULL,
  PRIMARY KEY (persistence_id, sequence_number)
);