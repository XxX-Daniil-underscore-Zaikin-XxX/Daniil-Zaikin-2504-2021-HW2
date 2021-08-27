using LinearAlgebra, StatsBase, TimerOutputs, DataFrames, StatsPlots, BenchmarkTools

 
function structured_P(L::Int; p::Float64 = 0.45, r::Float64 = 0.01)::Matrix{Float64}
    q = 1 - p - r
    P = diagm(fill(r,L)) + diagm(-1=>fill(q,L-1)) + diagm(1 => fill(p,L-1))
    P[1,1] = 1-p
    P[L,L] = 1-q
    return P
end

structured_π(L::Int; p::Float64 = 0.45, r::Float64 = 0.01)::Vector{Float64} = begin
    q = 1 - p - r
    [(p/q)^i  for i in 1:L] * (q-p) / p / (1-(p/q)^L) #Explicit expression (birth death)
end;

# Method 1: Linear Algebra
function method_1(input_matrix, L)
    # Transpose both sides, add a row to the bottom to represent the additional requirement
    return [I - input_matrix'; ones(1, L)] \ [zeros(L); 1]
end

# Method 2: Take a high matrix power
function method_2(input_matrix, L)
    matrix_power = 10^5 # arbitrary
    # Return the first column - the 'j' doesn't matter
    return (input_matrix^(matrix_power))[1, :]
end

# Method 3: Eigen trickery
function method_3(input_matrix, L)
    eigens = eigen(input_matrix')
    correct_vector = eigens.vectors[:, findfirst(isapprox(1), eigens.values)]
    return correct_vector * UniformScaling(1 / sum(correct_vector))
end

# Method 4: Random sample
function method_4(input_matrix, L)
    repeats = 10^5 # arbitrary
    states = 1:L
    current_value = rand(states)
    chain = zeros(L) # we don't need the order, just the counts
    for i in 1:repeats
        # Take a weighted sample based on the current state
        current_value = sample(states, Weights(view(input_matrix, current_value, :)))
        chain[current_value] += 1
    end
    # Apply the 1/n
    return map(x->x/repeats, chain)
end

# The L's given by the task
L_given = [2:5..., 10:10:50..., 100:100:500..., 1000]


# Get the benchmarks warmed up and ready to go
suite = BenchmarkGroup()
for method in [method_1, method_2, method_3, method_4]
    suite[String(Symbol(method))] = BenchmarkGroup()
end


# Prepare data structures
norms_df = DataFrame(a=L_given)
approx_methods_for_df = zip('b':'e', [method_1, method_2, method_3, method_4])

for approx_method ∈ approx_methods_for_df
    # Benchmark each L for each function, add it to suite
    for L in L_given
        suite[String(Symbol(approx_method[2]))][L] = @benchmarkable $(approx_method[2])(structured_P($L), $L)
    end

    # Put the error into the df for plotting
    norms_df[!, string(approx_method[1])] = map(L->norm(approx_method[2](structured_P(L), L) - structured_π(L)), L_given)
end

results = run(suite, verbose = true, seconds = 2, samples = 5)

# Plot the DataFrame

# Make sure none of the values break the graph
inds = (norms_df.c .> 0) .& (norms_df.d .> 0) .& (norms_df.b .> 0) .& (norms_df.e .> 0)
@df norms_df plot(
    :a[inds], [:b[inds] :c[inds] :d[inds] :e[inds]], 
    xaxis=:log10,
    xtickfont = font(5, "Courier"), 
    xlabel = "L", 
    ylabel = "Absolute Error", 
    yscale=:log10, 
    label = ["Method 1 (Linear Algebra)" "Method 2 (Matrix Power)" "Method 3 (Eigenvector)" "Method 4 (Random Seq)"], 
    title = "Demonstration of Approximation Methods"
)

benchmarks_df = DataFrame(L=L_given)
for method in keys(results)
    benchmarks_df[!, String(Symbol(method))] = map(L->median(results[method][L]).time, L_given)
end

@df benchmarks_df plot(
    :L, [:method_1 :method_2 :method_3 :method_4], 
    xaxis=:log10,
    xtickfont = font(5, "Courier"), 
    xlabel = "L", 
    ylabel = "Absolute Error", 
    yscale=:log10, 
    label = ["Method 1 (Linear Algebra)" "Method 2 (Matrix Power)" "Method 3 (Eigenvector)" "Method 4 (Random Seq)"], 
    title = "Demonstration of Approximation Methods"
)