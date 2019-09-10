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
    TimeDivision::Array{Int}
    function SearchParameters(typ::String,
                        min, max;
                        start = ((max-min)/2),
                        name::String = "",
                        index = 0,
                        departState = "",
                        corTarget = -1,
                        timeDiv::Array{Int} = [0, -1])
        NewPar = new()
        NewPar.Type = typ
        NewPar.Min = (typ==Types[3])? Float64(min):Int(min)
        NewPar.Max = (typ==Types[3])? Float64(max):Int(max)
        NewPar.StartVal = (typ==Types[3])? Float64(start):Int(round(start))
        NewPar.Name = name
        NewPar.Index = index
        NewPar.StartingState = departState
        NewPar.CorrelationTarget = corTarget
        NewPar.TimeDivision = timeDiv
        return NewPar
    end
end


global ParametersList = [SearchParameters("RecFlow", 20, 300, start = 150, index = 1, corTarget = 1, timeDiv = [1, 5, -1]),#[1, 5, 10, 15, 20, -1]
                         SearchParameters("RecFlow", 20, 300, start = 150, index = 2, corTarget = 1, timeDiv = [1, 5, -1]),
                         SearchParameters("RecFlow", 20, 300, start = 150, index = 3, corTarget = 1, timeDiv = [1, 5, -1]),
                         SearchParameters("RecFlow", 20, 300, start = 150, index = 4, corTarget = 1, timeDiv = [1, 5, -1]),
                         SearchParameters("RecFlow", 20, 300, start = 150, index = 5, corTarget = 2, timeDiv = [1, 5, -1]),
                         SearchParameters("RecFlow", 20, 300, start = 150, index = 6, corTarget = 2, timeDiv = [1, 5, -1]),
                         SearchParameters("RecFlow", 20, 300, start = 150, index = 7, corTarget = 2, timeDiv = [1, 5, -1]),
                         SearchParameters("RecFlow", 20, 300, start = 150, index = 8, corTarget = 2, timeDiv = [1, 5, -1]),
                         SearchParameters("RecFlow", 20, 300, start = 150, index = 9, corTarget = 3, timeDiv = [1, 5, -1]),
                         SearchParameters("RecFlow", 20, 300, start = 150, index = 10, corTarget = 3, timeDiv = [1, 5, -1]),
                         #SearchParameters("RecAge", 16, 32, start = 19, index = 1, corTarget = 1),
                         #SearchParameters("RecAge", 16, 32, start = 19, index = 2, corTarget = 1),
                         #SearchParameters("RecAge", 16, 32, start = 19, index = 3, corTarget = 3),
                         #SearchParameters("RecAge", 16, 32, start = 19, index = 4, corTarget = 3),
                         #SearchParameters("TransProba", 0.3, 0.8, start = 0.5, name = "B+", departState = "1A-D", corTarget = 4),
                         #SearchParameters("TransTenure", 3, 20, start = 12, name = "B+", departState = "1A-D", corTarget = 4),
                         #SearchParameters("TransProba", 0.3, 0.8, start = 0.5, name = "B+", departState = "1B-D", corTarget = 4),
                         #SearchParameters("TransTenure", 3, 20, start = 12, name = "B+", departState = "1B-D", corTarget = 4),
                         #SearchParameters("PEAge", 53, 70, start = 67, corTarget = 1)
                         ]
