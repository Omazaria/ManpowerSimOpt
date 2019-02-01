#@everywhere begin
using ManpowerPlanning
using XLSX
using DataFrames
using Plots
plotly()
#end
function CreatSim( fName::String )#::ManpowerSimulation

    tmpFileName = endswith( fName, ".xlsx" ) ? fName : fName * ".xlsx"

    if !ispath( tmpFileName )
        error( "'$tmpFileName' is not a valid file." )
    end  # if !ispath( tmpFilename )

    mpSim = ManpowerSimulation( tmpFileName )
    runSim = true

    XLSX.openxlsx( tmpFileName ) do xf
        # Make network plot if requested.
        if XLSX.hassheet( xf, "State Map" )
            sheet = xf[ "State Map" ]

            if sheet[ "B3" ] == "YES"
                println( "Creating network plot." )
                tStart = now()
                plotTransitionMap( mpSim, sheet )
                tEnd = now()
                timeElapsed = (tEnd - tStart).value / 1000
                println( "Network plot time: $timeElapsed seconds." )
            end  # if sheet[ "B3" ] == "YES"
        end  # if XLSX.hassheet( xf, "State Map" )

        # Run only if flag is okay.
        sheet = xf[ "General" ]

        if sheet[ "B14" ] == "NO"
            println( "No simulation run requested." )
            runSim = false
        end  # if sheet[ "B11" ] == "NO"
    end  # XLSX.openxlsx( tmpFileName ) do xf

    return mpSim

end

function runSim( fName::String )::ManpowerSimulation

    tmpFileName = endswith( fName, ".xlsx" ) ? fName : fName * ".xlsx"

    if !ispath( tmpFileName )
        error( "'$tmpFileName' is not a valid file." )
    end  # if !ispath( tmpFilename )

    mpSim = ManpowerSimulation( tmpFileName )
    runSim = true

    XLSX.openxlsx( tmpFileName ) do xf
        # Make network plot if requested.
        if XLSX.hassheet( xf, "State Map" )
            sheet = xf[ "State Map" ]

            if sheet[ "B3" ] == "YES"
                println( "Creating network plot." )
                tStart = now()
                plotTransitionMap( mpSim, sheet )
                tEnd = now()
                timeElapsed = (tEnd - tStart).value / 1000
                println( "Network plot time: $timeElapsed seconds." )
            end  # if sheet[ "B3" ] == "YES"
        end  # if XLSX.hassheet( xf, "State Map" )

        # Run only if flag is okay.
        sheet = xf[ "General" ]

        if sheet[ "B14" ] == "NO"
            println( "No simulation run requested." )
            runSim = false
        end  # if sheet[ "B11" ] == "NO"
    end  # XLSX.openxlsx( tmpFileName ) do xf

    if runSim
        println( "Running simulation." )
        tStart = now()
        run( mpSim )
        tEnd = now()
        timeElapsed = (tEnd - tStart).value / 1000
        println( "Simulation time: $timeElapsed seconds." )
    end  # if runSim

    return mpSim

end


function plotSimResults( mpSim, fName )::Void

    tmpFileName = endswith( fName, ".xlsx" ) ? fName : fName * ".xlsx"

    if !ispath( tmpFileName )
        error( "'$tmpFileName' is not a valid file." )
    end  # if !ispath( tmpFilename )

    # Generate plots.
    println( "Generating plots. This can take a while..." )
    tStart = now()
    showPlotsFromFile( mpSim, fName )
    showFluxPlotsFromFile( mpSim, fName )
    tEnd = now()
    timeElapsed = (tEnd - tStart).value / 1000
    println( "Plot generation time: $timeElapsed seconds." )
    return

end

println("Worker ", myid())
#end
# function generateHierarchy( mpSim::ManpowerSimulation,
#     attrList::String... )::Void
#
#     # Retain only the attributes that actually exist in the simulation.
#     attrsInSim = vcat( mpSim.initAttrList, mpSim.otherAttrList )
#     attrNames = map( attr -> attr.name, attrsInSim )
#     tmpAttrList = unique( collect( attrList ) )
#     filter!( attrName -> attrName ∈ attrNames, tmpAttrList )
#
#     if isempty( tmpAttrList )
#         return
#     end  # if isempty( tmpAttrList )
#
#     attrs = similar( tmpAttrList, PersonnelAttribute )
#
#     # Get the attributes with the retained names.
#     for ii in eachindex( tmpAttrList )
#         attrInd = findfirst( attr -> attr.name == tmpAttrList[ ii ],
#             attrsInSim )
#         attrs[ ii ] = attrsInSim[ attrInd ]
#     end  # for ii in eachindex( tmpAttrList )
#
#     partitionByAttribute( collect( keys( mpSim.stateList ) ), attrs, 1, mpSim )
#     return
#
# end  # generateHierarchy( mpSim, attrList )
#
#
# function partitionByAttribute( stateList::Vector{String},
#     attrList::Vector{PersonnelAttribute}, level::Int,
#     mpSim::ManpowerSimulation, name::String = "" )::Void
#
#     println( "Level $level: ", stateList )
#     statePartition = Dict{String, Vector{String}}()
#     listOfStates = map( stateName -> mpSim.stateList[ stateName ], stateList )
#     attr = attrList[ level ]
#     statePartitioned = similar( stateList, Bool )
#
#     # Generate the partition.
#     for attrVal in attr.possibleValues
#         stateInds = map( listOfStates ) do state
#             return haskey( state.requirements, attr.name ) &&
#                 ( attrVal ∈ state.requirements[ attr.name ] )
#         end  # map( listOfStates ) do state
#
#         if any( stateInds )
#             statePartition[ attrVal ] = stateList[ stateInds ]
#         end  # if any( stateInds )
#
#         statePartitioned .|= stateInds
#     end  # for attrVal in attrList[ level ].possibleValues
#
#     # Generate part for states with attribute not filled in.
#     if !all( statePartitioned )
#         statePartition[ "undefined" ] = stateList[ .!statePartition ]
#     end  # if !all( statePartitioned )
#
#     for attrVal in keys( statePartition )
#         newName = name * ( name == "" ? "" : "; " ) * "$(attr.name):$attrVal"
#
#         # Generate compound state.
#         if length( statePartition[ attrVal ] ) > 1
#             addCompoundState!( mpSim, newName, -1, statePartition[ attrVal ]... )
#             partitionByAttribute( statePartition[ attrVal ], attrList,
#                 level + 1, mpSim, newName )
#         end  # if length( statePartition[ attrVal ] ) > 1
#     end  # for attrVal in keys( statePartition )
#
#     return  # for attrVal in attrList[ level ].possibleValues
#
# end  # partitionByAttribute( stateList, attrList, level, mpSim, name )
