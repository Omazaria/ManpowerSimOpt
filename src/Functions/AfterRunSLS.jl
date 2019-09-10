
mpSim = InitMpSim


for i in 1:length(ParametersList)
    if ParametersList[i].Type == "RecFlow"
        # Set recruitment flows
        if length(ParametersList[i].TimeDivision) > 2
            mpSim.recruitmentSchemes[ParametersList[i].Index].UseRecFlowArray = true
            mpSim.recruitmentSchemes[ParametersList[i].Index].RecFlowArray = Int.(zeros(mpSim.simLength/12 + 1))
            for div in 1:(length(ParametersList[i].TimeDivision)-1)
                mpSim.recruitmentSchemes[ParametersList[i].Index].RecFlowArray[ParametersList[i].TimeDivision[div] + 1:((ParametersList[i].TimeDivision[div + 1] == -1)? end : 1 + ParametersList[i].TimeDivision[div + 1])] = result.minimum.parameters[string(ParametersList[i].Type, i, div)].value
            end
        else
            setRecruitmentFixed(mpSim.recruitmentSchemes[ParametersList[i].Index], result.minimum.parameters[string(ParametersList[i].Type, i)].value)
        end
    elseif ParametersList[i].Type == "RecAge"
        # Set recruitment age
        if length(ParametersList[i].TimeDivision) > 2
            mpSim.recruitmentSchemes[ParametersList[i].Index].UseRecAgeArray = true
            mpSim.recruitmentSchemes[ParametersList[i].Index].RecAgeArray = Int.(zeros(mpSim.simLength/12 + 1))
            for div in 1:(length(ParametersList[i].TimeDivision) - 1)
                mpSim.recruitmentSchemes[ParametersList[i].Index].RecAgeArray[ParametersList[i].TimeDivision[div] + 1:((ParametersList[i].TimeDivision[div + 1] == -1)? end : 1+ParametersList[i].TimeDivision[i + 1])] = result.minimum.parameters[string(ParametersList[i].Type, i, div)].value
            end
        else
            mpSim.recruitmentSchemes[ParametersList[i].Index].ageDist = function () return 12*(result.minimum.parameters[string(ParametersList[i].Type, i)].value) end
        end
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


configFileName = joinpath( dirname( Base.source_path() ), "..", "..", "Data", "SIMULdemo.xlsx")
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
