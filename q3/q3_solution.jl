using Plots, DataFrames, StatsPlots, TimerOutputs

"""
Initialise the basics to avoid massive, incomprehensible globs of code
"""

function fds(func, x, h)
    return (func(x + h) - func(x))/(h)
end

function abs_error(func, x, h, approx_func, accur_value)
    return abs(accur_value - approx_func(func, BigFloat(x), BigFloat(h)))
end

function cds(func, x, h)
    return (func(x + h/2) - func(x - h/2))/(h)
end

function cvm(func, x, h)
    return imag(func(complex(x, h))/h)
end


# *avoid*, not *remove*
sine_set = (x->(sin(x^2)), BigFloat(0.5), big"0.968912421710644784144595449494")
e_set = (x->(ℯ^x), BigFloat(1), ℯ)
atan_set = (x -> (atan(x)/(1 + ℯ^(-x^2))), BigFloat(2), big"0.2746237281548575890153809496775478")


# Test the performance of each approximation for each function

performance_testing_range = map(x->(10.0^(-x)), 3.0:0.01:60)
to = TimerOutput()

optimal_value_df = DataFrame(function_name=String[], approximation_method=String[], optimal_h=BigFloat[], minimal_difference=BigFloat[])

for func_set in [(atan_set, "atan function"), (sine_set, "sine function"), (e_set, "exponent function")]
    for approx_method in [fds, cds, cvm]
        # Simply times how long it takes to collate all absolute errors and find their min
        @timeit to func_set[2]*": "*String(Symbol(approx_method)) begin
            b = map(h->abs_error(func_set[1][1], func_set[1][2], BigFloat(h), approx_method, func_set[1][3]), performance_testing_range)
            c = argmin(b)
        end
        push!(optimal_value_df, (func_set[2], String(Symbol(approx_method)), performance_testing_range[c], b[c]))
    end
end

println(to)
println(optimal_value_df)

# Demonstrate the differences via a chart

charting_range = map(x->(10.0^(-x)), 3.0:0.01:60) # to avoid complete computer death

# Fill the DataFrame with data points for each approximation
df = DataFrame(a=charting_range)
approx_methods_for_df = zip('b':'d', [fds, cds, cvm])
for approx_method ∈ approx_methods_for_df
    df[!, string(approx_method[1])] = map(h->abs_error(atan_set[1], BigFloat(atan_set[2]), BigFloat(h), approx_method[2], atan_set[3]), charting_range)
end

# Plot the DataFrame
inds = (df.c .> 0) .& (df.d .> 0) .& (df.b .> 0)
@df df plot(
    :a[inds], [:b[inds] :c[inds] :d[inds]], 
    xaxis=:log10, 
    xticks=map(x->(10.0^(-x)), 3.0:10:100.0), 
    xflip=true, 
    xtickfont = font(5, "Courier"), 
    xlabel = "h", 
    ylabel = "Absolute Error", 
    yscale=:log10, 
    label = ["Forward Diff. Scheme" "Central Diff. Scheme" "Complex Var. Method"], 
    title = "Demonstration of Approximation Methods"
)

# The differences in time performance for each approximation method were negligible, but the Complex Variable Method appeared to use more significantly more memory. All methods are perfectly capable of approximating a derivative.

# The main difference between these methods is apparent from the graph below. As we can see, the Central Difference Scheme and the Forward Difference Scheme both 'peter out' at sufficiently small values of $h$; after reaching a certain point, the absolute difference for both of these methods begins to rise with a logarithmic trend. This is not the case for the Complex Variable Method - its absolute error continues to plummet logarithmically, then comes to a hard stop within a small range of a minimum. This hard stop remains constant, which allows one to take extremely small values of $n$ without concern for rounding errors.