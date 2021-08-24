using HTTP, JSON, DataFrames, CSV


"""
Returns total num of escaped chars and lines for any cell, including any outputs
"""
function get_cell_counts_shared(cell)
    char_total, lines_total = 0, 0
    for line in cell["source"]
        char_total += length(String(line))
    end

    # Count outputs if they exist
    if haskey(cell, "outputs")
        char_outputs, lines_outputs = get_counts_outputs(cell["outputs"])
        char_total += char_outputs
        lines_total += lines_outputs
    end

    lines_total += length(cell["source"])
    return char_total, lines_total
end


"""
Returns number of escaped chars and lines from an array of outputs. It considers only the following:
 - The `text` portion of an `stdout` output
 - A `text/plain` portion of a `data` output
"""
function get_counts_outputs(outputs)
    char_total, line_total = 0, 0

    # Loops through lines, checks if keys exist, add to counts if they do
    for output in outputs
        if haskey(output, "name") && output["name"] == "stdout"
            for line in output["text"]
                char_total += length(line)
            end
            line_total += length(output["text"])
        elseif haskey(output, "data") && haskey(output["data"], "text/plain")
            for line in output["data"]["text/plain"]
                char_total += length(line)
            end
            line_total += length(output["data"]["text/plain"])
        end
    end
    return char_total, line_total
end

"""
Returns array of counts for #, ##, ###, and #### (respectively) in a cell.
"""
function get_cell_counts_markdown(cell)
    count = zeros(Int32, 4)
    for line in cell["source"]
        # Loops through each index of the above array, also using it to count the number of # in a row
        for i in eachindex(count)
            # Considers a # surrounded by non-#es a match. Also takes into account BoL and EoL.
            count[i] += length(collect(m.match for m in eachmatch(Regex("^#{$i}[^#]|[^#]#{$i}[^#]|[^#]#{$i}^"), String(line))))
        end
    end
    return count
end

"""
Returns array of counts for `return`, `for`, `if`, and `using` (respectively) in a cell
"""
function get_cell_counts_code(cell)
    matches = ["return", "for", "if", "using"]
    count = zeros(Int32, 4)
    for line in cell["source"]
        # Loop through array of matches, add each match to the count
        for i in eachindex(matches)
            count[i] += length(collect(m.match for m in eachmatch(Regex(matches[i]), String(line))))
        end
    end
    return count
end

"""
Returns a formatted, processed row representing a markdown cell
"""
function process_cell_markdown(cell_number, markdown_cell)
    return [cell_number, get_cell_counts_shared(markdown_cell)..., get_cell_counts_markdown(markdown_cell)...]
end

"""
Returns a formatted, processed row representing a code cell
"""
function process_cell_code(cell_number, code_cell)
    return [cell_number, get_cell_counts_shared(code_cell)..., get_cell_counts_code(code_cell)...]
end

"""
Iterates through all given cells, formats the markdown and code cells into two separate DataFrames, returns them.
"""
function process_cells_all(all_cells)
    markdown_df = DataFrame(cell_number = Int[], character_count = Int[], line_count = Int[], one_hash = Int[], two_hash = Int[], three_hash = Int[], four_hash = Int[])
    code_df = DataFrame(cell_number = Int[], character_count = Int[], line_count = Int[], returns = Int[], fors = Int[], ifs = Int[], usings = Int[])
    for i in 1:lastindex(all_cells)
        cell = all_cells[i]
        if cell["cell_type"] == "markdown"
            push!(markdown_df, process_cell_markdown(i, cell))
        elseif cell["cell_type"] == "code"
            push!(code_df, process_cell_code(i, cell))
        end
    end
    return markdown_df, code_df
end


# Basic request - no need to pull out into a function

r = HTTP.request("GET", "https://raw.githubusercontent.com/yoninazarathy/ProgrammingCourse-with-Julia-SimulationAnalysisAndLearningSystems/main/practicals_jupyter/practical_B_julia_essentials.ipynb")
notebook_json = JSON.parse(String(r.body))


# Print the summary (with the help of an occasional inline)

println("Total number of cells: " * string(length(notebook_json["cells"])))

code_cells_count = count(cell->(cell["cell_type"] == "code"), notebook_json["cells"])
println("Number of code cells: " * string(code_cells_count))

println("Number of markdown cells: " * string(count(cell->(cell["cell_type"] == "markdown"), notebook_json["cells"])))

code_cells_nooutput_count = count(cell->(cell["cell_type"] == "code" && length(cell["outputs"]) == 0), notebook_json["cells"])
println("Number of code cells w/o output: " * string(code_cells_nooutput_count))
println("Number of code cells w/ output: " * string(code_cells_count - code_cells_nooutput_count))


"""
Quick function that takes a list of cells and iterates through their outputs, returning a somewhat comprehensive list of keys
"""
function total_keys_in_outputs(cells)
    unique_keys = Set()
    for cell in cells
        if haskey(cell, "outputs")
            for output in cell["outputs"]
                union!(unique_keys, Set(keys(output)))
                for key in keys(output)
                    if isa(output[key], Dict)
                        union!(unique_keys, Set(keys(output[key])))
                    end
                end
            end
        end
    end
    return unique_keys
end


# It always worried me whether I missed an edge case in the outputs - so, this is my chosen 'extra summary'

println("Number of unique keys present in output fields: " * string(length(total_keys_in_outputs(notebook_json["cells"]))))

# Process cells, chuck em into the csvs with proper formatting

markdown_df, code_df = process_cells_all(notebook_json["cells"])

CSV.write("markdown_summary.csv", markdown_df; header = ["cell_number", "character_count", "line_count", "#", "##", "###", "####"])

CSV.write("code_summary.csv", code_df; header = ["cell_number", "character_count", "line_count", "return", "for", "if", "using"])


# Read the files back, then print them out with decent formatting
markdown_csv, code_csv = CSV.File("markdown_summary.csv"; limit=4, header=0) |> DataFrame, CSV.File("code_summary.csv"; limit=4, header=0) |> DataFrame
println(markdown_csv)
println(code_csv)