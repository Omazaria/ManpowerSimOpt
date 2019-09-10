#@everywhere
include(joinpath( dirname( Base.source_path() ), myid()==1? "": "src", myid()==1? "":"Functions", "mpInit.jl" ))
include(joinpath( dirname( Base.source_path() ), myid()==1? "..": "src", "types", "LocalSearchManSim.jl" ))


configFileName = myid()==1? joinpath( dirname( Base.source_path() ), "..", "..", "Data", "SIMULdemo.xlsx"):joinpath( dirname( Base.source_path() ), "Data", "SIMULdemo.xlsx")#"C:/Users/MediaMonster/Dropbox/JuliaManpowerPlanning/ManpowerSimOpt/Data/SIMULdemo.xlsx"

global InitMpSim = CreatSim( configFileName )

sendto(workers(), InitMpSim=InitMpSim)

@everywhere begin

    using MPStochasticSearch#StochasticSearch
    include(joinpath( dirname( Base.source_path() ), myid()==1? "": "src", myid()==1? "":"Functions", "ComputeFitness.jl" ))
    function setmpSimParameters(mpSim::ManpowerSimulation, ParametersList::Array{SearchParameters,1}, x::Configuration)

        for i in 1:length(ParametersList)

            if ParametersList[i].Type == "RecFlow"
                # Set recruitment flows
                if length(ParametersList[i].TimeDivision) > 2
                    mpSim.recruitmentSchemes[ParametersList[i].Index].UseRecFlowArray = true
                    mpSim.recruitmentSchemes[ParametersList[i].Index].RecFlowArray = Int.(zeros(mpSim.simLength/12 + 1))
                    for div in 1:(length(ParametersList[i].TimeDivision)-1)
                        mpSim.recruitmentSchemes[ParametersList[i].Index].RecFlowArray[ParametersList[i].TimeDivision[div] + 1:((ParametersList[i].TimeDivision[div + 1] == -1)? end : 1 + ParametersList[i].TimeDivision[div + 1])] = x[string(ParametersList[i].Type, i, div)].value
                    end
                else
                    setRecruitmentFixed(mpSim.recruitmentSchemes[ParametersList[i].Index], x[string(ParametersList[i].Type, i)].value)
                end
            elseif ParametersList[i].Type == "RecAge"
                # Set recruitment age
                if length(ParametersList[i].TimeDivision) > 2
                    mpSim.recruitmentSchemes[ParametersList[i].Index].UseRecAgeArray = true
                    mpSim.recruitmentSchemes[ParametersList[i].Index].RecAgeArray = Int.(zeros(mpSim.simLength/12 + 1))
                    for div in 1:(length(ParametersList[i].TimeDivision) - 1)
                        mpSim.recruitmentSchemes[ParametersList[i].Index].RecAgeArray[ParametersList[i].TimeDivision[div] + 1:((ParametersList[i].TimeDivision[div + 1] == -1)? end : 1+ParametersList[i].TimeDivision[i + 1])] = x[string(ParametersList[i].Type, i, div)].value
                    end
                else
                    mpSim.recruitmentSchemes[ParametersList[i].Index].ageDist = function () return 12*(x[string(ParametersList[i].Type, i)].value) end
                end
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

    end

    function mpSimSLS(x::Configuration, parameters::Dict{Symbol, Any})
        tStart = now()
        mpSim = deepcopy(InitMpSim)
        ParametersList = parameters[:ParametersList]
        targetList = parameters[:targetList]
        setmpSimParameters(mpSim, ParametersList, x)

        mpSim.simDB = SQLite.DB( "" )
        resetSimulation(mpSim)
        run( mpSim )

        score, fitness = ComputeFitness(mpSim, targetList)

        tEnd = now()
        timeElapsed = (tEnd - tStart).value / 1000
        println("score ", score, " Run time ", timeElapsed)
        return score, fitness
    end
end
