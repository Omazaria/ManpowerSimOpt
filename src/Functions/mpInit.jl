@everywhere begin
using ManpowerPlanning
using XLSX
using DataFrames
using Plots
plotly()
end
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
