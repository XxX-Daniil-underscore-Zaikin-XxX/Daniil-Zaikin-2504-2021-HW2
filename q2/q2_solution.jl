using HTTP, JSON, DataFrames, CSV


# """
# println(r.status)

# #println(test_json)

# println(length(test_json["cells"]))
# code_cells_count = count(cell->(cell["cell_type"] == "code"), test_json["cells"])
# println(code_cells_count)
# println(count(cell->(cell["cell_type"] == "markdown"), test_json["cells"]))
# code_cells_nooutput_count = count(cell->(cell["cell_type"] == "code" && length(cell["outputs"]) == 0), test_json["cells"])
# println(code_cells_nooutput_count)
# println(code_cells_count - code_cells_nooutput_count)
# println(String(test_json["cells"][1]["source"][1]))
# """
# """
# struct SharedCellCounts
#     character_count::Int
#     line_count::Int
# end

# struct MarkDownCellCounts
#     one_hash_count::Int
#     two_hash_count::Int
#     three_hash_count::Int
#     four_hash_count::Int
# end
# """
function get_cell_counts_shared(cell)
    char_total, lines_total = 0, 0
    for line in cell["source"]
        char_total += length(String(line))
    end
    if haskey(cell, "outputs")
        char_outputs, lines_outputs = get_counts_outputs(cell["outputs"])
        char_total += char_outputs
        lines_total += lines_outputs
    end
    lines_total += length(cell["source"])
    return char_total, lines_total
end

function get_counts_outputs(outputs)
    char_total = 0
    line_total = 0
    for output in outputs
        if haskey(output, "name")
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

function get_cell_counts_markdown(cell)
    count = zeros(Int32, 4)
    for line in cell["source"]
        for i in eachindex(count)
            count[i] += length(collect(m.match for m in eachmatch(Regex("^#{$i}[^#]|[^#]#{$i}[^#]|[^#]#{$i}^"), String(line))))
        end
    end
    return count
end

function get_cell_counts_code(cell)
    matches = ["return", "for", "if", "using"]
    count = zeros(Int32, 4)
    for line in cell["source"]
        for i in eachindex(matches)
            count[i] += length(collect(m.match for m in eachmatch(Regex(matches[i]), String(line))))
        end
    end
    return count
end

# """
# function process_cells_markdown(markdown_cells)
#     df = DataFrame(character_count = Int[], line_count = Int[], one_hash = Int[], two_hash = Int[], three_hash = Int[], four_hash = Int[])
#     for cell in markdown_cells
#         push!(df, [get_cell_counts_shared(cell)..., get_cell_counts_markdown(cell)...])
#     end
#     return df
# end
# """

function process_cell_markdown(cell_number, markdown_cell)
    return [cell_number, get_cell_counts_shared(markdown_cell)..., get_cell_counts_markdown(markdown_cell)...]
end

function process_cell_code(cell_number, code_cell)
    return [cell_number, get_cell_counts_shared(code_cell)..., get_cell_counts_code(code_cell)...]
end

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
# """
# function process_cells_code(code_cells)
#     df = DataFrame(character_count = Int[], line_count = Int[], returns = Int[], fors = Int[], ifs = Int[], usings = Int[])
#     for cell in code_cells
#         push!(df, [get_cell_counts_shared(cell)..., get_cell_counts_code(cell)...])
#     end
#     return df
# end
# """
r = HTTP.request("GET", "https://raw.githubusercontent.com/yoninazarathy/ProgrammingCourse-with-Julia-SimulationAnalysisAndLearningSystems/main/practicals_jupyter/practical_B_julia_essentials.ipynb")

test_json = JSON.parse(String(r.body))
# total_number
# code_number
# markdown_number
# code_nooutput_number
# code_output_number
# output_keys_number 


println("Total number of cells: " * string(length(test_json["cells"])))
code_cells_count = count(cell->(cell["cell_type"] == "code"), test_json["cells"])
println("Number of code cells: " * string(code_cells_count))
println("Number of markdown cells: " * string(count(cell->(cell["cell_type"] == "markdown"), test_json["cells"])))
code_cells_nooutput_count = count(cell->(cell["cell_type"] == "code" && length(cell["outputs"]) == 0), test_json["cells"])
println("Number of code cells w/o output: " * string(code_cells_nooutput_count))
println("Number of code cells with output: " * string(code_cells_count - code_cells_nooutput_count))

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


# It always worried me whether I missed an edge case in the outputs
println("Number of unique keys present in output fields: " * string(length(total_keys_in_outputs(test_json["cells"]))))

markdown_df, code_df = process_cells_all(test_json["cells"])

CSV.write("markdown_summary.csv", markdown_df; header = ["cell_number", "character_count", "line_count", "#", "##", "###", "####"])

CSV.write("code_summary.csv", code_df; header = ["cell_number", "character_count", "line_count", "return", "for", "if", "using"])
