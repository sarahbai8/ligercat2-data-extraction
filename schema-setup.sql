-- Creating db schema for bidirection search data loading script

CREATE DATABASE IF NOT EXISTS bidirectional_search
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE bidirectional_search;

DROP PROCEDURE IF EXISTS build_bidirectional_search_schema;

DELIMITER $$

CREATE PROCEDURE build_bidirectional_search_schema()
BEGIN
    DECLARE has_error INTEGER DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            SET has_error = 1;
            SHOW ERRORS;
        END;

    START TRANSACTION;

    CREATE TABLE IF NOT EXISTS article(
        id VARCHAR(190) NOT NULL PRIMARY KEY,
        title TEXT DEFAULT NULL,
        description TEXT DEFAULT NULL,
        journal_name VARCHAR(255) DEFAULT NULL
    ) ENGINE=InnoDb ROW_FORMAT=DYNAMIC;

    CREATE TABLE IF NOT EXISTS snp(
        id VARCHAR(190) NOT NULL PRIMARY KEY,
        chromosome_number VARCHAR(255) DEFAULT NULL,
        observed_bases VARCHAR(255) DEFAULT NULL
    ) ENGINE=InnoDb ROW_FORMAT=DYNAMIC;

    CREATE TABLE IF NOT EXISTS gene(
        id VARCHAR(190) NOT NULL PRIMARY KEY,
        name VARCHAR(255) DEFAULT NULL,
        short_description TEXT DEFAULT NULL,
        description TEXT DEFAULT NULL,
        chromosome_number VARCHAR(255) DEFAULT NULL,
        location VARCHAR(255) DEFAULT NULL
    ) ENGINE=InnoDb ROW_FORMAT=DYNAMIC;

    CREATE TABLE IF NOT EXISTS article_to_snp(
        article_id VARCHAR(190) NOT NULL,
        snp_id VARCHAR(190) NOT NULL,
        PRIMARY KEY(article_id, snp_id),
        FOREIGN KEY(article_id) REFERENCES article(id),
        FOREIGN KEY(snp_id) REFERENCES snp(id)
    ) ENGINE=InnoDb ROW_FORMAT=DYNAMIC;

    CREATE TABLE IF NOT EXISTS snp_to_gene(
        snp_id VARCHAR(190) NOT NULL,
        gene_id VARCHAR(190) NOT NULL,
        PRIMARY KEY(snp_id, gene_id),
        FOREIGN KEY(snp_id) REFERENCES snp(id),
        FOREIGN KEY(gene_id) REFERENCES gene(id)
    ) ENGINE=InnoDb ROW_FORMAT=DYNAMIC;

    IF has_error = 1 THEN
        ROLLBACK;
    ELSE
        COMMIT;
        SELECT "Successfully created schema";
    END IF;
END $$

DELIMITER ;

CALL build_bidirectional_search_schema();
