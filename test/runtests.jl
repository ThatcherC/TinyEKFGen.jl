using TinyEKFGen

using Test

using SymEngine

function outputof(command)
    io = IOBuffer()
    line = pipeline(command, stdout=io)
    result = run(line)

    code = result.exitcode

    output = String(take!(io))

    output, code
end

@testset "Integration" begin
    include("tablegeneration.jl")

    ENV["IN_TEST"] = true
    include("parabola.jl")
end

#function symbolicStringNoExponents(f::SymEngine.Basic)

@testset "Output C Exponents" begin
    @vars x y z
    f = x^2 + y^0.5 + z^-1
    fRewrite = TinyEKFGen.rewriteExponents(f)
    fCstring = TinyEKFGen.symbolicStringNoExponents(f)

    # check rewritten expression evaluates to the same as the original!

    @test N(SymEngine.subs(f, x => 4.1, y => 81, z => 15)) ≈
          N(SymEngine.subs(Basic(fRewrite), x => 4.1, y => 81, z => 15))

    # check no ^ characters are included in the C string
    @test !occursin('^', fCstring)
end

# function cprintmat(out, M, name)

# function diffvwrtv(
# constant matrix
@testset "diffvwrtv" begin
    @vars w x y z

    v2 = [x, y]
    v3 = [x, y, z]
    # expect square of zeros
    @testset "Constant" begin
        M = rand(3) * w
        Mwrtv3 = TinyEKFGen.diffvwrtv(M, v3)

        @test Mwrtv3 == Basic.(zeros(Int64, 3, 3))

        # check shape: expect 2 rows by 3 columns of zeros
        Mwrtv2 = TinyEKFGen.diffvwrtv(M, v2)
        @test Mwrtv2 == Basic.(zeros(Int64, 3, 2))
    end

    @testset "Linear" begin
        coeffs = rand(3, 3)
        V = coeffs * v3 + rand(3) * w

        @test TinyEKFGen.diffvwrtv(V, v3) == Basic.(coeffs)
        @test TinyEKFGen.diffvwrtv(V, v2) == Basic.(coeffs[:, 1:2])
    end

    @testset "Non-Linear" begin
        V = [x * y * w, cos(x + y * z), w * x * exp(z), 2 / x]
        Jxyz =
            [
                y*w -sin(x + y * z) w*exp(z) -2/x^2
                x*w -z*sin(x + y * z) 0 0
                0 -y*sin(x + y * z) w*x*exp(z) 0
            ]'

        @test TinyEKFGen.diffvwrtv(V, v3) == Basic.(Jxyz)
        @test TinyEKFGen.diffvwrtv(V, [y, z]) == Basic.(Jxyz[:, 2:3])
    end
end

# function outputHeader

# 
