include( "./Functions/mpInit.jl" )

configFileName = joinpath( dirname( Base.source_path() ), "..", "Data", "SIMULdemo.xlsx")

mpSim = runSim( configFileName )

plotSimResults( mpSim, configFileName )
