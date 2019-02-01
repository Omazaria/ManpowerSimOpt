#using Distributed
#addprocs(1)

include(joinpath( dirname( Base.source_path() ), myid()==1? "": "src", "Types", "GAforManSim.jl"))
#@everywhere
using GeneticAlgorithms

model = runga(GAforManSim; initial_pop_size = 32)

#population(model)

include(joinpath( dirname( Base.source_path() ), "Functions", "mpInitGA.jl" ))
#using ManpowerPlanning
configFileName = joinpath( dirname( Base.source_path() ), "..", "Data", "SIMULdemo.xlsx")
plotSimResults(population(model)[1].mpSim, configFileName)


ent = population(model)[1]

println("____________________________________________")
println()

println("R 1A-B  : ", ent.mpSim.recruitmentSchemes[1].recDist()," R 1A-D  : ", ent.mpSim.recruitmentSchemes[2].recDist()," R 1B-B  : ", ent.mpSim.recruitmentSchemes[3].recDist()," R 1B-D  : ", ent.mpSim.recruitmentSchemes[4].recDist())

print("A 1A-B  : ", ent.mpSim.recruitmentSchemes[1].ageDist()/12)
print(" A 1A-D  : ", ent.mpSim.recruitmentSchemes[2].ageDist()/12)
print(" A 1B-B  : ", ent.mpSim.recruitmentSchemes[3].ageDist()/12)
println(" A 1B-D  : ", ent.mpSim.recruitmentSchemes[4].ageDist()/12)

for TransTuple in ent.mpSim.otherStateList
    for i in 1:length(TransTuple[2])
        if TransTuple[2][i].name == "B+"
            println("Trans B+ : ", TransTuple[2][i].startState.name, "->", TransTuple[2][i].endState.name, " Proba : ", TransTuple[2][i].probabilityList[1], " Tenure : ", (TransTuple[2][i].extraConditions[1].val/12))
        end
    end
end
println("Retirement Age : ", (ent.mpSim.retirementScheme.retireAge/12))
fitn = ent.fitness["active"][1] + abs(ent.fitness["active"][2])
fitn = ent.fitness["AdOff"][1] + abs(ent.fitness["AdOff"][2])
fitn = ent.fitness["Off"][1] + abs(ent.fitness["Off"][2])
fitn = ent.fitness["BO"][1] + abs(ent.fitness["BO"][2])
fitn = ent.fitness["BDL"][1] + abs(ent.fitness["BDL"][2])
println("Fitness : ", fitn)
println("____________________________________________")
