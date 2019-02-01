#@everywhere
mutable struct  Target
    StateName::String
    Value::Int
    StartYear::Int
    CompletionRate::Float64
    function Target(name::String, val::Int, year::Int, rate::Float64)
        new(name, val, year, rate)
    end
end


global targetList = [   Target("active", 3860, 7, 0.8),
                        Target("AdOff", 2580, 7, 0.8),
                        Target("Off", 1280, 7, 0.8),
                        Target("BDL", 1740, 7, 0.8),
                        Target("BO", 2120, 7, 0.8)]
