# Constants
# ---------

const REST_VERB_GET = "GET"
const REST_VERB_POST = "POST"

const ENTREZ_URL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
const ESEARCH_URL = "$ENTREZ_URL/esearch.fcgi"
const ELINK_URL = "$ENTREZ_URL/elink.fcgi"
const EFETCH_URL = "$ENTREZ_URL/efetch.fcgi"
const ESUMMARY_URL = "$ENTREZ_URL/esummary.fcgi"

const DB_PUBMED = "pubmed"
const DB_SNP = "snp"
const DB_GENE = "gene"

const LINK_PUBMED_SNP = "pubmed_snp"
const LINK_SNP_GENE = "snp_gene"

const ESEARCH_BATCH_SIZE = 90000
const ELINK_BATCH_SIZE = 4000
const EFETCH_BATCH_SIZE = 8000
const ESUMMARY_BATCH_SIZE = 8000

# Object detail structs
# ---------------------

struct Article
    id::String
    title::String
    description::String
    journal::String
end

struct SNP
    id::String
    chromosomeNumber::String
    observedBases::String
end

struct Gene
    id::String
    name::String
    shortDescription::String
    description::String
    chromosomeNumber::String
    location::String
end
