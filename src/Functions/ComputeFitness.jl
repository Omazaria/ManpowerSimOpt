function ComputeScore(mpSim::ManpowerSimulation, targetList::Array{Target,1})
    score = 0

    for i in 1:length(targetList)
        fluxInCounts    =  generateFluxReport( mpSim, 12,  true, targetList[i].StateName)
        fluxOutCounts   =  generateFluxReport( mpSim, 12, false, targetList[i].StateName)
        personnelCounts = generateCountReport( mpSim, targetList[i].StateName, fluxInCounts, fluxOutCounts )

        for y in targetList[i].StartYear:length(personnelCounts[Symbol(targetList[i].StateName)])
            tempo = abs(targetList[i].Value - personnelCounts[Symbol(targetList[i].StateName)][y])
            if (tempo/targetList[i].Value) > targetList[i].CompletionRate
                score += tempo*targetList[i].CoefCostFunc*(y)
            end
        end
        # if !Satifaction[i]
        #      sum(abs.(personnelCounts[Symbol(targetList[i].StateName)][targetList[i].StartYear:end] - targetList[i].Value))
        # end
    end

    # TotRecruitment = 0
    # for i in 1:length(mpSim.recruitmentSchemes)
    #     TotRecruitment += mpSim.recruitmentSchemes[i].recDist()
    # end
    # score += (mpSim.simLength/12)*TotRecruitment/2

    return score
end

function ComputeFitness(mpSim::ManpowerSimulation, targetList::Array{Target,1})
    score = 0
    fitness = Dict{String, Any}()

    for i in 1:length(targetList)
        fitness[targetList[i].StateName] = zeros(2)
        fluxInCounts    =  generateFluxReport( mpSim, 12,  true, targetList[i].StateName)
        fluxOutCounts   =  generateFluxReport( mpSim, 12, false, targetList[i].StateName)
        personnelCounts =  generateCountReport(mpSim, targetList[i].StateName, fluxInCounts, fluxOutCounts )

        for y in targetList[i].StartYear:length(personnelCounts[Symbol(targetList[i].StateName)])
            tempo = personnelCounts[Symbol(targetList[i].StateName)][y] - targetList[i].Value
            score += abs(tempo/targetList[i].Value)*(y)

            if (tempo/targetList[i].Value) > targetList[i].CompletionRate
                fitness[targetList[i].StateName][1] += tempo
            elseif (tempo/targetList[i].Value) < -targetList[i].CompletionRate
                fitness[targetList[i].StateName][2] += tempo
            end
        end
    end

    # TotRecruitment = 0
    # for i in 1:length(ent.mpSim.recruitmentSchemes)
    #     TotRecruitment += ent.mpSim.recruitmentSchemes[i].recDist()
    # end
    # fitness["RecCost"] = (ent.mpSim.simLength/12)*TotRecruitment/2

    return score, fitness
end
