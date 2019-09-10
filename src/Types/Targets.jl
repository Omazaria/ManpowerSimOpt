#@everywhere
mutable struct  Target
    StateName::String
    Value::Int
    StartYear::Int
    CompletionRate::Float64
    CoefCostFunc::Number
    function Target(name::String, val::Int, year::Int, rate::Float64; CostFuncCoef = 1)
        new(name, val, year, rate, CostFuncCoef)
    end
end

global targetList = [   Target("Officers", 7400, 7, 0.1),
                        Target("NonComOfficers", 10500, 7, 0.1),
                        Target("volunteers", 6000, 7, 0.1),
                        #Target("NCOff", 9293, 7, 0.1),
                        #Target("Vol", 8502, 7, 0.1)
                        ]


# global targetList = [   Target("AdOff", 2583, 7, 0.1),
#                         Target("Off", 1281, 7, 0.1),
#                         Target("AdNCOff", 582, 7, 0.1),
#                         Target("NCOff", 9293, 7, 0.1),
#                         Target("Vol", 8502, 7, 0.1)
#                         ]

# global targetList = [   #Target("active", 22241, 7, 0.1, CostFuncCoef = 0),
#                         Target("AdOff", 2583, 7, 0.),
#                         Target("Off", 1281, 7, 0.),
#                         Target("AdNCOff", 582, 7, 0.),
#                         Target("NCOff", 9293, 7, 0.),
#                         Target("Vol", 8502, 7, 0.),
#                         #Target("BDL", 1740, 7, 0.0),
#                         #Target("BO", 2120, 7, 0.0)
#                         ]
