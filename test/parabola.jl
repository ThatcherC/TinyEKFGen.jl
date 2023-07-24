@testset "Parabola Test" begin
    println(pwd())
    println("Navigating to Parabola Example")
    cd("../examples/parabola")
    println(pwd())
    run(`julia -v`, wait=true)

    #run(Cmd(`julia examples/DataGeneration.jl`, env=("SAVE_PATH"=>"tables", )))
    res = run(Cmd(`julia --startup-file=no Parabola.jl IN_TEST`), wait=true)

    @test res.exitcode == 0
    @test isfile("parabola-ekf.h")
    @test isfile("parabola")

    println("Navigating back to test/")
    cd("../../")
    println(pwd())
end
