function Tests_neighbor!(configuration::Configuration, tuning_run::MPRun; distance::Float64 = 1.0, RandPercentage::Float64 = 0.0, NbVaribleMutate::Int = 1)
    #println("In neighbor...")
    targetList    = tuning_run.cost_arguments[:targetList]
    ParametersList= tuning_run.cost_arguments[:ParametersList]

    key_set = collect(keys(configuration.parameters))
    #NbVaribleMutate = rand(Float64)

    #if NbVaribleMutate <= 0.5
    #    NbVaribleMutate = VarToMutate
    #elseif NbVaribleMutate <= 0.8
    #    NbVaribleMutate = 20
    #else
    #    NbVaribleMutate = 3
    #end
    for mutVar in 1:NbVaribleMutate
        target  = key_set[rand(1:length(key_set))]
        for i = 1:distance
            if rand() < RandPercentage#0.5
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
                    min = Int(round(configuration.parameters[target].min*distance))
                    max = Int(round(configuration.parameters[target].max*distance))
                else
                    min = configuration.parameters[target].min*distance
                    max = configuration.parameters[target].max*distance
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
    #println("In neighbor...")
    update!(configuration)
    configuration
end

function Tests_probabilistic_improvement(tuning_run::MPRun;
                                   threshold::AbstractFloat = 2.,
                                   acceptance_criterion::Function = metropolis,
                                   distance::Float64 = 1.0, RandPercentage::Float64 = 0.0, NbVaribleMutate::Int = 1)
    initial_cost  = tuning_run.starting_cost
    x             = deepcopy(tuning_run.starting_point)
    fitness       = deepcopy(tuning_run.Fitness)
    x_proposal    = deepcopy(tuning_run.starting_point)
    name          = "MP Probabilistic Improvement $(myid())"
    cost_calls    = 0
    iteration     = 1
    #println("Before...")
    try
        if RandPercentage > 0
            Tests_neighbor!(x_proposal, tuning_run, distance = distance, RandPercentage = RandPercentage, NbVaribleMutate = NbVaribleMutate)#tuning_run
        else
            for i in 1:NbVaribleMutate
                neighbor!(x_proposal, )
            end
        end

    #println("after...")
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
    catch e
        println(e)
    end
    MPResult(name, tuning_run.starting_point, x, initial_cost, iteration,
           iteration, cost_calls, false, fitness)
end

function Test25_simulated_annealing(tuning_run::MPRun,
                                   reference::RemoteChannel;
                                   temperature::Function = log_temperature)
    name               = "Test25_Simulated Annealing $(myid())"
    iteration          = 1
    cost_calls         = tuning_run.cost_evaluations
    stopping_criterion = @task tuning_run.stopping_criterion(tuning_run.duration)
    stop               = consume(stopping_criterion)
    AllSols = Vector{Float64}()
    while !stop
        try
        iteration                 += 1
        p                          = temperature(iteration)
        result                     = Tests_probabilistic_improvement(tuning_run, threshold = p, distance = 0.3, RandPercentage = 0.5, NbVaribleMutate = 20)
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
        catch e
            println(e)
        end
    end
    open("C:/SLS/$name.txt", "w") do io
       writedlm(io, AllSols)
   end
end

function Test26_simulated_annealing(tuning_run::MPRun,
                                   reference::RemoteChannel;
                                   temperature::Function = log_temperature)
    name               = "Test26_Simulated Annealing $(myid())"
    iteration          = 1
    cost_calls         = tuning_run.cost_evaluations
    stopping_criterion = @task tuning_run.stopping_criterion(tuning_run.duration)
    stop               = consume(stopping_criterion)
    AllSols = Vector{Float64}()
    while !stop
        iteration                 += 1
        p                          = temperature(iteration)
        result                     = Tests_probabilistic_improvement(tuning_run, threshold = p, distance = 0.3, RandPercentage = 0.0, NbVaribleMutate = 20)
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
    open("C:/SLS/$name.txt", "w") do io
       writedlm(io, AllSols)
   end
end

function Test27_simulated_annealing(tuning_run::MPRun,
                                   reference::RemoteChannel;
                                   temperature::Function = log_temperature)
    name               = "Test27_Simulated Annealing $(myid())"
    iteration          = 1
    cost_calls         = tuning_run.cost_evaluations
    stopping_criterion = @task tuning_run.stopping_criterion(tuning_run.duration)
    stop               = consume(stopping_criterion)
    AllSols = Vector{Float64}()
    while !stop
        iteration                 += 1
        p                          = temperature(iteration)
        result                     = Tests_probabilistic_improvement(tuning_run, threshold = p, distance = 0.3, RandPercentage = 1.0, NbVaribleMutate = 20)
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
    open("C:/SLS/$name.txt", "w") do io
       writedlm(io, AllSols)
   end
end

logx10_temperature(t::Real) = 10 / log(t)

function Test28_simulated_annealing(tuning_run::MPRun,
                                   reference::RemoteChannel;
                                   temperature::Function = logx10_temperature)
    name               = "Test28_Simulated Annealing $(myid())"
    iteration          = 1
    cost_calls         = tuning_run.cost_evaluations
    stopping_criterion = @task tuning_run.stopping_criterion(tuning_run.duration)
    stop               = consume(stopping_criterion)
    AllSols = Vector{Float64}()
    while !stop
        iteration                 += 1
        p                          = temperature(iteration)
        result                     = Tests_probabilistic_improvement(tuning_run, threshold = p, distance = 0.3, RandPercentage = 0.5, NbVaribleMutate = 20)
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
    open("C:/SLS/$name.txt", "w") do io
       writedlm(io, AllSols)
   end
end

function Test29_simulated_annealing(tuning_run::MPRun,
                                   reference::RemoteChannel;
                                   temperature::Function = logx10_temperature)
    name               = "Test29_Simulated Annealing $(myid())"
    iteration          = 1
    cost_calls         = tuning_run.cost_evaluations
    stopping_criterion = @task tuning_run.stopping_criterion(tuning_run.duration)
    stop               = consume(stopping_criterion)
    AllSols = Vector{Float64}()
    while !stop
        iteration                 += 1
        p                          = temperature(iteration)
        result                     = Tests_probabilistic_improvement(tuning_run, threshold = p, distance = 0.3, RandPercentage = 0.0, NbVaribleMutate = 20)
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
    open("C:/SLS/$name.txt", "w") do io
       writedlm(io, AllSols)
   end
end

function Test30_simulated_annealing(tuning_run::MPRun,
                                   reference::RemoteChannel;
                                   temperature::Function = logx10_temperature)
    name               = "Test30_Simulated Annealing $(myid())"
    iteration          = 1
    cost_calls         = tuning_run.cost_evaluations
    stopping_criterion = @task tuning_run.stopping_criterion(tuning_run.duration)
    stop               = consume(stopping_criterion)
    AllSols = Vector{Float64}()
    while !stop
        iteration                 += 1
        p                          = temperature(iteration)
        result                     = Tests_probabilistic_improvement(tuning_run, threshold = p, distance = 0.3, RandPercentage = 1.0, NbVaribleMutate = 20)
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
    open("C:/SLS/$name.txt", "w") do io
       writedlm(io, AllSols)
   end
end

function Test31_simulated_annealing(tuning_run::MPRun,
                                   reference::RemoteChannel;
                                   temperature::Function = log_temperature)
    name               = "Test31_Simulated Annealing $(myid())"
    iteration          = 1
    cost_calls         = tuning_run.cost_evaluations
    stopping_criterion = @task tuning_run.stopping_criterion(tuning_run.duration)
    stop               = consume(stopping_criterion)
    AllSols = Vector{Float64}()
    while !stop
        iteration                 += 1
        p                          = temperature(iteration)
        result                     = Tests_probabilistic_improvement(tuning_run, threshold = p, distance = 0.5, RandPercentage = 0.5, NbVaribleMutate = 20)
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
    open("C:/SLS/$name.txt", "w") do io
       writedlm(io, AllSols)
   end
end

function Test32_simulated_annealing(tuning_run::MPRun,
                                   reference::RemoteChannel;
                                   temperature::Function = logx10_temperature)
    name               = "Test32_Simulated Annealing $(myid())"
    iteration          = 1
    cost_calls         = tuning_run.cost_evaluations
    stopping_criterion = @task tuning_run.stopping_criterion(tuning_run.duration)
    stop               = consume(stopping_criterion)
    AllSols = Vector{Float64}()
    while !stop
        iteration                 += 1
        p                          = temperature(iteration)
        result                     = Tests_probabilistic_improvement(tuning_run, threshold = p, distance = 0.5, RandPercentage = 0.5, NbVaribleMutate = 20)
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
    open("C:/SLS/$name.txt", "w") do io
       writedlm(io, AllSols)
   end
end
