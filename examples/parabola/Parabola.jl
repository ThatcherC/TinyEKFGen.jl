### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# ╔═╡ 91825218-2b47-4b31-8862-26c2c846b2e2
haskey(ENV, "IN_TEST") || begin 
	import Pkg
	Pkg.add(path="../../", rev="main")
end

# ╔═╡ f3bbdac0-fd55-11ec-1ee5-37f857dc7ab4
begin
	using TinyEKFGen
	using SymEngine
	using LinearAlgebra
	using DataFrames
	using CSV
	using Plots
end

# ╔═╡ 177dd8ce-30a8-461d-9771-6f9db1df8498
println(pwd())

# ╔═╡ 89bf2ea0-4e20-46af-bc4c-bb16ae833e0a
@vars r_x r_y v_x v_y dt ACCEL

# ╔═╡ d947f988-e58f-4ec0-a183-d1bd73d08287
md"""
## Define State Vector

State vector here is a 2D position and velocity.
"""

# ╔═╡ 0a0043ac-d8c1-43c3-ab8f-4bb71161b115
begin
	r = [r_x, r_y]
	v = [v_x, v_y]

	x = [r..., v...]
end

# ╔═╡ 2bd678ea-ab77-4845-b2f4-2e7ab08d159a
md"""
## Define State Evolution
"""

# ╔═╡ 3ff5e117-b05c-48d2-aaf1-ac9c8063da2a
nextr = r + v*dt + 1/2 .* [0, ACCEL] .* dt^2

# ╔═╡ f86eea91-72f6-4197-8c98-c37825c9f4f4
nextv = [v_x, v_y+ACCEL*dt]

# ╔═╡ dcacc705-2f07-42df-bd16-947478a36c20
nextx = [nextr..., nextv...]

# ╔═╡ f60b4663-f4dd-42ce-9721-12d52f7aed47
md"""
## Observation Model
"""

# ╔═╡ 889a33a9-f940-4861-8736-dac7c071f773
begin
	meas_x = r_x
	meas_y = r_y

	predobs = [meas_x, meas_y]
end

# ╔═╡ bb9d0ded-70e3-4e74-ab2d-07b349b4939a
md"""
## Define Constants

Assign constant values to some symbols. In this case, our model assumes the acceleration due to gravity is -9.81. We're not being very careful with units here, but we could call this -9.81 m/s^2
"""

# ╔═╡ f5dde4a5-d238-40b6-a5a7-52bccdca576d
constants = Dict( ACCEL => -9.81)

# ╔═╡ 1786e901-035a-437f-b9f8-0225c66e535d
TinyEKFGen.outputHeader("parabola-ekf.h",x,
			nextx,
			predobs,
			constants)

# ╔═╡ 37d55ea5-6334-41af-bb37-c1b2ceef040f
md"""
### Load Dummy Data
"""

# ╔═╡ a547b5d2-e0c0-4313-8a1b-8cf4e6125139
md"""
### Generate Free Parabola States
"""

# ╔═╡ bbfcefc6-39bc-4ee7-9a1f-18de7542f987
nodragtruth = CSV.read("tables/nodrag-truth.csv", DataFrame);

# ╔═╡ 3208bb35-a20d-44b2-91ba-80adb4132e73
nodragnoisy = CSV.read("tables/nodrag-noisy.csv", DataFrame);

# ╔═╡ fad76790-2e20-4d16-a986-6565e9530050
md"""
### Generate Parabola with Air Resistance
"""

# ╔═╡ 44a3bfa4-0681-45dc-916a-db67b519fe41
draggytruth = CSV.read("tables/drag-truth.csv", DataFrame);

# ╔═╡ 9eb01da8-ccc3-4caa-9835-e129058cd7bd
draggynoisy = CSV.read("tables/drag-noisy.csv", DataFrame);

# ╔═╡ 21a86029-2564-4d94-bab6-a9c727c0340c
md"""
## Run Estimation on Data
"""

# ╔═╡ 32a3564d-8032-42ee-9392-d726fefc0fce
begin
	inputfile = "tables/nodrag-noisy.csv"; refdata = nodragtruth;
	#inputfile = "tables/drag-noisy.csv"; refdata = draggytruth;
end

# ╔═╡ 5d6c67c0-f06d-4564-b690-b7f1637db105
estimations = let
	run(`make parabola`)
	run(`./parabola -i $inputfile -o ekf-result.csv`)
	println("Compiled and ran!")
	CSV.read("ekf-result.csv", DataFrame, header=false)
end

# ╔═╡ 5fa31c85-5129-45c1-b2d9-a6dac2f50ede
length(ARGS)==0 && let
	p = plot(layout=(2,2))
	plot!(subplot=1, estimations[:, 1], estimations[:, 2], ribbon=estimations[:, 6], label="x")
	plot!(subplot=2, estimations[:, 1], estimations[:, 3], ribbon=estimations[:, 7], label="y")
	plot!(subplot=3, estimations[:, 1], estimations[:, 4], ribbon=estimations[:, 8], label="vx")
	plot!(subplot=4, estimations[:, 1], estimations[:, 5], ribbon=estimations[:, 9], label="vy")
end

# ╔═╡ 162e370e-aa34-401c-aa2d-6f7f3febe930
length(ARGS)==0 && let
	p = plot(layout=(2,2))
	plot!(subplot=1, estimations[:, 1], 
		estimations[:, 2]-refdata[:, "x"], 
		ribbon=estimations[:, 6],fillalpha=.5)
	plot!(subplot=2, estimations[:, 1], 
		estimations[:, 3]-refdata[:, "y"], 
		ribbon=estimations[:, 7],fillalpha=.5)

	plot!(subplot=3, estimations[:, 1], 
		estimations[:, 4]-refdata[:, "vx"], 
		ribbon=estimations[:, 8],fillalpha=.5)
	plot!(subplot=4, estimations[:, 1], 
		estimations[:, 5]-refdata[:, "vy"], 
		ribbon=estimations[:, 9],fillalpha=.5)
end

# ╔═╡ Cell order:
# ╠═91825218-2b47-4b31-8862-26c2c846b2e2
# ╠═f3bbdac0-fd55-11ec-1ee5-37f857dc7ab4
# ╠═177dd8ce-30a8-461d-9771-6f9db1df8498
# ╠═89bf2ea0-4e20-46af-bc4c-bb16ae833e0a
# ╟─d947f988-e58f-4ec0-a183-d1bd73d08287
# ╠═0a0043ac-d8c1-43c3-ab8f-4bb71161b115
# ╟─2bd678ea-ab77-4845-b2f4-2e7ab08d159a
# ╠═3ff5e117-b05c-48d2-aaf1-ac9c8063da2a
# ╠═f86eea91-72f6-4197-8c98-c37825c9f4f4
# ╠═dcacc705-2f07-42df-bd16-947478a36c20
# ╟─f60b4663-f4dd-42ce-9721-12d52f7aed47
# ╠═889a33a9-f940-4861-8736-dac7c071f773
# ╟─bb9d0ded-70e3-4e74-ab2d-07b349b4939a
# ╠═f5dde4a5-d238-40b6-a5a7-52bccdca576d
# ╠═1786e901-035a-437f-b9f8-0225c66e535d
# ╟─37d55ea5-6334-41af-bb37-c1b2ceef040f
# ╟─a547b5d2-e0c0-4313-8a1b-8cf4e6125139
# ╠═bbfcefc6-39bc-4ee7-9a1f-18de7542f987
# ╠═3208bb35-a20d-44b2-91ba-80adb4132e73
# ╟─fad76790-2e20-4d16-a986-6565e9530050
# ╠═44a3bfa4-0681-45dc-916a-db67b519fe41
# ╠═9eb01da8-ccc3-4caa-9835-e129058cd7bd
# ╟─21a86029-2564-4d94-bab6-a9c727c0340c
# ╠═32a3564d-8032-42ee-9392-d726fefc0fce
# ╠═5d6c67c0-f06d-4564-b690-b7f1637db105
# ╠═5fa31c85-5129-45c1-b2d9-a6dac2f50ede
# ╠═162e370e-aa34-401c-aa2d-6f7f3febe930
