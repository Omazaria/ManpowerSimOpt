#@everywhere
module GAforManSim

    using GeneticAlgorithms
    using SQLite


    include(joinpath( dirname( Base.source_path() ), "..", "Functions", "mpInitGA.jl" )) #: "src" myid()==1?
    include(joinpath( dirname( Base.source_path() ), "Targets.jl" ))
    include(joinpath( dirname( Base.source_path() ), "Parameters.jl" ))
    include(joinpath( dirname( Base.source_path() ), "..", "Functions", "ComputeFitness.jl" ))
    if myid()==1
        configFileName = joinpath( dirname( Base.source_path() ), "..", "..", "Data", "SIMULdemo.xlsx")
    else
        configFileName = joinpath( dirname( Base.source_path() ), "Data", "SIMULdemo.xlsx")
    end

    InitMpSim = CreatSim( configFileName )
    BestSol = Vector{Float64}()
    AllSols = Vector{Float64}()

    #export BestSol, AllSols

    import Base.isless

    mutable struct GAEngine <: Entity
        mpSim::ManpowerSimulation
        fitness
        score
        Generation

        function GAEngine()
            gamp = new( deepcopy(InitMpSim), nothing)

            for i in 1:length(ParametersList)
                if ParametersList[i].Type == "RecFlow"
                    # Set recruitment flows
                    if length(ParametersList[i].TimeDivision) > 2
                        gamp.mpSim.recruitmentSchemes[ParametersList[i].Index].UseRecFlowArray = true
                        gamp.mpSim.recruitmentSchemes[ParametersList[i].Index].RecFlowArray = Int.(zeros(gamp.mpSim.simLength/12 + 1))
                        for div in 1:(length(ParametersList[i].TimeDivision)-1)
                            gamp.mpSim.recruitmentSchemes[ParametersList[i].Index].RecFlowArray[ParametersList[i].TimeDivision[div] + 1:((ParametersList[i].TimeDivision[div + 1] == -1)? end : 1 + ParametersList[i].TimeDivision[div + 1])] = rand(ParametersList[i].Min:ParametersList[i].Max)
                        end
                    else
                        setRecruitmentFixed(gamp.mpSim.recruitmentSchemes[ParametersList[i].Index], rand(ParametersList[i].Min:ParametersList[i].Max))
                    end
                elseif ParametersList[i].Type == "RecAge"
                    # Set recruitment age
                    if length(ParametersList[i].TimeDivision) > 2
                        gamp.mpSim.recruitmentSchemes[ParametersList[i].Index].UseRecAgeArray = true
                        gamp.mpSim.recruitmentSchemes[ParametersList[i].Index].RecAgeArray = Int.(zeros(gamp.mpSim.simLength/12 + 1))
                        for div in 1:(length(ParametersList[i].TimeDivision) - 1)
                            gamp.mpSim.recruitmentSchemes[ParametersList[i].Index].RecAgeArray[ParametersList[i].TimeDivision[div] + 1:((ParametersList[i].TimeDivision[div + 1] == -1)? end : 1+ParametersList[i].TimeDivision[i + 1])] = rand(ParametersList[i].Min:ParametersList[i].Max)
                        end
                    else
                        gamp.mpSim.recruitmentSchemes[ParametersList[i].Index].ageDist = function () return 12*(rand(ParametersList[i].Min:ParametersList[i].Max)) end
                    end
                elseif ParametersList[i].Type == "TransProba"
                    for TransTuple in gamp.mpSim.otherStateList
                        if !contains(TransTuple[1].name, ParametersList[i].StartingState)
                            continue
                        end
                        for j in 1:length(TransTuple[2])
                            if TransTuple[2][j].name ==ParametersList[i].Name
                                TransTuple[2][j].probabilityList = [rand()*(ParametersList[i].Max - ParametersList[i].Min) + ParametersList[i].Min]
                            end
                        end
                    end
                elseif ParametersList[i].Type == "TransTenure"
                    for TransTuple in gamp.mpSim.otherStateList
                        if !contains(TransTuple[1].name, ParametersList[i].StartingState)
                            continue
                        end
                        for j in 1:length(TransTuple[2])
                            if TransTuple[2][j].name ==ParametersList[i].Name
                                TransTuple[2][j].extraConditions[1].val = 12*(rand(ParametersList[i].Min:ParametersList[i].Max))
                            end
                        end
                    end
                elseif ParametersList[i].Type == "PEAge"
                    # Retirement Age
                    gamp.mpSim.retirementScheme.retireAge = 12*(rand(ParametersList[i].Min:ParametersList[i].Max))
                end
            end


            # for i in 1:length(gamp.mpSim.recruitmentSchemes)
            #             # Set recruitment flows 0 -> 1000
            #             setRecruitmentFixed(gamp.mpSim.recruitmentSchemes[i], abs.(rand(Int) % 1001))
            #
            #             # Set recruitment age 16 -> 32
            #             gamp.mpSim.recruitmentSchemes[i].ageDist = function () return 12*(abs.(rand(Int) % 17) + 16) end
            # end
            #
            # println("R 1A-B  : ", gamp.mpSim.recruitmentSchemes[1].recDist()," R 1A-D  : ", gamp.mpSim.recruitmentSchemes[2].recDist()," R 1B-B  : ", gamp.mpSim.recruitmentSchemes[3].recDist()," R 1B-D  : ", gamp.mpSim.recruitmentSchemes[4].recDist())
            # println("A 1A-B  : ", gamp.mpSim.recruitmentSchemes[1].ageDist()/12," A 1A-D  : ", gamp.mpSim.recruitmentSchemes[2].ageDist()/12," A 1B-B  : ", gamp.mpSim.recruitmentSchemes[3].ageDist()/12," A 1B-D  : ", gamp.mpSim.recruitmentSchemes[4].ageDist()/12)
            #
            #
            # # Set B+ success probability 0 -> 100% / Set B+ tenure 1 -> 25
            # TempoProba1A = round(rand(), 3)
            # TempoTenure1A = abs.(rand(Int) % 25) + 1
            # TempoProba1B = round(rand(), 3)
            # TempoTenure1B = abs.(rand(Int) % 25) + 1
            # for TransTuple in gamp.mpSim.otherStateList
            #     for i in 1:length(TransTuple[2])
            #         if !contains(TransTuple[1].name, "-D")
            #             continue
            #         end
            #         if TransTuple[2][i].name == "B+"
            #             if contains(TransTuple[1].name, "1A")
            #                 TransTuple[2][i].probabilityList = [TempoProba1A]
            #                 TransTuple[2][i].extraConditions[1].val = 12*(TempoTenure1A)
            #             else
            #                 TransTuple[2][i].probabilityList = [TempoProba1B]
            #                 TransTuple[2][i].extraConditions[1].val = 12*(TempoTenure1B)
            #             end
            #             println("Trans B+ : ", TransTuple[2][i].startState.name, "->", TransTuple[2][i].endState.name, " Proba : ", TransTuple[2][i].probabilityList[1], " Tenure : ", (TransTuple[2][i].extraConditions[1].val/12))
            #         end
            #     end
            # end
            #
            # # Set retirement age 40 -> 70
            # gamp.mpSim.retirementScheme.retireAge = 12*(abs.(rand(Int) % 31) + 40)
            # println("Retirement Age : ", (gamp.mpSim.retirementScheme.retireAge/12))
            # println()
            # println()

            gamp.Generation = 1
            return gamp
        end
        function GAEngine(a::Int)
            if a == 1
                gamp = new( deepcopy(InitMpSim), nothing)

                for i in 1:length(ParametersList)
                    if ParametersList[i].Type == "RecFlow"
                        # Set recruitment flows
                        if length(ParametersList[i].TimeDivision) > 2
                            gamp.mpSim.recruitmentSchemes[ParametersList[i].Index].UseRecFlowArray = true
                            gamp.mpSim.recruitmentSchemes[ParametersList[i].Index].RecFlowArray = Int.(zeros(gamp.mpSim.simLength/12 + 1))
                            for div in 1:(length(ParametersList[i].TimeDivision)-1)
                                gamp.mpSim.recruitmentSchemes[ParametersList[i].Index].RecFlowArray[ParametersList[i].TimeDivision[div] + 1:((ParametersList[i].TimeDivision[div + 1] == -1)? end : 1 + ParametersList[i].TimeDivision[div + 1])] = ParametersList[i].StartVal
                            end
                        else
                            setRecruitmentFixed(gamp.mpSim.recruitmentSchemes[ParametersList[i].Index], ParametersList[i].StartVal)
                        end
                    elseif ParametersList[i].Type == "RecAge"
                        # Set recruitment age
                        if length(ParametersList[i].TimeDivision) > 2
                            mpSim.recruitmentSchemes[ParametersList[i].Index].UseRecAgeArray = true
                            mpSim.recruitmentSchemes[ParametersList[i].Index].RecAgeArray = Int.(zeros(mpSim.simLength/12 + 1))
                            for div in 1:(length(ParametersList[i].TimeDivision) - 1)
                                mpSim.recruitmentSchemes[ParametersList[i].Index].RecAgeArray[ParametersList[i].TimeDivision[div] + 1:((ParametersList[i].TimeDivision[div + 1] == -1)? end : 1+ParametersList[i].TimeDivision[i + 1])] = ParametersList[i].StartVal
                            end
                        else
                            gamp.mpSim.recruitmentSchemes[ParametersList[i].Index].ageDist = function () return 12*(ParametersList[i].StartVal) end
                        end
                    elseif ParametersList[i].Type == "TransProba"
                        for TransTuple in gamp.mpSim.otherStateList
                            if !contains(TransTuple[1].name, ParametersList[i].StartingState)
                                continue
                            end
                            for j in 1:length(TransTuple[2])
                                if TransTuple[2][j].name ==ParametersList[i].Name
                                    TransTuple[2][j].probabilityList = [ParametersList[i].StartVal]
                                end
                            end
                        end
                    elseif ParametersList[i].Type == "TransTenure"
                        for TransTuple in gamp.mpSim.otherStateList
                            if !contains(TransTuple[1].name, ParametersList[i].StartingState)
                                continue
                            end
                            for j in 1:length(TransTuple[2])
                                if TransTuple[2][j].name ==ParametersList[i].Name
                                    TransTuple[2][j].extraConditions[1].val = 12*(ParametersList[i].StartVal)
                                end
                            end
                        end
                    elseif ParametersList[i].Type == "PEAge"
                        # Retirement Age
                        gamp.mpSim.retirementScheme.retireAge = 12*(ParametersList[i].StartVal)
                    end
                end

                gamp.Generation = 1
                return gamp
            else
                return GAEngine()
            end
        end
    end

    include(joinpath( dirname( Base.source_path() ), "..", "Functions", "GAforManSim.jl" ))
end
