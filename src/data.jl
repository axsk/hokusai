# initialize data
using DataFrames, CSV, PyPlot

datapath = joinpath(@__DIR__, "..", "data")

global DATA
try
    DATA = CSV.read(joinpath(datapath, "sallsac_Hokusai.seq"), delim = '\t')
catch
    warn("could not load data")
end

# TODO: add filters for mirrored, starting location, ..
function filterdata(data::DataFrame, image)
    # select the corresponding image
    data = data[data[:image] .== "$image.jpg", :]

    # consider only one starting position
    const left = 52
    const right = 69
    #data = data[data[:fixcrosspos] .== left]

    # "disable" grouping by subjects
    #data[:subj] = 0

    # scale/filter coordinates to 0->width, 0->height
    width, height = data[1,:width], data[1,:height]
    dx, dy = (1280-width)/2, (1024-height)/2
    data[:fposx] = data[:fposx] - dx
    data[:fposy] = data[:fposy] - dy
    data = data[((data[:fposx] .> 0) .& (data[:fposy] .> 0) .& (data[:fposx] .< width) .& (data[:fposy] .< height)) , :]

    # mirror x coordinates of mirrored version to make it comparable
    if ismatch(r"mirrored", string(image))
        data[:fposx] = width - data[:fposx]
    end

    return data
end

function TimeSeries(data::DataFrame)
    ts = TimeSeries[]
    by(data, :subj) do d
        times = Array(cumsum(d[:fixdur])) ::Vector
        points = Array(hcat(d[:fposx], d[:fposy])) ::Matrix{Float64}
        push!(ts, TimeSeries(times, points))
        nothing # return value for by construct / hotfix
    end
    ts
end

## convenience wrapper for plotting
function run(ts::Union{TimeSeries, Vector{TimeSeries}}, n, sigma, tau; kwargs...)
    ass = cluster(ts, n, sigma, tau; kwargs...)
    figure()
    plot(ts, ass)
end

run(d::DataFrame, n, sigma, tau; kwargs...) = run(TimeSeries(d), n, sigma, tau; kwargs...)

function run(img::Integer, n, sigma, tau; kwargs...)
    run(filterdata(DATA, img), n, sigma, tau; kwargs...)
    plotimg(img)
end

## plot functions
function plot(ts::Union{TimeSeries, Vector{TimeSeries}}, ass)
    ps = points(ts)
    PyPlot.scatter(ps[:,1], ps[:,2], c=ass)
    gcf()
end

plotimg(img::Integer) = plotimg(joinpath(datapath,"$img.jpg"))

function plotimg(path::String)
    PyPlot.imread(path) |> PyPlot.imshow
    PyPlot.gcf()
end