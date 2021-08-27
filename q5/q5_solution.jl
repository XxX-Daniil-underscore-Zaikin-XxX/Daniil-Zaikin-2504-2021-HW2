using Plots, Measures, HTTP, Serialization, Random

#These four convenience functions extract the state variable from the state vector
#It is assumed the layout of the vector u is u = [v_x, v_y, x, y]
state_v_x(u::Vector{Float64}) = u[1]
state_v_y(u::Vector{Float64}) = u[2]
state_x(u::Vector{Float64}) = u[3]
state_y(u::Vector{Float64}) = u[4]

"""
Modified version of the given function. Takes a Vector of tuples of (Float, Vector), first element being h and the second being the values corresponding to that h
"""
function plot_solutions( t::Int64, 
    u::Vector{Tuple{Float64,Vector{Vector{Float64}}}};
    title::String = "",
    label::Union{String, Bool} = false,
    show_energy = true,
    combine_positions = false) where T
    
    position_plots = [] # Storing plots
    energy_values = [] # Storing values to plot later

    # Iterates through given sets of values, does mostly the same thing as the given function
    for (h, u_vec) in u
        x, y, v_x, v_y = state_x.(u_vec), state_y.(u_vec), state_v_x.(u_vec), state_v_y.(u_vec)

        r = @. sqrt(x^2 + y^2)
        E = @. 0.5*(v_x^2 + v_y^2) - 1.0/r

        # Pushes to plot list instead of plotting outright
        push!(position_plots, plot(  reduce_data_points([x], [y])..., label = label, xlabel= "X", ylabel = "Y",
        title = title*" (position): h = $h", aspectratio=1,legend=:topleft,ylim=(-7,7)))
        scatter!([0], [0], ms=15, msw=0, c=:orange, shape =:star, label="Sun")
        scatter!([x[1]], [y[1]], ms=4, msw=0, c=:blue, shape =:circle, label="Earth initial position")
        
        # Push values without plotting
        push!(energy_values, (h, E))
    end

    # Plot all energy values all at once
    x_values_full, y_values_full = map(x->1:x[1]:t, energy_values), map(x->x[2], energy_values)
    p4 = plot(  reduce_data_points(x_values_full, y_values_full)..., xlabel = "Time", ylabel = "Energy",
    label = transpose(map(x->x[1], energy_values)), title = title*" (energy)")
    
    # Exclude the energy plot if not needed
    plots_to_plot = position_plots
    if show_energy
        push!(plots_to_plot, p4)
    end

    # Collate all plots into the apex plot
    return plot(plots_to_plot..., margin = 10mm,size=(1000,1000))
end;

"""
"Simple" function for reducing the amount of data points in a graph. Both args must be vectors of vectors.
"""
function reduce_data_points(x_values_full, y_values_full)
    x_values_truncated, y_values_truncated = [], []
    for i in eachindex(x_values_full)
        len = length(x_values_full[i])
        randsub = randsubseq(1:len, min(1000, len)/len)
        push!(x_values_truncated, x_values_full[i][randsub])
        push!(y_values_truncated, y_values_full[i][randsub])
    end
    return x_values_truncated, y_values_truncated
end

# Using the same starting values as given
h_list = map(x->10^(-x), 2.0:4.0)
t_max = 200
u_0 = [0., 1, 1.5, 0]

"""
Computes the RHS for the one body problem (the t arg has been removed)
"""
function df_dt_one_body(u::Vector{Float64})::Vector{Float64}
    M, G = 1, 1
    r = sqrt(state_x(u)^2 + state_y(u)^2)
    return [-M*G*state_x(u)/r^3, -M*G*state_y(u)/r^3, state_v_x(u), state_v_y(u)]
end;

"""
Performs euler method. f is a function which takes a single arg of same type as u_0
"""
function euler_method(f, u_0, step_size, t_vec)
    values = [u_0]
    previous = u_0
    for i in 2:length(t_vec)
        next = previous .+ step_size * f(previous)
        previous = next
        push!(values, next)
    end
    return values
end

"""
Performs RK4 method. f takes a single argument of same type as u_0
"""
function rk4_method(f, u_0, step_size, t_vec)
    values = [u_0]
    prev_value = u_0
    # Could go at it recursively, but I also don't want to make my code even more unreadable
    for i in 2:length(t_vec)
        next_value = prev_value .+ rk4_calculate_section(f, prev_value, step_size)
        push!(values, next_value)
        prev_value = next_value
    end
    return values
end

"""
Helper function for the cumbersome calculation. Args must be vectors.
"""
function rk4_calculate_section(f, current_elem, step_size)
    k_1 = f(current_elem)
    k_2 = f(current_elem .+ ((step_size/2) .* k_1))
    k_3 = f(current_elem .+ ((step_size/2) .* k_2))
    k_4 = f(current_elem .+ (step_size .* k_3))
    return (step_size/6) .* (k_1 .+ (2 .* k_2) .+ (2 .* k_3) .+ k_4)
end


# The part where the graphs get drawn

display(plot_solutions(t_max, map(h -> (h, euler_method(df_dt_one_body, u_0, h, 1:h:t_max)), h_list), title="Euler's Method"))

h_best, h_worst = 0.01, 0.01 # for RK4 and Euler respectively

anim = @animate for i = 30:max(t_max÷50, 1):t_max
    plot_solutions(i, [(h_best, rk4_method(df_dt_one_body, u_0, h_best, 1:h_best:i)), (h_worst, euler_method(df_dt_one_body, u_0, h_worst, 1:h_worst:i))], title="Combined animation", show_energy = false)
end

gif(anim, "tutorial_anim_fps30.gif", fps = 30)

h_list_rk4 = [0.01, 0.1, 0.5]
display(plot_solutions(t_max, map(h -> (h, rk4_method(df_dt_one_body, u_0, h, 1:h:t_max)), h_list_rk4), title="RK4 Method"))