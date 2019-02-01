function isless(lhs::GAEngine, rhs::GAEngine)
    Tempolhs = 0
    Temporhs = 0

    for i in 1:length(targetList)
        if (sum(abs.(lhs.fitness[targetList[i].StateName]))/(targetList[i].Value*(lhs.mpSim.simLength - targetList[i].StartYear))) <= targetList[i].CompletionRate
            Tempolhs += 1
        end
        if (sum(abs.(rhs.fitness[targetList[i].StateName]))/(targetList[i].Value*(rhs.mpSim.simLength - targetList[i].StartYear))) <= targetList[i].CompletionRate
            Temporhs += 1
        end
    end

    if Tempolhs != 0 && Temporhs != 0
        if Tempolhs == Temporhs
            return lhs.fitness["RecCost"] > rhs.fitness["RecCost"]
        end
        return Tempolhs > Temporhs
    end

    Tempolhs = 0
    Temporhs = 0
    for tempo in lhs.fitness
        try
            Tempolhs += abs(tempo[2][2])
            Tempolhs += abs(tempo[2][1])
        end
    end
    for tempo in rhs.fitness
        try
            Temporhs += abs(tempo[2][2])
            Temporhs += abs(tempo[2][1])
        end
    end
    Tempolhs > Temporhs
end

function create_entity(num)
    GAEngine(num)
end

function fitness(ent)
    try
        if length(ent.fitness) != 0
            return ent.fitness
        end
    end
    fitn = 0
    score = Dict{String, Any}()#"active" => zeros(2), "AdOff" => zeros(2), "Off" => zeros(2), "BO" => zeros(2), "BDL" => zeros(2), "RecCost" => 0.0)#, "TotPopRate" => 0.0, "AdOffRate" => 0.0, "OffRate" => 0.0, "BORate" => 0.0, "BDLRate" => 0.0)
    try
        println("Running... ")
        tStart = now()
        ent.mpSim.simDB = SQLite.DB( "" )
        resetSimulation(ent.mpSim)
        run( ent.mpSim )
        #println("end.")
        tEnd = now()
        timeElapsed = (tEnd - tStart).value / 1000
        println( "SimEnd. simulation time: $timeElapsed seconds." )
        tStart = now()

        for i in 1:length(targetList)
            score[targetList[i].StateName] = zeros(2)
            fluxInCounts    =  generateFluxReport( ent.mpSim, 12,  true, targetList[i].StateName)
            fluxOutCounts   =  generateFluxReport( ent.mpSim, 12, false, targetList[i].StateName)
            personnelCounts = generateCountReport( ent.mpSim, targetList[i].StateName, fluxInCounts, fluxOutCounts )

            for j in targetList[i].StartYear:length(personnelCounts[Symbol(targetList[i].StateName)])
                tempo = personnelCounts[Symbol(targetList[i].StateName)][j] - targetList[i].Value
                if tempo > 0
                    score[targetList[i].StateName][1] += tempo
                else
                    score[targetList[i].StateName][2] += tempo
                end
            end
        end

        for sco in score
            fitn += abs(sco[2][2]) + sco[2][1]
        end
        TotRecruitment = 0
        for i in 1:length(ent.mpSim.recruitmentSchemes)
            TotRecruitment += ent.mpSim.recruitmentSchemes[i].recDist()
        end
        score["RecCost"] = (ent.mpSim.simLength/12)*TotRecruitment/3

        tEnd = now()
        timeElapsed = (tEnd - tStart).value / 1000
        println( "Fitness compute time: $timeElapsed seconds, with $fitn" )
        println()

    catch e
        println()
        println("____________________________________________")
        println(e)

        println("R 1A-B  : ", ent.mpSim.recruitmentSchemes[1].recDist()," R 1A-D  : ", ent.mpSim.recruitmentSchemes[2].recDist()," R 1B-B  : ", ent.mpSim.recruitmentSchemes[3].recDist()," R 1B-D  : ", ent.mpSim.recruitmentSchemes[4].recDist())
        try
            println("A 1A-B  : ", ent.mpSim.recruitmentSchemes[1].ageDist()/12)
        end
        try
            println(" A 1A-D  : ", ent.mpSim.recruitmentSchemes[2].ageDist()/12)
        end
        try
            println(" A 1B-B  : ", ent.mpSim.recruitmentSchemes[3].ageDist()/12)
        end
        try
            println(" A 1B-D  : ", ent.mpSim.recruitmentSchemes[4].ageDist()/12)
        end
        for TransTuple in ent.mpSim.otherStateList
            for i in 1:length(TransTuple[2])
                if TransTuple[2][i].name == "B+"
                    println("Trans B+ : ", TransTuple[2][i].startState.name, "->", TransTuple[2][i].endState.name, " Proba : ", TransTuple[2][i].probabilityList[1], " Tenure : ", (TransTuple[2][i].extraConditions[1].val/12))
                end
            end
        end
        println("Retirement Age : ", (ent.mpSim.retirementScheme.retireAge/12))
        println("____________________________________________")
        println()
        ent.Generation = 100
    end
    score
end

function group_entities(grouped::Channel, pop)

    if pop[1].Generation > 5
        return
    end

    # simple naive groupings that pair the best entitiy with every other
    for i in 1:length(pop)
        put!(grouped, [1, i])
    end
end

function HaveDiffrentSigns(Fit1, Fit2)
    return ((Fit1[1] > abs(Fit1[2]) && Fit2[1] < abs(Fit2[2])) || (Fit1[1] < abs(Fit1[2]) && Fit2[1] > abs(Fit2[2])))
end

function WeightedAverage(Val1, Fit1, Val2, Fit2)
    return ((Val1*max(Fit2[1], abs(Fit2[2])))+(Val2*max(Fit1[1], abs(Fit1[2]))))/(max(Fit2[1], abs(Fit2[2])) + max(Fit1[1], abs(Fit1[2])))
end

function IntWeightedAverage(Val1, Fit1, Val2, Fit2)
    return Int(round(((Val1*max(Fit2[1], abs(Fit2[2])))+(Val2*max(Fit1[1], abs(Fit1[2]))))/(max(Fit2[1], abs(Fit2[2])) + max(Fit1[1], abs(Fit1[2])))))
end

function LinearExtension(X1, Y1, X2, Y2)
    y1 = (Y1[1] > abs(Y1[2]))? Y1[1] : Y1[2]
    y2 = (Y2[1] > abs(Y2[2]))? Y2[1] : Y2[2]
    if y1 == y2
        return (rand()<0.5)? X1 : X2
    end
    return (X1 - ((X2 - X1)/(y2 - y1))*y1)
end

function IntLinearExtension(X1, Y1, X2, Y2)
    y1 = (Y1[1] > abs(Y1[2]))? Y1[1] : Y1[2]
    y2 = (Y2[1] > abs(Y2[2]))? Y2[1] : Y2[2]
    if y1 == y2
        return (rand()<0.5)? X1 : X2
    end
    return Int(round(X1 - ((X2 - X1)/(y2 - y1))*y1))
end

function crossover(group)
    println("crossover operator")
    if group[1].fitness == group[2].fitness # treat the case where the parents are the same.

        child = group[1]
        child.Generation += 1

        return child
    end

    child = GAEngine(1)
    child.Generation = group[1].Generation + 1


    for var in 1:length(ParametersList)
        if ParametersList[var].Type == "RecFlow"
            # Set recruitment flows
            NewVal = max(min(IntLinearExtension(group[1].mpSim.recruitmentSchemes[ParametersList[var].Index].recDist(),
                                                group[1].fitness[targetList[ParametersList[var].CorrelationTarget].StateName],
                                                group[2].mpSim.recruitmentSchemes[ParametersList[var].Index].recDist(),
                                                group[2].fitness[targetList[ParametersList[var].CorrelationTarget].StateName]),
                             ParametersList[var].Max), ParametersList[var].Min)
            setRecruitmentFixed(child.mpSim.recruitmentSchemes[ParametersList[var].Index], NewVal)

        elseif ParametersList[var].Type == "RecAge"
            # Set recruitment age
            NewVal = max(min(IntLinearExtension(group[1].mpSim.recruitmentSchemes[ParametersList[var].Index].ageDist()/12,
                                                group[1].fitness[targetList[ParametersList[var].CorrelationTarget].StateName],
                                                group[2].mpSim.recruitmentSchemes[ParametersList[var].Index].ageDist()/12,
                                                group[2].fitness[targetList[ParametersList[var].CorrelationTarget].StateName]),
                              ParametersList[var].Max), ParametersList[var].Min)
            child.mpSim.recruitmentSchemes[ParametersList[var].Index].ageDist = function () return 12*NewVal end

        elseif ParametersList[var].Type == "TransProba"
            for TransTuple in child.mpSim.otherStateList
                if !contains(TransTuple[1].name, ParametersList[var].StartingState)
                    continue
                end
                for j in 1:length(TransTuple[2])
                    if TransTuple[2][j].name == ParametersList[var].Name
                        TransTuple[2][j].probabilityList[1] = max(min(LinearExtension( group[1].mpSim.otherStateList[group[1].mpSim.stateList[TransTuple[1].name]][j].probabilityList[1],
                                                                                       group[1].fitness[targetList[ParametersList[var].CorrelationTarget].StateName],
                                                                                       group[2].mpSim.otherStateList[group[2].mpSim.stateList[TransTuple[1].name]][j].probabilityList[1],
                                                                                       group[2].fitness[targetList[ParametersList[var].CorrelationTarget].StateName]),
                                                                      ParametersList[var].Max), ParametersList[var].Min)
                    end
                end
            end

        elseif ParametersList[var].Type == "TransTenure"
            for TransTuple in child.mpSim.otherStateList
                if !contains(TransTuple[1].name, ParametersList[var].StartingState)
                    continue
                end
                for j in 1:length(TransTuple[2])
                    if TransTuple[2][j].name == ParametersList[var].Name
                        TransTuple[2][j].extraConditions[1].val = 12*max(min(IntLinearExtension(group[1].mpSim.otherStateList[group[1].mpSim.stateList[TransTuple[1].name]][j].extraConditions[1].val/12,
                                                                                                group[1].fitness[targetList[ParametersList[var].CorrelationTarget].StateName],
                                                                                                group[2].mpSim.otherStateList[group[2].mpSim.stateList[TransTuple[1].name]][j].extraConditions[1].val/12,
                                                                                                group[2].fitness[targetList[ParametersList[var].CorrelationTarget].StateName]),
                                                                              ParametersList[var].Max), ParametersList[var].Min)
                    end
                end
            end

        elseif ParametersList[var].Type == "PEAge"
            # Retirement Age
            child.mpSim.retirementScheme.retireAge = 12*max(min(IntLinearExtension(group[1].mpSim.retirementScheme.retireAge/12,
                                                                                   group[1].fitness[targetList[ParametersList[var].CorrelationTarget].StateName],
                                                                                   group[2].mpSim.retirementScheme.retireAge/12,
                                                                                   group[2].fitness[targetList[ParametersList[var].CorrelationTarget].StateName]),
                                                              ParametersList[var].Max), ParametersList[var].Min)
        end
    end

    # setRecruitmentFixed(child.mpSim.recruitmentSchemes[1], min(max(IntLinearExtension(group[1].mpSim.recruitmentSchemes[1].recDist(), group[1].fitness["AdOff"], group[2].mpSim.recruitmentSchemes[1].recDist(), group[2].fitness["AdOff"]), 0), 1000))
    # setRecruitmentFixed(child.mpSim.recruitmentSchemes[2], min(max(IntLinearExtension(group[1].mpSim.recruitmentSchemes[2].recDist(), group[1].fitness["AdOff"], group[2].mpSim.recruitmentSchemes[2].recDist(), group[2].fitness["AdOff"]), 0), 1000))
    # setRecruitmentFixed(child.mpSim.recruitmentSchemes[3], min(max(IntLinearExtension(group[1].mpSim.recruitmentSchemes[3].recDist(), group[1].fitness["Off"], group[2].mpSim.recruitmentSchemes[3].recDist(), group[2].fitness["Off"]), 0), 1000))
    # setRecruitmentFixed(child.mpSim.recruitmentSchemes[4], min(max(IntLinearExtension(group[1].mpSim.recruitmentSchemes[4].recDist(), group[1].fitness["Off"], group[2].mpSim.recruitmentSchemes[4].recDist(), group[2].fitness["Off"]), 0), 1000))
    #
    # for i in 1:length(child.mpSim.recruitmentSchemes)
    #     child.mpSim.recruitmentSchemes[i].ageDist = function () return 12*( max(min(IntLinearExtension( group[1].mpSim.recruitmentSchemes[i].ageDist()/12,
    #                                                                                                     group[1].fitness["active"],
    #                                                                                                     group[2].mpSim.recruitmentSchemes[i].ageDist()/12,
    #                                                                                                     group[2].fitness["active"]), 32), 16)) end
    # end
    # for TransTuple in child.mpSim.otherStateList
    #     if !contains(TransTuple[1].name, "1A-D")
    #         continue
    #     end
    #     for i in 1:length(TransTuple[2])
    #         if TransTuple[2][i].name == "B+"
    #             # TransTuple[2][i].probabilityList = [max(min(LinearExtension( group[1].mpSim.otherStateList[group[1].mpSim.stateList[TransTuple[1].name]][i].probabilityList[1],
    #             #                                                                 group[1].fitness["BDL"],
    #             #                                                                 group[2].mpSim.otherStateList[group[2].mpSim.stateList[TransTuple[1].name]][i].probabilityList[1],
    #             #                                                                 group[2].fitness["BDL"]), 1), 0)]
    #             # TransTuple[2][i].extraConditions[1].val = 12*max(min(IntLinearExtension(group[1].mpSim.otherStateList[group[1].mpSim.stateList[TransTuple[1].name]][i].extraConditions[1].val/12,
    #             #                                                                         group[1].fitness["BDL"],
    #             #                                                                         group[2].mpSim.otherStateList[group[2].mpSim.stateList[TransTuple[1].name]][i].extraConditions[1].val/12,
    #             #                                                                         group[2].fitness["BDL"]), 25), 1)
    #         end
    #     end
    # end
    # for TransTuple in child.mpSim.otherStateList
    #     if !contains(TransTuple[1].name, "1B-D")
    #         continue
    #     end
    #     for i in 1:length(TransTuple[2])
    #         if TransTuple[2][i].name == "B+"
    #             TransTuple[2][i].probabilityList = [max(min(LinearExtension( group[1].mpSim.otherStateList[group[1].mpSim.stateList[TransTuple[1].name]][i].probabilityList[1],
    #                                                                             group[1].fitness["BO"],
    #                                                                             group[2].mpSim.otherStateList[group[2].mpSim.stateList[TransTuple[1].name]][i].probabilityList[1],
    #                                                                             group[2].fitness["BO"]), 1), 0)]
    #             TransTuple[2][i].extraConditions[1].val = 12*max(min(IntLinearExtension(group[1].mpSim.otherStateList[group[1].mpSim.stateList[TransTuple[1].name]][i].extraConditions[1].val/12,
    #                                                                                     group[1].fitness["BO"],
    #                                                                                     group[2].mpSim.otherStateList[group[2].mpSim.stateList[TransTuple[1].name]][i].extraConditions[1].val/12,
    #                                                                                     group[2].fitness["BO"]), 25), 1)
    #         end
    #     end
    # end
    # child.mpSim.retirementScheme.retireAge = 12*max(min(IntLinearExtension(group[1].mpSim.retirementScheme.retireAge/12,
    #                                                                        group[1].fitness["active"],
    #                                                                        group[2].mpSim.retirementScheme.retireAge/12,
    #                                                                        group[1].fitness["active"]), 70), 40)
    println("End Crossover")
    child
end

function mutate(ent)
    try
        if length(ent.fitness) != 0
            return ent.fitness
        end
    end

    # We mutate 15% of the time
    rand(Float64) < 0.85 && return

    MutationRate = 0.2
    NbVaribleMutate = rand(Float64)

    if NbVaribleMutate <= 0.5
        NbVaribleMutate = 1
    elseif NbVaribleMutate <= 0.8
        NbVaribleMutate = 2
    else
        NbVaribleMutate = 3
    end
    VariablesToMutate = Vector{Int}()

    while length(VariablesToMutate) < NbVaribleMutate
        tempVar = rand(1:length(ParametersList))
        if !in(tempVar, VariablesToMutate)
            push!(VariablesToMutate, tempVar)
        end
    end

    for var in VariablesToMutate
        if ParametersList[var].Type == "RecFlow"
            # Set recruitment flows
            AddedFlow = rand(Int)%max(Int(round((ParametersList[var].Max - ParametersList[var].Min)*MutationRate)), 2)
            NewVal = max(min(ent.mpSim.recruitmentSchemes[ParametersList[var].Index].recDist() + AddedFlow, ParametersList[var].Max), ParametersList[var].Min)
            setRecruitmentFixed(ent.mpSim.recruitmentSchemes[ParametersList[var].Index], NewVal)
        elseif ParametersList[var].Type == "RecAge"
            # Set recruitment age
            AddedYears = rand(Int)%max(Int(round((ParametersList[var].Max - ParametersList[var].Min)*MutationRate)), 2)
            NewVal = max(min(ent.mpSim.recruitmentSchemes[ParametersList[var].Index].ageDist() + 12*(AddedYears), 12*ParametersList[var].Max), 12*ParametersList[var].Min)
            ent.mpSim.recruitmentSchemes[ParametersList[var].Index].ageDist = function () return NewVal end
        elseif ParametersList[var].Type == "TransProba"
            AddedRate = (rand(Int)%max((ParametersList[var].Max - ParametersList[var].Min)*MutationRate*100, 2))/1000.0
            for TransTuple in ent.mpSim.otherStateList
                if !contains(TransTuple[1].name, ParametersList[var].StartingState)
                    continue
                end
                for j in 1:length(TransTuple[2])
                    if TransTuple[2][j].name == ParametersList[var].Name
                        TransTuple[2][j].probabilityList[1] = max(min(TransTuple[2][j].probabilityList[1] + AddedRate, ParametersList[var].Max), ParametersList[var].Min)
                    end
                end
            end
        elseif ParametersList[var].Type == "TransTenure"
            AddedYears = rand(Int)%max(Int(round((ParametersList[var].Max - ParametersList[var].Min)*MutationRate)), 2)
            for TransTuple in ent.mpSim.otherStateList
                if !contains(TransTuple[1].name, ParametersList[var].StartingState)
                    continue
                end
                for j in 1:length(TransTuple[2])
                    if TransTuple[2][j].name == ParametersList[var].Name
                        TransTuple[2][j].extraConditions[1].val = max(min(TransTuple[2][j].extraConditions[1].val + 12*(AddedYears), 12*ParametersList[var].Max), 12*ParametersList[var].Min)
                    end
                end
            end
        elseif ParametersList[var].Type == "PEAge"
            # Retirement Age
            AddedYears = rand(Int)%max(Int(round((ParametersList[var].Max - ParametersList[var].Min)*MutationRate)), 2)
            ent.mpSim.retirementScheme.retireAge = max(min(ent.mpSim.retirementScheme.retireAge + 12*(AddedYears), 12*ParametersList[var].Max), 12*ParametersList[var].Min)
        end
    end
end
