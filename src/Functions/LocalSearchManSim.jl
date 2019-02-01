#@everywhere 
include(joinpath( dirname( Base.source_path() ), myid()==1? "": "src", myid()==1? "":"Functions", "mpInit.jl" ))

configFileName = myid()==1? joinpath( dirname( Base.source_path() ), "..", "..", "Data", "SIMULdemo.xlsx"):joinpath( dirname( Base.source_path() ), "Data", "SIMULdemo.xlsx")#"C:/Users/MediaMonster/Dropbox/JuliaManpowerPlanning/ManpowerSimOpt/Data/SIMULdemo.xlsx"

global InitMpSim = CreatSim( configFileName )

sendto(workers(), InitMpSim=InitMpSim)

@everywhere begin
    using StochasticSearch
    function mpSimSLS(x::Configuration, parameters::Dict{Symbol, Any})

        mpSim = deepcopy(InitMpSim)
        ParametersList = parameters[:ParametersList]
        targetList = parameters[:targetList]
        for i in 1:length(ParametersList)
            if ParametersList[i].Type == "RecFlow"
                # Set recruitment flows
                setRecruitmentFixed(mpSim.recruitmentSchemes[ParametersList[i].Index], x[string(ParametersList[i].Type, i)].value)
            elseif ParametersList[i].Type == "RecAge"
                # Set recruitment age
                mpSim.recruitmentSchemes[ParametersList[i].Index].ageDist = function () return 12*(x[string(ParametersList[i].Type, i)].value) end
            elseif ParametersList[i].Type == "TransProba"
                for TransTuple in mpSim.otherStateList
                    if !contains(TransTuple[1].name, ParametersList[i].StartingState)
                        continue
                    end
                    for j in 1:length(TransTuple[2])
                        if TransTuple[2][j].name ==ParametersList[i].Name
                            TransTuple[2][j].probabilityList = [x[string(ParametersList[i].Type, i)].value]
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
                            TransTuple[2][j].extraConditions[1].val = 12*(x[string(ParametersList[i].Type, i)].value)
                        end
                    end
                end
            elseif ParametersList[i].Type == "PEAge"
                # Retirement Age
                mpSim.retirementScheme.retireAge = 12*(x[string(ParametersList[i].Type, i)].value)
            end
        end

        tStart = now()
        println("Running... ")
        #ExecNb += 1
        mpSim.simDB = SQLite.DB( "" )
        resetSimulation(mpSim)
        run( mpSim )

        score = 0


        for i in 1:length(targetList)
            fluxInCounts    =  generateFluxReport( mpSim, 12,  true, targetList[i].StateName)
            fluxOutCounts   =  generateFluxReport( mpSim, 12, false, targetList[i].StateName)
            personnelCounts = generateCountReport( mpSim, targetList[i].StateName, fluxInCounts, fluxOutCounts )
            score += sum(abs.(personnelCounts[Symbol(targetList[i].StateName)][targetList[i].StartYear:end] - targetList[i].Value))
        end

        TotRecruitment = 0
        for i in 1:length(mpSim.recruitmentSchemes)
            TotRecruitment += mpSim.recruitmentSchemes[i].recDist()
        end
        score += (mpSim.simLength/12)*TotRecruitment/3

        tEnd = now()
        timeElapsed = (tEnd - tStart).value / 1000
        println("end. $timeElapsed seconds with $score as a score")
        return score
    end
end
