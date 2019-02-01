Types = ["RecFlow", "RecAge", "TransProba", "TransTenure", "PEAge"]

#@everywhere
mutable struct SearchParameters
    Type::String
    Name::String
    Index::Int
    Min
    Max
    StartVal
    StartingState::String
    CorrelationTarget::Int
    function SearchParameters(typ::String,
                        min, max;
                        start = ((max-min)/2),
                        name::String = "",
                        index = 0,
                        departState = "",
                        corTarget = -1)
        NewPar = new()
        NewPar.Type = typ
        NewPar.Min = (typ==Types[3])? Float64(min):Int(min)
        NewPar.Max = (typ==Types[3])? Float64(max):Int(max)
        NewPar.StartVal = (typ==Types[3])? Float64(start):Int(round(start))
        NewPar.Name = name
        NewPar.Index = index
        NewPar.StartingState = departState
        NewPar.CorrelationTarget = corTarget
        return NewPar
    end
end


global ParametersList = [ SearchParameters("RecFlow", 0, 500, start = 100, index = 1, corTarget = 2),
                         SearchParameters("RecFlow", 0, 500, start = 100, index = 2, corTarget = 2),
                         SearchParameters("RecFlow", 0, 500, start = 100, index = 3, corTarget = 3),
                         SearchParameters("RecFlow", 0, 500, start = 100, index = 4, corTarget = 3),
                         SearchParameters("RecAge", 16, 32, start = 19, index = 1, corTarget = 1),
                         SearchParameters("RecAge", 16, 32, start = 19, index = 2, corTarget = 1),
                         SearchParameters("RecAge", 16, 32, start = 19, index = 3, corTarget = 3),
                         SearchParameters("RecAge", 16, 32, start = 19, index = 4, corTarget = 3),
                         SearchParameters("TransProba", 0.0, 1.0, start = 0.5, name = "B+", departState = "1A-D", corTarget = 4),
                         SearchParameters("TransTenure", 1, 25, start = 12, name = "B+", departState = "1A-D", corTarget = 4),
                         SearchParameters("TransProba", 0.0, 1.0, start = 0.5, name = "B+", departState = "1B-D", corTarget = 4),
                         SearchParameters("TransTenure", 1, 25, start = 12, name = "B+", departState = "1B-D", corTarget = 4),
                         SearchParameters("PEAge", 45, 70, start = 67, corTarget = 1)]
