@testset "Data Generation" begin
    println("Generating Data...")
    println(pwd())
    run(`julia -v`, wait=true)

    #run(Cmd(`julia examples/DataGeneration.jl`, env=("SAVE_PATH"=>"tables", )))
    run(
        `julia --startup-file=no ../examples/DataGeneration.jl ../examples/parabola/tables`,
        wait=true,
    )

    println("Comparing to Reference Data")

    res = outputof(
        `diff table-refs/drag-truth.csv ../examples/parabola/tables/drag-truth.csv`,
    )
    @test res[1] == ""
    @test res[2] == 0
end
