import MySQL

function populateDb(dbHost::String, dbName::String, dbUser::String, dbPassword::String;
    articleIdToSnpIds::Dict{String, Array{String}} = Dict(),
    snpIdToGeneIds::Dict{String, Array{String}} = Dict(),
    articleDetails::Array{Article} = [],
    snpDetails::Array{SNP} = [],
    geneDetails::Array{Gene} = [])

    info("Connecting to the db using provided information...")
    connection = MySQL.connect(dbHost, dbUser, dbPassword, db = dbName)
    info("\t ...successfully connected")

    MySQL.execute!(connection, "START TRANSACTION;");
    try
        _doPopulateDb(connection,
            articleIdToSnpIds=articleIdToSnpIds,
            snpIdToGeneIds=snpIdToGeneIds,
            articleDetails=articleDetails,
            snpDetails=snpDetails,
            geneDetails=geneDetails)
        info("Commiting changes")
        MySQL.execute!(connection, "COMMIT;");
    catch x
        info("Rolling back changes")
        MySQL.execute!(connection, "ROLLBACK;");
        rethrow(x)
    finally
        info("Disconnecting from db...")
        MySQL.disconnect(connection)
        info("\t ...successfully disconnected")
    end
end

function _doPopulateDb(connection; articleIdToSnpIds::Dict{String, Array{String}} = Dict(),
    snpIdToGeneIds::Dict{String, Array{String}} = Dict(),
    articleDetails::Array{Article} = [],
    snpDetails::Array{SNP} = [],
    geneDetails::Array{Gene} = [])

    info("Inserting $(length(articleDetails)) rows into the `article` table...")
    articleStmt = MySQL.Stmt(connection, """
        INSERT INTO article(
            id,
            title,
            description,
            journal_name)
        VALUES(?, ?, ?, ?);""")
    for a in articleDetails
        MySQL.execute!(articleStmt, [
            a.id,
            a.title,
            a.description,
            a.journal])
    end
    info("\t ...done")

    info("Inserting $(length(snpDetails)) rows into the `snp` table...")
    snpStmt = MySQL.Stmt(connection, """
        INSERT INTO snp(
            id,
            chromosome_number,
            observed_bases)
        VALUES(?, ?, ?);""")
    for s in snpDetails
        MySQL.execute!(snpStmt, [
            s.id,
            s.chromosomeNumber,
            s.observedBases])
    end
    info("\t ...done")

    info("Inserting $(length(geneDetails)) rows into the `gene` table...")
    geneStmt = MySQL.Stmt(connection, """
        INSERT INTO gene(
            id,
            name,
            short_description,
            description,
            chromosome_number,
            location)
        VALUES(?, ?, ?, ?, ?, ?);""")
    for g in geneDetails
        MySQL.execute!(geneStmt, [
            g.id,
            g.name,
            g.shortDescription,
            g.description,
            g.chromosomeNumber,
            g.location])
    end
    info("\t ...done")

    info("Inserting into the `article_to_snp` table...")
    articleToSnpStmt = MySQL.Stmt(connection, """
        INSERT IGNORE INTO article_to_snp(
            article_id,
            snp_id)
        VALUES(?, ?);""")
    counter = 0
    for articleId in keys(articleIdToSnpIds)
        for snpId in unique(articleIdToSnpIds[articleId])
            MySQL.execute!(articleToSnpStmt, [articleId, snpId])
            counter += 1
        end
    end
    info("\t ...done inserting $(counter) rows")

    info("Inserting into the `snp_to_gene` table...")
    snpToGeneStmt = MySQL.Stmt(connection, """
        INSERT IGNORE INTO snp_to_gene(
            snp_id,
            gene_id)
        VALUES(?, ?);""")
    counter = 0
    for snpId in keys(snpIdToGeneIds)
        for geneId in unique(snpIdToGeneIds[snpId])
            MySQL.execute!(snpToGeneStmt, [snpId, geneId])
            counter += 1
        end
    end
    info("\t ...done inserting $(counter) rows")
end
