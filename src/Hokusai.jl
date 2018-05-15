module Hokusai

using DataArrays, DataFrames
using Distances
using Clustering
using PyPlot, Colors
using Optim, StatsBase

type HokusaiResult
    data
    assignments
    n
    tau
    sigma
    P
end

include("pccap.jl")
include("cluster.jl")
include("plot.jl")
include("api.jl")


# TODO: move these diagnostics somewhere meaningful

metastability(result) = trace(coupling(result)) / result.n

function coupling(result)
    P = zeros(result.n, result.n)	
    by(result.data, :groupby) do subjdata	
	for row = 1:size(subjdata,1)-1
	    i = result.assignments[subjdata[row, :index]]
	    j = result.assignments[subjdata[row+1, :index]]
	    P[i,j] += 1
	end
    end
    rownormalize(P)
end


try
    readdata!()
catch
    warn("could not load data")
end

end
