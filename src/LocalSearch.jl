addprocs(4)


include(joinpath( dirname( Base.source_path() ), "Functions", "sendto.jl"))
@everywhere include(joinpath( dirname( Base.source_path() ), myid()==1? "": "src", "Types", "Targets.jl"))
@everywhere include(joinpath( dirname( Base.source_path() ), myid()==1? "": "src", "Types", "Parameters.jl"))
include(joinpath( dirname( Base.source_path() ), "Functions", "LocalSearchManSim.jl")) #myid()==1? "": "src",

ParametersListSLS = Array{StochasticSearch.Parameter,1}()

for i in 1:length(ParametersList)
    if ParametersList[i].Type == "TransProba"
        push!(ParametersListSLS, FloatParameter(Float64(ParametersList[i].Min), Float64(ParametersList[i].Max), Float64(ParametersList[i].StartVal), string(ParametersList[i].Type, i)))
    else
        push!(ParametersListSLS, IntegerParameter(ParametersList[i].Min, ParametersList[i].Max, Int(round(ParametersList[i].StartVal)), string(ParametersList[i].Type, i)))
    end
end

cost_arg = Dict{Symbol, Any}(:targetList => targetList, :ParametersList => ParametersList)


configuration = Configuration(ParametersListSLS,
                               "Manpower Recruitment Search")
tStart = now()
tuning_run = Run(cost               = mpSimSLS,
                 starting_point     = configuration,
                 cost_arguments     = cost_arg,
                 duration           = 50,
                 report_after       = 20,
                 methods            = [[:simulated_annealing 1];
                                      #[:iterative_first_improvement 1];
                                      [:simulated_annealing 1];
                                      [:simulated_annealing 1];
                                      [:simulated_annealing 1];
                                      [:simulated_annealing 1];
                                      #[:randomized_first_improvement 1];
                                      #[:iterative_greedy_construction 1];
                                      #[:iterative_probabilistic_improvement 1];
                                      ])

search_task = @task optimize(tuning_run)
result = consume(search_task)

print(result)
while result.is_final == false
    result = consume(search_task)
    print(result)
end

tEnd = now()
timeElapsed = (tEnd - tStart).value / 1000
println( "Search ended: $timeElapsed seconds." )


mpSim = InitMpSim


for i in 1:length(ParametersList)
    if ParametersList[i].Type == "RecFlow"
        # Set recruitment flows
        setRecruitmentFixed(mpSim.recruitmentSchemes[ParametersList[i].Index], result.minimum.parameters[string(ParametersList[i].Type, i)].value)
    elseif ParametersList[i].Type == "RecAge"
        # Set recruitment age
        mpSim.recruitmentSchemes[ParametersList[i].Index].ageDist = function () return 12*(result.minimum.parameters[string(ParametersList[i].Type, i)].value) end
    elseif ParametersList[i].Type == "TransProba"
        for TransTuple in mpSim.otherStateList
            if !contains(TransTuple[1].name, ParametersList[i].StartingState)
                continue
            end
            for j in 1:length(TransTuple[2])
                if TransTuple[2][j].name ==ParametersList[i].Name
                    TransTuple[2][j].probabilityList = [result.minimum.parameters[string(ParametersList[i].Type, i)].value]
                end
            end
        end
    elseif ParametersList[i].Type == "TransTenure"
        for TransTuple in mpSim.otherStateList
            if !contains(TransTuple[1].name, ParametersList[i].StartingState)
                continue
            end
            for j in 1:length(TransTuple[2])
                if TransTuple[2][j].name ==ParametersList[i].Name
                    TransTuple[2][j].extraConditions[1].val = 12*(result.minimum.parameters[string(ParametersList[i].Type, i)].value)
                end
            end
        end
    elseif ParametersList[i].Type == "PEAge"
        # Retirement Age
        mpSim.retirementScheme.retireAge = 12*(result.minimum.parameters[string(ParametersList[i].Type, i)].value)
    end
end

tStart = now()
println("Running... ")
#ExecNb += 1
mpSim.simDB = SQLite.DB( "" )
resetSimulation(mpSim)
run( mpSim )


configFileName = joinpath( dirname( Base.source_path() ), "..", "Data", "SIMULdemo.xlsx")
plotSimResults(mpSim, configFileName)

score = Dict{String, Any}()

for i in 1:length(targetList)
    score[targetList[i].StateName] = zeros(2)
    fluxInCounts    =  generateFluxReport( mpSim, 12,  true, targetList[i].StateName)
    fluxOutCounts   =  generateFluxReport( mpSim, 12, false, targetList[i].StateName)
    personnelCounts = generateCountReport( mpSim, targetList[i].StateName, fluxInCounts, fluxOutCounts )

    for j in targetList[i].StartYear:length(personnelCounts[Symbol(targetList[i].StateName)])
        tempo = personnelCounts[Symbol(targetList[i].StateName)][j] - targetList[i].Value
        if tempo > 0
            score[targetList[i].StateName][1] += tempo
        else
            score[targetList[i].StateName][2] += tempo
        end
    end
end
