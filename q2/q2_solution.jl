using HTTP, JSON, DataFrames, CSV

r = HTTP.request("GET", "https://raw.githubusercontent.com/yoninazarathy/ProgrammingCourse-with-Julia-SimulationAnalysisAndLearningSystems/main/practicals_jupyter/practical_B_julia_essentials.ipynb")
test_json = JSON.parse(String(r.body))

println(r.status)

#println(test_json)

println(length(test_json["cells"]))
code_cells_count = count(cell->(cell["cell_type"] == "code"), test_json["cells"])
println(code_cells_count)
println(count(cell->(cell["cell_type"] == "markdown"), test_json["cells"]))
code_cells_nooutput_count = count(cell->(cell["cell_type"] == "code" && length(cell["outputs"]) == 0), test_json["cells"])
println(code_cells_nooutput_count)
println(code_cells_count - code_cells_nooutput_count)
println(String(test_json["cells"][1]["source"][1]))

struct SharedCellCounts
    character_count::Int
    line_count::Int
end

struct MarkDownCellCounts
    one_hash_count::Int
    two_hash_count::Int
    three_hash_count::Int
    four_hash_count::Int
end

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

function process_cells_markdown(markdown_cells)
    df = DataFrame(character_count = Int[], line_count = Int[], one_hash = Int[], two_hash = Int[], three_hash = Int[], four_hash = Int[])
    for cell in markdown_cells
        push!(df, [get_cell_counts_shared(cell)..., get_cell_counts_markdown(cell)...])
    end
    return df
end

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

function process_cells_code(code_cells)
    df = DataFrame(character_count = Int[], line_count = Int[], returns = Int[], fors = Int[], ifs = Int[], usings = Int[])
    for cell in code_cells
        push!(df, [get_cell_counts_shared(cell)..., get_cell_counts_code(cell)...])
    end
    return df
end

markdown_df, code_df = process_cells_all(test_json["cells"])

CSV.write("testfile.csv", markdown_df; header = ["cell_number", "character_count", "line_count", "#", "##", "###", "####"])

CSV.write("testfile2.csv", code_df; header = ["cell_number", "character_count", "line_count", "return", "for", "if", "using"])

"""
source = test_json["cells"][20]

@show get_cell_counts_shared(source)
@show get_cell_counts_markdown(source)
@show get_cell_counts_markdown(source)
@show get_cell_counts_code(test_json["cells"][8])

df = DataFrame(A = Int[], B = Int[], C = Int[], D = Int[])

push!(df, get_cell_counts_markdown(source))
push!(df, get_cell_counts_code(test_json["cells"][8]))

println(df)

@show markdown_processed = process_cells_markdown(filter(cell -> (cell["cell_type"] == "markdown"), test_json["cells"]))

DataFrames.insertcols!(markdown_processed, 1, :cell_number => 1:nrow(markdown_processed))

CSV.write("testfile.csv", markdown_processed; header = ["cell_number", "character_count", "line_count", "#", "##", "###", "####"])
"""