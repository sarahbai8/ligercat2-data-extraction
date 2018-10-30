include("_vars.jl")
include("_helpers.jl")
include("_load-data.jl")
include("_populate-db.jl")

function doLoad(searchTerm::String, dbHost::String, dbName::String, dbUser::String, dbPassword::String)
    articleIdToSnpIds::Dict{String, Array{String}} = Dict()
    snpIdToGeneIds::Dict{String, Array{String}} = Dict()
    articleDetails::Array{Article} = []
    snpDetails::Array{SNP} = []
    geneDetails::Array{Gene} = []

    loadFromApi(searchTerm,
        articleIdToSnpIds=articleIdToSnpIds,
        snpIdToGeneIds=snpIdToGeneIds,
        articleDetails=articleDetails,
        snpDetails=snpDetails,
        geneDetails=geneDetails)
    populateDb(dbHost, dbName, dbUser, dbPassword,
        articleIdToSnpIds=articleIdToSnpIds,
        snpIdToGeneIds=snpIdToGeneIds,
        articleDetails=articleDetails,
        snpDetails=snpDetails,
        geneDetails=geneDetails)
end

doLoad(ARGS...)
