include(joinpath( dirname( Base.source_path() ), "Functions", "mpInitGA.jl" ))

configFileName =  joinpath( dirname( Base.source_path() ), "..", "Data", "SIMULdemo.xlsx")

mpSim = CreatSim( configFileName )

function GenerateRecArray(RecVals::Array{Int}, TimeDiv::Array{Int}, SimLength::Float64)
    RecArray = Int.(zeros(SimLength/12 + 1))
    for i in 1:length(RecVals)
        RecArray[TimeDiv[i] + 1:1+((TimeDiv[i + 1] == -1)? Int(SimLength/12) : TimeDiv[i + 1])] = RecVals[i]
    end
    return RecArray
end

RecArrays = [[300, 150],
             [259, 200],
             [250, 14],
             [134, 20],
             [176, 107],
             [122, 254],
             [259, 189],
             [223, 285],
             [150, 122],
             [136, 81],
             ]

for i in 1:length(mpSim.recruitmentSchemes)
    mpSim.recruitmentSchemes[i].UseRecFlowArray = true
    mpSim.recruitmentSchemes[i].RecFlowArray = GenerateRecArray(RecArrays[i], [1, 5, -1], mpSim.simLength)
end

# mpSim.recruitmentSchemes[2].UseRecFlowArray = true
# mpSim.recruitmentSchemes[2].RecFlowArray = GenerateRecArray([200, 75, 0], [0, 7, 15, -1], mpSim.simLength)
#
# mpSim.recruitmentSchemes[3].UseRecFlowArray = true
# mpSim.recruitmentSchemes[3].RecFlowArray = GenerateRecArray([200, 75, 0], [0, 7, 15, -1], mpSim.simLength)
#
# mpSim.recruitmentSchemes[4].UseRecFlowArray = true
# mpSim.recruitmentSchemes[4].RecFlowArray = GenerateRecArray([200, 75, 0], [0, 7, 15, -1], mpSim.simLength)
#
# mpSim.recruitmentSchemes[1].UseRecAgeArray = true
# mpSim.recruitmentSchemes[1].RecAgeArray = GenerateRecArray([19, 25, 16], [0, 7, 15, -1], mpSim.simLength)
#
# mpSim.recruitmentSchemes[2].UseRecAgeArray = true
# mpSim.recruitmentSchemes[2].RecAgeArray = GenerateRecArray([19, 25, 16], [0, 7, 15, -1], mpSim.simLength)
#
# mpSim.recruitmentSchemes[3].UseRecAgeArray = true
# mpSim.recruitmentSchemes[3].RecAgeArray = GenerateRecArray([19, 25, 16], [0, 7, 15, -1], mpSim.simLength)
#
# mpSim.recruitmentSchemes[4].UseRecAgeArray = true
# mpSim.recruitmentSchemes[4].RecAgeArray = GenerateRecArray([19, 25, 16], [0, 7, 15, -1], mpSim.simLength)

tStart = now()
println("Running... ")
#ExecNb += 1
#mpSim.simDB = SQLite.DB( "" )
run( mpSim )

configFileName = joinpath( dirname( Base.source_path() ), "..", "Data", "SIMULdemo.xlsx")


plotSimResults(mpSim, configFileName)
