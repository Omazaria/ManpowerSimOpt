#addprocs(2)


include(joinpath( dirname( Base.source_path() ), "Functions", "sendto.jl"))
@everywhere include(joinpath( dirname( Base.source_path() ), myid()==1? "": "src", "Types", "Targets.jl"))
@everywhere include(joinpath( dirname( Base.source_path() ), myid()==1? "": "src", "Types", "Parameters.jl"))
include(joinpath( dirname( Base.source_path() ), "Functions", "LocalSearchManSim.jl")) #myid()==1? "": "src",

NbSimRunForEvaluation = 1
ProbaCrossOver =  function (iteration) 1/iteration end

ParametersListSLS = Array{StochasticSearch.Parameter,1}()

for i in 1:length(ParametersList)
    if ParametersList[i].Type == "TransProba"
        push!(ParametersListSLS, FloatParameter(Float64(ParametersList[i].Min), Float64(ParametersList[i].Max), Float64(ParametersList[i].StartVal), string(ParametersList[i].Type, i)))
    else
        if length(ParametersList[i].TimeDivision) > 2
            for div in 1:(length(ParametersList[i].TimeDivision) - 1)
                push!(ParametersListSLS, IntegerParameter(ParametersList[i].Min, ParametersList[i].Max, Int(round(ParametersList[i].StartVal)), string(ParametersList[i].Type, i, div)))
            end
        else
            push!(ParametersListSLS, IntegerParameter(ParametersList[i].Min, ParametersList[i].Max, Int(round(ParametersList[i].StartVal)), string(ParametersList[i].Type, i)))
        end
    end
end

cost_arg = Dict{Symbol, Any}(:targetList => targetList, :ParametersList => ParametersList, :ProbaCrossOver => ProbaCrossOver)


configuration = Configuration(ParametersListSLS,
                               "Manpower Recruitment Search")
tStart = now()
tuning_run = MPRun(cost             = mpSimSLS,
                 starting_point     = configuration,
                 cost_arguments     = cost_arg,
                 duration           = 250,
                 report_after       = 3000,
                 cost_evaluations   = NbSimRunForEvaluation,
                 methods            = [[:Test41_simulated_annealing 1];
                                       #[:Test42_simulated_annealing 1];
                                       #[:Test43_simulated_annealing 1];
                                       #[:Test44_simulated_annealing 1];
                                       #[:Test45_simulated_annealing 1];
                                       #[:Test46_simulated_annealing 1];
                                       #[:Test47_simulated_annealing 1];
                                       #[:Test48_simulated_annealing 1];
                                      #[:iterative_first_improvement 1];
                                      #[:MPsimulated_annealing 1];
                                      #[:simulated_annealing 1];
                                      #[:randomized_first_improvement 1];
                                      #[:iterative_greedy_construction 1];
                                      #[:iterative_probabilistic_improvement 1];
                                      ])


BestSolsEval = Array{Any,1}()
search_task = @task optimize(tuning_run, BestSolsEval)
result = consume(search_task)

print(result)
while result.is_final == false
    result = consume(search_task)
    print(result)
end

tEnd = now()
timeElapsed = (tEnd - tStart).value / 1000
println( "Search ended: $timeElapsed seconds." )
try
#    interrupt(workers())
end


plot(BestSolsEval)

#include(joinpath( dirname( Base.source_path() ), "Functions", "AfterRunSLS.jl"))
