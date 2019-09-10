
function optimize(tuning_run::MPRun, BestSolsEval::Array{Any})
    stopping_criterion  = @task tuning_run.stopping_criterion(tuning_run.duration)
    #reporting_criterion = @task tuning_run.reporting_criterion(tuning_run.report_after)
    stop                = false#consume(stopping_criterion)
    results             = initialize_search_tasks!(tuning_run)
    best                = get_new_best(results)
    iteration           = 1
    start_time          = time()
    produce(best)
    NoBestCount = 0
    while !stop
        best                    = get_new_best(results, best)
        if !(best.cost_minimum in BestSolsEval)
            push!(BestSolsEval, best.cost_minimum)
        end
        iteration              += 1
        best.current_iteration  = iteration
        #stop                    = consume(stopping_criterion)
        if length(BestSolsEval) > tuning_run.duration
            stop = true
            NoBestCount = 0
        else
            NoBestCount += 1
            if NoBestCount > tuning_run.report_after
                stop = true
            end
        end
        if stop
            best.is_final     = true
            best.current_time = time() - start_time
            open("C:/SLS/SLSBestSols$(myid()).txt", "w") do io
               writedlm(io, BestSolsEval)
           end
            produce(best)
        #elseif consume(reporting_criterion)
        #    best.current_time = time() - start_time
        #    produce(best)
        end
    end
end

function initialize_search_tasks!(tuning_run::MPRun)
    next_proc      = @task chooseproc()

    instance_id    = 1
    results        = RemoteChannel[]

    tuning_run.cost_values    = zeros(tuning_run.cost_evaluations)

    tuning_run.starting_cost, tuning_run.Fitness = tuning_run.measurement_method(tuning_run,
                                                              tuning_run.starting_point)

    initial_result            = MPResult("Initialize",
                                       tuning_run.starting_point,
                                       tuning_run.starting_point,
                                       tuning_run.starting_cost,
                                       1, 1, 1, false, tuning_run.Fitness)
    for i = 1:size(tuning_run.methods, 1)
        for j = 1:tuning_run.methods[i, 2]
            worker = consume(next_proc)
            push!(results, RemoteChannel(() -> MPResultChannel(deepcopy(initial_result)), worker))

            reference = results[instance_id]
            remotecall(eval(tuning_run.methods[i, 1]), worker,
                       deepcopy(tuning_run), reference)
            instance_id += 1
        end
    end
    results
end

function FindParmeterIndex(tuning_run::MPRun, key::String)
    ParametersList= tuning_run.cost_arguments[:ParametersList]
    for i in 1:length(ParametersList)
        if ((ParametersList[i].Type == "RecFlow" || ParametersList[i].Type == "RecAge") && length(ParametersList[i].TimeDivision) > 2)
            for div in 1:(length(ParametersList[i].TimeDivision)-1)
                if string(ParametersList[i].Type, i, div) == key
                    return i
                end
            end
        elseif string(ParametersList[i].Type, i) == key
            return i
        end
    end
    return -1
end

function neighbor!(configuration::Configuration, tuning_run::MPRun; distance::Int = 1)

    targetList    = tuning_run.cost_arguments[:targetList]
    ParametersList= tuning_run.cost_arguments[:ParametersList]

    key_set = collect(keys(configuration.parameters))
    NbVaribleMutate = rand(Float64)

    if NbVaribleMutate <= 0.5
        NbVaribleMutate = 1
    elseif NbVaribleMutate <= 0.8
        NbVaribleMutate = 2
    else
        NbVaribleMutate = 3
    end
    for mutVar in 1:NbVaribleMutate
        target  = key_set[rand(1:length(key_set))]
        for i = 1:distance
            if rand() < 0.5#0.5
                if !(typeof(configuration[target]) <: StringParameter)
                    neighbor!(configuration[target])
                end
            else
                ParamIndex = FindParmeterIndex(tuning_run, target)
                fit = tuning_run.Fitness[targetList[ParametersList[ParamIndex].CorrelationTarget].StateName]
                signFitness = (fit[1] > abs(fit[2]))? (fit[1]/abs(fit[1])): (fit[2]/abs(fit[2]))
                min = 0
                max = 0
                if typeof(configuration.parameters[target].min) <: Integer
                    min = Int(round(configuration.parameters[target].min*0.3))
                    max = Int(round(configuration.parameters[target].max*0.3))
                else
                    min = configuration.parameters[target].min*0.3
                    max = configuration.parameters[target].max*0.3
                end
                addedval = 0
                while addedval == 0
                    addedval = rand_in(min, max)
                end
                newVal = typeof(configuration.parameters[target].max)(configuration[target].value + signFitness*addedval)

                newVal = (newVal < configuration.parameters[target].min)? configuration.parameters[target].min:newVal#max(min(newVal, configuration.parameters[target].max), configuration.parameters[target].min)
                newVal = (newVal > configuration.parameters[target].max)? configuration.parameters[target].max:newVal

                configuration[target].value = newVal
            end
        end
    end
    update!(configuration)
    configuration
end

function MPprobabilistic_improvement(tuning_run::MPRun;
                                   threshold::AbstractFloat = 2.,
                                   acceptance_criterion::Function = metropolis)
    initial_cost  = tuning_run.starting_cost
    x             = deepcopy(tuning_run.starting_point)
    fitness       = deepcopy(tuning_run.Fitness)
    x_proposal    = deepcopy(tuning_run.starting_point)
    name          = "MP Probabilistic Improvement $(myid())"
    cost_calls    = 0
    iteration     = 1

    neighbor!(x_proposal, )#tuning_run

    proposal, fitness_proposal      = @fetch (tuning_run.measurement_method(tuning_run, x_proposal))
    #println("In $name ", initial_cost)
    #println("proposal : ", proposal)
    #println("fitness_proposal ", fitness_proposal)
    cost_calls   += tuning_run.cost_evaluations
    if acceptance_criterion(threshold, initial_cost, proposal)
        update!(x, x_proposal.parameters)
        fitness = deepcopy(fitness_proposal)
        initial_cost = proposal
    end
    MPResult(name, tuning_run.starting_point, x, initial_cost, iteration,
           iteration, cost_calls, false, fitness)
end

function GenerateRandomRun(tuning_run::MPRun)

    x_proposal    = deepcopy(tuning_run.starting_point)
    name          = "Random Generation $(myid())"
    cost_calls    = 0
    iteration     = 1

    for key in keys(x_proposal.parameters)
        x_proposal[key].value = rand_in(x_proposal.parameters[key].min, x_proposal.parameters[key].max)#x_proposal.parameters[key].val
    end
    initial_cost, fitness      = @fetch (tuning_run.measurement_method(tuning_run, x_proposal))
    cost_calls   += tuning_run.cost_evaluations

    update!(x_proposal)
    MPResult(name, tuning_run.starting_point, x_proposal, initial_cost, iteration,
           iteration, cost_calls, false, fitness)
end

function LinearExtension(X1::AbstractFloat, Y1::Number, X2::AbstractFloat, Y2::Number)
    return (X1 - ((X2 - X1)/(Y2 - Y1))*Y1)
end

function LinearExtension(X1::Integer, Y1::Number, X2::Integer, Y2::Number)
    return Int(round(X1 - ((X2 - X1)/(Y2 - Y1))*Y1))
end

function LinearExtension(X1::AbstractFloat, Y1::Array{Float64,1}, X2::AbstractFloat, Y2::Array{Float64,1})
    if X1 == X2
        return X1
    end

    y1 = (Y1[1] > abs(Y1[2]))? Y1[1] : Y1[2]
    y2 = (Y2[1] > abs(Y2[2]))? Y2[1] : Y2[2]
    if y1 == y2
        return (rand()<0.5)? X1 : X2
    end
    return (X1 - ((X2 - X1)/(y2 - y1))*y1)
end

function LinearExtension(X1::Integer, Y1::Array{Float64,1}, X2::Integer, Y2::Array{Float64,1})
    if X1 == X2
        return X1
    end

    y1 = (Y1[1] > abs(Y1[2]))? Y1[1] : Y1[2]
    y2 = (Y2[1] > abs(Y2[2]))? Y2[1] : Y2[2]
    if y1 == y2
        return (rand()<0.5)? X1 : X2
    end
    return Int(round(X1 - ((X2 - X1)/(y2 - y1))*y1))
end

function Crossover(tuning_run::MPRun, Config1::Configuration, cost1::Number, Config2::Configuration, cost2::Number)

    CrossConfig = deepcopy(Config1)
    name          = "Crossover $(myid())"
    cost_calls    = 0
    iteration     = 1

    #Crossover___________________
    for key in keys(CrossConfig.parameters)
        CrossConfig.value[key] = max(min(LinearExtension(Config1.value[key],
                                                         cost1,
                                                         Config2.value[key],
                                                         cost2),
                                                         CrossConfig.parameters[key].max),
                                                         CrossConfig.parameters[key].min)
    end
    #____________________________

    initial_cost, fitness      = @fetch (tuning_run.measurement_method(tuning_run, CrossConfig))
    cost_calls       += tuning_run.cost_evaluations

    MPResult(name, tuning_run.starting_point, CrossConfig, initial_cost, iteration,
           iteration, cost_calls, false, fitness)
end

function Crossover(tuning_run::MPRun, Config1::Configuration, fitness1::Dict{String, Any}, Config2::Configuration, fitness2::Dict{String, Any})

    CrossConfig = deepcopy(Config1)
    name          = "Crossover $(myid())"
    cost_calls    = 0
    iteration     = 1
    targetList    = tuning_run.cost_arguments[:targetList]
    ParametersList= tuning_run.cost_arguments[:ParametersList]

    #Crossover___________________
    for i in 1:length(ParametersList)

        if ((ParametersList[i].Type == "RecFlow" || ParametersList[i].Type == "RecAge") && length(ParametersList[i].TimeDivision) > 2)
            for div in 1:(length(ParametersList[i].TimeDivision)-1)
                CrossConfig[string(ParametersList[i].Type, i, div)].value = max(min(LinearExtension(Config1.value[string(ParametersList[i].Type, i, div)],
                                                                                                     fitness1[targetList[ParametersList[i].CorrelationTarget].StateName],
                                                                                                     Config2.value[string(ParametersList[i].Type, i, div)],
                                                                                                     fitness2[targetList[ParametersList[i].CorrelationTarget].StateName]),
                                                                                                     CrossConfig.parameters[string(ParametersList[i].Type, i, div)].max),
                                                                                                     CrossConfig.parameters[string(ParametersList[i].Type, i, div)].min)
            end
        else
            CrossConfig[string(ParametersList[i].Type, i)].value = max(min(LinearExtension(Config1[string(ParametersList[i].Type, i)].value,
                                                                                           fitness1[targetList[ParametersList[i].CorrelationTarget].StateName],
                                                                                           Config2[string(ParametersList[i].Type, i)].value,
                                                                                           fitness2[targetList[ParametersList[i].CorrelationTarget].StateName]),
                                                                                           CrossConfig.parameters[string(ParametersList[i].Type, i)].max),
                                                                                           CrossConfig.parameters[string(ParametersList[i].Type, i)].min)
        end
    end

    initial_cost, fitness      = @fetch (tuning_run.measurement_method(tuning_run, CrossConfig))
    cost_calls       += tuning_run.cost_evaluations
    update!(CrossConfig)
    MPResult(name, tuning_run.starting_point, CrossConfig, initial_cost, iteration,
           iteration, cost_calls, false, fitness)
end

function get_best(res1::MPResult, res2::MPResult)

    if res2.cost_minimum < res1.cost_minimum
        res1 = deepcopy(res2)
    end

    res1
end

function MPsimulated_annealing(tuning_run::MPRun,
                             reference::RemoteChannel;
                             temperature::Function = log_temperature)
    name               = "MP Simulated Annealing $(myid())"
    iteration          = 1
    cost_calls         = tuning_run.cost_evaluations
    stopping_criterion = @task tuning_run.stopping_criterion(tuning_run.duration)
    stop               = consume(stopping_criterion)
    ProbaCrossOver = tuning_run.cost_arguments[:ProbaCrossOver]
    AllSols = Vector{Float64}()
    while !stop
        iteration                 += 1
        p                          = temperature(iteration)
        result                     = MPprobabilistic_improvement(tuning_run, threshold = p)
        if rand() < ProbaCrossOver(iteration-1)
            resultRand = GenerateRandomRun(tuning_run)
            resultCross = Crossover(tuning_run, result.minimum, result.Fitness, resultRand.minimum, resultRand.Fitness)
            result = get_best(result, get_best(resultCross, resultRand))
            println("Out of a crossover. Result : ", result.technique)
        end
        cost_calls                += result.cost_calls
        result.cost_calls          = cost_calls
        result.start               = tuning_run.starting_point
        result.technique           = (result.technique != "MP Probabilistic Improvement")? result.technique : name
        result.iterations          = iteration
        result.current_iteration   = iteration
        tuning_run.starting_point  = result.minimum
        tuning_run.starting_cost   = result.cost_minimum
        tuning_run.Fitness         = result.Fitness
        stop                       = consume(stopping_criterion)
        push!(AllSols, result.cost_minimum)
        put!(reference, result)
    end
    open("C:/SLS/MPSimAnnealAllSols$(myid()).txt", "w") do io
       writedlm(io, AllSols)
   end
end

function simulated_annealing(tuning_run::MPRun,
                             reference::RemoteChannel;
                             temperature::Function = log_temperature)
    name               = "Simulated Annealing $(myid())"
    iteration          = 1
    cost_calls         = tuning_run.cost_evaluations
    stopping_criterion = @task tuning_run.stopping_criterion(tuning_run.duration)
    stop               = consume(stopping_criterion)
    AllSols = Vector{Float64}()
    while !stop
        iteration                 += 1
        p                          = temperature(iteration)
        result                     = MPprobabilistic_improvement(tuning_run, threshold = p)
        cost_calls                += result.cost_calls
        result.cost_calls          = cost_calls
        result.start               = tuning_run.starting_point
        result.technique           = (result.technique != "MP Probabilistic Improvement")? result.technique : name
        result.iterations          = iteration
        result.current_iteration   = iteration
        tuning_run.starting_point  = result.minimum
        tuning_run.starting_cost   = result.cost_minimum
        tuning_run.Fitness         = result.Fitness
        stop                       = consume(stopping_criterion)
        push!(AllSols, result.cost_minimum)
        put!(reference, result)
    end
    open("C:/SLS/SimAnnealAllSols$(myid()).txt", "w") do io
       writedlm(io, AllSols)
   end
end

function measure_mean!(tuning_run::MPRun, x::Configuration)

    next_proc   = @task chooseproc()
    ArrayFitness = Array{Dict{String, Any}, 1}(tuning_run.cost_evaluations)
    for i = 1:tuning_run.cost_evaluations
        ArrayFitness[i] = Dict{String, Any}()
    end

    @sync begin
        for i = 1:tuning_run.cost_evaluations

            @async begin
                tuning_run.cost_values[i], ArrayFitness[i] = remotecall_fetch(tuning_run.cost,
                                                             consume(next_proc),
                                                             x,
                                                             tuning_run.cost_arguments)
            end
        end
    end
    fitness = Dict{String, Any}()
    for key in keys(ArrayFitness[1])
        fitness[key] = zeros(2)
        fitness[key][1] = mean([ArrayFitness[i][key][1] for i = 1:tuning_run.cost_evaluations])
        fitness[key][2] = mean([ArrayFitness[i][key][2] for i = 1:tuning_run.cost_evaluations])
    end

    mean(tuning_run.cost_values), fitness
end

function get_new_best(results::Array{RemoteChannel}, best::MPResult)
    for reference in results
        partial = take!(reference)
        if partial.cost_minimum < best.cost_minimum
            best = deepcopy(partial)
        end
    end
    best
end


Base.show{T <: MPResult}(io::IO, n::T) = begin
    if n.is_final
        @printf io "["
        print_with_color(:blue, io, "Final Result")
        @printf io "]\n"
        print_with_color(:yellow, io, "Cost")
        @printf io "                  : "
        print_with_color(:bold, io, "$(n.cost_minimum)\n")
        print_with_color(:yellow, io, "Found in Iteration")
        @printf io "    : "
        print_with_color(:bold, io, "$(n.iterations)\n")
        print_with_color(:blue, io, "Current Iteration")
        @printf io "     : "
        print_with_color(:bold, io, "$(n.current_iteration)\n")
        print_with_color(:blue, io, "Technique")
        @printf io "             : "
        print_with_color(:bold, io, "$(n.technique)\n")
        print_with_color(:blue, io, "Function Calls")
        @printf io "        : "
        print_with_color(:bold, io, "$(n.cost_calls)\n")
        print_with_color(:blue, io, "Starting Configuration")
        @printf io ":\n"
        show(io, n.start)
        print_with_color(:blue, io, "Minimum Configuration")
        @printf io " :\n"
        show(io, n.minimum)
    else
        @printf io "["
        print_with_color(:blue, io, "Result")
        @printf io "]\n"
        print_with_color(:yellow, io, "Cost")
        @printf io "              : "
        print_with_color(:bold, io, "$(n.cost_minimum)\n")
        print_with_color(:yellow, io, "Found in Iteration")
        @printf io ": "
        print_with_color(:bold, io, "$(n.iterations)\n")
        print_with_color(:blue, io, "Current Iteration")
        @printf io " : "
        print_with_color(:bold, io, "$(n.current_iteration)\n")
        print_with_color(:blue, io, "Technique")
        @printf io "         : "
        print_with_color(:bold, io, "$(n.technique)\n")
        print_with_color(:blue, io, "Function Calls")
        @printf io "    : "
        print_with_color(:bold, io, "$(n.cost_calls)\n")
        print_with_color(:blue, io, "  ***\n")
    end
    return
end
