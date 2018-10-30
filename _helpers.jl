import DataStructures

# Helpers
# -------

function buildUrl(urlRoot::String, params::Dict = Dict())::String
    "$urlRoot?" * join(["$(escapeForUrl(kv[1]))=$(escapeForUrl(kv[2]))" for kv in params], "&")
end

function escapeForUrl(urlFragment)::String
    HTTP.Strings.escapehtml(replace("$urlFragment", r"\s", "+"))
end

function buildIdsAsSingle(ids)
    "&id=$(join(ids, ","))"
end

function buildIdsAsSeparate(ids)
    foldl((accum, val) -> accum * "&id=$(val)", "", ids)
end

function doForBatchViaGet(url::String, params::Dict;
    batchSize::Integer = 100, getCount::Function = identity, storeResults::Function = identity)

    thisAction = function(numProcessed::Integer, batchSize::Integer)
        response = HTTP.request(REST_VERB_GET, buildUrl(url, merge(params,
            Dict("retmax" => batchSize, "retstart" => numProcessed))))
        XMLDict.xml_dict(String(response.body))
    end
    doForBatch(batchSize = batchSize,
        initNumToProcess = () -> nothing,
        updateNumToProcess = resultDict -> getCount(resultDict),
        storeResults = storeResults,
        doAction = thisAction)
end

function doForBatchViaPost(url::String, ids::Array;
    batchSize::Integer = 100, buildBody::Function = identity, storeResults::Function = identity)

    thisAction = function(numProcessed::Integer, batchSize::Integer)
        response = HTTP.request(REST_VERB_POST, url, [],
            buildBody(sliceArray(ids, offset = numProcessed, batchSize = batchSize)),
            retry_non_idempotent=true)
        XMLDict.xml_dict(String(response.body))
    end
    doForBatch(batchSize = batchSize,
        initNumToProcess = () -> length(ids),
        storeResults = storeResults,
        doAction = thisAction)
end

function doForBatch(; batchSize::Integer = 100,
    initNumToProcess::Function = identity,
    updateNumToProcess::Function = identity,
    doAction::Function = identity,
    storeResults::Function = identity)

    numToProcess = initNumToProcess()
    numProcessed = 0

    while numToProcess == nothing || numToProcess > numProcessed
        info("\t starting batch of size $(batchSize), finished with $(numProcessed)")

        batchResult = doAction(numProcessed, batchSize)
        if updateNumToProcess != identity
            numToProcess = updateNumToProcess(batchResult)
        end
        storeResults(batchResult)
        numProcessed += batchSize
    end
end

function sliceArray(array::Array; offset::Integer = 0, batchSize::Integer = 10)
    array[offset + 1:min(length(array), offset + batchSize)]
end

# XML parsing helpers
# -------------------

function processForOneOrMany(action::Function, data)
    if isa(data, Array)
        foreach(action, data)
    else
        action(data)
    end
end

function xmlGetAt(val, path...; index = 1, key = "dictKey", default = "")
    didTravelPath, retVal = _xmlStepThroughPath(val, path..., default = default)
    if didTravelPath
        finalVal = isa(retVal, Array) ? retVal[index][key] : retVal[key]
        isempty(finalVal) ? default : finalVal
    else
        retVal
    end
end

function xmlGet(val, path...; default = "")
    didTravelPath, retVal = _xmlStepThroughPath(val, path..., default = default)
    didTravelPath ? _xmlGetFlatten(retVal, default) : retVal
end

function _xmlStepThroughPath(val, path...; default = "")
    finalVal = val
    for pathStep in path
        if _xmlGetIsDict(finalVal) && haskey(finalVal, pathStep)
            finalVal = finalVal[pathStep]
        else
            return false, default
        end
    end
    true, finalVal
end

function _xmlGetFlatten(val, default)
    if isempty(val)
        default
    elseif isa(val, Array)
        join(map(x -> _xmlGetFlatten(x, default), val), " ")
    elseif _xmlGetIsDict(val)
        join(map(x -> _xmlGetFlatten(x, default), values(val)), " ")
    else
        val
    end
end

function _xmlGetIsDict(val)
    isa(val, Dict) || isa(val, DataStructures.OrderedDict)
end
