import HTTP
import XMLDict

function loadFromApi(searchTerm::String; articleIdToSnpIds::Dict{String, Array{String}} = Dict(),
    snpIdToGeneIds::Dict{String, Array{String}} = Dict(),
    articleDetails::Array{Article} = [],
    snpDetails::Array{SNP} = [],
    geneDetails::Array{Gene} = [])

    articleIds::Array{String} = []
    snpIds::Array{String} = []
    geneIds::Array{String} = []

    # getting articleIds from ESearch given the search term
    info("Getting initial PMID list for query `$(searchTerm)`...")
    doForBatchViaGet(ESEARCH_URL, Dict("db" => DB_PUBMED, "term" => searchTerm, "retmode" => "xml"),
        batchSize = ESEARCH_BATCH_SIZE,
        getCount = (resultDict -> parse(Int16, resultDict["eSearchResult"]["Count"])),
        storeResults = (resultDict -> append!(articleIds, resultDict["eSearchResult"]["IdList"]["Id"])))
    articleIds = unique(articleIds)
    info("\t ...retrieved $(length(articleIds)) articles")

    # from articleIds list, use ELink to find the the snp ids associated with each articleId
    info("Linking PMIDs to SNPs...")
    doForBatchViaPost(buildUrl(ELINK_URL,
            Dict("dbFrom" => DB_PUBMED, "db" => DB_SNP, "linkname" => LINK_PUBMED_SNP, "retmode" => "xml")),
        articleIds,
        batchSize = ELINK_BATCH_SIZE,
        buildBody = buildIdsAsSeparate,
        storeResults = (resultDict -> processForOneOrMany((x -> processLinkSet(x, dataDict = articleIdToSnpIds)),
            resultDict["eLinkResult"]["LinkSet"])))
    info("\t ...found SNP associations for $(length(articleIdToSnpIds)) PMIDs")
    snpIds = isempty(articleIdToSnpIds) ? [] :
        unique(collect(Iterators.flatten(values(articleIdToSnpIds))))
    info("\t ...found $(length(snpIds)) associated SNPs")

    # from snp ids list, use ELink to find the gene id associated with each snp id
    info("Linking SNPs to genes...")
    doForBatchViaPost(buildUrl(ELINK_URL,
        Dict("dbFrom" => DB_SNP, "db" => DB_GENE, "linkname" => LINK_SNP_GENE, "retmode" => "xml")),
        snpIds,
        batchSize = ELINK_BATCH_SIZE,
        buildBody = buildIdsAsSeparate,
        storeResults = (resultDict -> processForOneOrMany((x -> processLinkSet(x, dataDict = snpIdToGeneIds)),
            resultDict["eLinkResult"]["LinkSet"])))
    info("\t ...found gene associations for $(length(snpIdToGeneIds)) SNPs")
    geneIds = isempty(snpIdToGeneIds) ? [] :
        unique(collect(Iterators.flatten(values(snpIdToGeneIds))))
    info("\t ...found $(length(geneIds)) associated genes")

    # get article details using EFetch
    info("Getting details for $(length(articleIds)) PMIDs...")
    doForBatchViaPost(buildUrl(EFETCH_URL, Dict("db" => DB_PUBMED, "retmode" => "xml")),
        articleIds,
        batchSize = ELINK_BATCH_SIZE,
        buildBody = buildIdsAsSingle,
        storeResults = (resultDict -> processForOneOrMany((x -> processArticle(x, array = articleDetails)),
            resultDict["PubmedArticleSet"]["PubmedArticle"])))
    info("\t ...retrieved details for $(length(articleDetails)) PMIDs")

    # get SNP details using EFetch
    info("Getting details for $(length(snpIds)) SNPs...")
    doForBatchViaPost(buildUrl(EFETCH_URL, Dict("db" => DB_SNP, "retmode" => "xml")), snpIds,
        batchSize = ELINK_BATCH_SIZE,
        buildBody = buildIdsAsSingle,
        storeResults = (resultDict -> processForOneOrMany((x -> processSnp(x, array = snpDetails)),
            resultDict["ExchangeSet"]["Rs"])))
    info("\t ...retrieved details for $(length(snpDetails)) SNPs")

    # get gene details using ESummary
    info("Getting details for $(length(geneIds)) genes...")
    doForBatchViaPost(buildUrl(ESUMMARY_URL, Dict("db" => DB_GENE, "retmode" => "xml")), geneIds,
        batchSize = ESUMMARY_BATCH_SIZE,
        buildBody = buildIdsAsSingle,
        storeResults = (resultDict -> processForOneOrMany((x -> processGene(x, array = geneDetails)),
            resultDict["eSummaryResult"]["DocumentSummarySet"]["DocumentSummary"])))
    info("\t ...retrieved details for $(length(geneDetails)) genes")
end

# Helpers
# -------

function processLinkSet(linkSet; dataDict::Dict = Dict())
    thisId = linkSet["IdList"]["Id"]
    if haskey(linkSet, "LinkSetDb")
        processedIds = []
        processForOneOrMany(x -> push!(processedIds, "$(x["Id"])"), linkSet["LinkSetDb"]["Link"])
        dataDict[thisId] = append!(get(dataDict, thisId, []), processedIds)
    end
end

function processArticle(article; array::Array{Article} = [])
    aInfo = article["MedlineCitation"]["Article"]

    aId = xmlGet(article, "MedlineCitation", "PMID", "") # don't want to include the version attribute
    title = xmlGet(aInfo, "ArticleTitle")
    desc = xmlGet(aInfo, "Abstract", "AbstractText")
    journal = xmlGet(aInfo, "Journal", "Title")

    push!(array, Article(aId, title, desc, journal))
end

function processSnp(snp; array::Array{SNP} = [])
    snpId = snp[:rsId]
    chromosomeNumber = xmlGetAt(snp, "Assembly", "Component",
        index = 1, key = :chromosome, default = "0")
    observedBases = xmlGet(snp, "Sequence", "Observed")

    push!(array, SNP(snpId, chromosomeNumber, observedBases))
end

function processGene(gene; array::Array{Gene} = [])
    geneId = gene[:uid]
    name = xmlGet(gene, "Name")
    shortDescription = xmlGet(gene, "Description")
    description = xmlGet(gene, "Summary")
    chromosomeNumber = xmlGet(gene, "Chromosome", default="0")
    location = xmlGet(gene, "MapLocation")

    push!(array, Gene(geneId, name, shortDescription, description, chromosomeNumber, location))
end
