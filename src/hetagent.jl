abstract type AbstractHetAgent end

abstract type HetAgentStyle end

struct TimeDiscrete <: HetAgentStyle end

HetAgentStyle(ha::AbstractHetAgent) = HetAgentStyle(typeof(ha))
HetAgentStyle(::Type{<:AbstractHetAgent}) = TimeDiscrete()

"""
    endoprocs(ha::AbstractHetAgent)

Return an iterable object that contains all the endogenous law of motion of `ha`.
This method is required.
"""
function endoprocs end

"""
    exogprocs(ha::AbstractHetAgent)

Return an iterable object that contains all the exogenous law of motion of `ha`.
This method is required.
"""
function exogprocs end

"""
    valuevars(ha::AbstractHetAgent)

Return an iterable object that contains all the value functions
or their partial derivatives involved in the backward iteration of `ha`.
This method is required.
"""
function valuevars end

"""
    expectedvalues(ha::AbstractHetAgent)

Return an iterable object that contains all the expectation of value functions
or their partial derivatives involved in the backward iteration of `ha`.
This method is required.
"""
function expectedvalues end

"""
    policies(ha::AbstractHetAgent)

Return an iterable object that contains all the policy functions of `ha`.
The returned object must contain the policies associated with the endogenous states
and places them in the beginning in the same order as
how the states are indexed by the object returned by [`endoprocs`](@ref).
This method is required.
"""
function policies end

"""
    endopolicies(ha::AbstractHetAgent)

Return an iterable object that contains the policies corresponding to
all the endogenous law of motion of `ha`.
The order of the elements must match the objects returned by [`endoprocs`](@ref).
The fallback method assumes that the policies are placed in the beginning of
the object returned by [`policies`](@ref) in the correct order.
"""
function endopolicies(ha::AbstractHetAgent)
    endos = endoprocs(ha)
    pols = policies(ha)
    return ntuple(i->pols[i], length(endos))
end

"""
    backwardtargets(ha::AbstractHetAgent)

Return an iterable object that contains all the pairs of variables
that are used for determining the convergence of backward iteration from `ha`.
Each element of the returned object must be a `Pair` containing two objects
involved in each comparison with the first one being an object
evaluated from the current step of backward iteration
and the second one being the one evaluated from the last step.
This method is required.
"""
function backwardtargets end

"""
    getdist(ha::AbstractHetAgent)

Return the distribution of agents associated with
the current step of forward iteration from `ha`.
The fallback method assumes that `D` is a property of `ha`
and returns this property.
See also [`getlastdist`](@ref) and [`getdistendo`](@ref).
"""
getdist(ha::AbstractHetAgent) = getproperty(ha, :D)

"""
    getlastdist(ha::AbstractHetAgent)

Return the distribution of agents associated with
the previous step of forward iteration from `ha`.
The fallback method assumes that `Dlast` is a property of `ha`
and returns this property.
See also [`getdist`](@ref) and [`getdistendo`](@ref).
"""
getlastdist(ha::AbstractHetAgent) = getproperty(ha, :Dlast)

"""
    getdistendo(ha::AbstractHetAgent)

Return the distribution of agents after the transition
driven by the endogenous law of motion but before being hitted by exogenous shocks.
The fallback method assumes that `Dendo` is a property of `ha`
and returns this property.
See also [`getdist`](@ref) and [`getlastdist`](@ref).
"""
getdistendo(ha::AbstractHetAgent) = getproperty(ha, :Dendo)

"""
    backwardsolver(::AbstractHetAgent)

Return the solver used for backward iteration.
The fallback method returns `nothing`,
which indicates direct iteration using results from the last step as input.
"""
backwardsolver(::AbstractHetAgent) = nothing

"""
    backward_exog!(ha::AbstractHetAgent)

Compute the expected values given the current values and the law of motion of exogenous states.
"""
function backward_exog!(ha::AbstractHetAgent)
    exogs = exogprocs(ha)
    vs = valuevars(ha)
    evs = expectedvalues(ha)
    for i in 1:length(vs)
        backward!(evs[i], vs[i], exogs...)
    end
end

"""
    backward_endo!(ha::AbstractHetAgent, EVs..., invals...)

Update the values and policies of `ha` given the expected values `EVs`
and macro variables evaluated at `invals`.
To allow the computation of Jacobians,
reference to the arrays of expected values must be done via `EVs`
instead of any array contained in `ha`.
This method is essential for computing the sequence-space Jacobians and transitional paths.
"""
function backward_endo! end

"""
    backward!(ha::AbstractHetAgent, invals...)

Iterate the values of `ha` backward by one step with macro variables evaluated at `invals`.
A fallback method is selected based on [`HetAgentStyle`](@ref).
"""
backward!(ha::AbstractHetAgent, invals...) = backward!(HetAgentStyle(ha), ha, invals...)

function backward!(::TimeDiscrete, ha::AbstractHetAgent, invals...)
    foreach(x->copyto!(x[2], x[1]), backwardtargets(ha))
    backward_exog!(ha)
    backward_endo!(ha, expectedvalues(ha)..., invals...)
end

"""
    backward_steadystate!(ha::AbstractHetAgent, invals...)

A variant of [`backward!`](@ref) used when solving the steady state.
A fallback method is selected based on [`HetAgentStyle`](@ref)
and may simply call [`backward!`](@ref).
"""
backward_steadystate!(ha::AbstractHetAgent, invals...) =
    backward!(HetAgentStyle(ha), ha, invals...)

backward_steadystate!(hs::TimeDiscrete, ha, invals...) = backward!(hs, ha, invals...)

"""
    backward_init!(ha::AbstractHetAgent, invals...)

Initialize data objects contained in `ha` before backward iteration.
Assigning initial values only to data underlying [`valuevars`](@ref)
should be sufficient for typical problems.
The fallback method returns `nothing` without making any change.
"""
backward_init!(::AbstractHetAgent, invals...) = nothing

"""
    backward_status(ha::AbstractHetAgent)

Return an object that indicates the status of backward iteration based on values in `ha`.
This method allows tracing the steps of backward iteration for inspection.
The fallback method returns `nothing`.
"""
backward_status(::AbstractHetAgent) = nothing

"""
    backward_converged(ha::AbstractHetAgent, status, tol::Real=1e-8)

Assess whether the backward iteration has converged at tolerance level `tol`
based on values in `ha` and `status` returned by [`backward_status`](@ref).
The fallback method returns `true` if [`supconverged`](@ref) returns `true`
for all pairs of current and last policies while disregarding `status`.
"""
backward_converged(ha::AbstractHetAgent, st, tol::Real=1e-8) =
    all(x->supconverged(x[1], x[2], tol), backwardtargets(ha))

"""
    forwardsolver(::AbstractHetAgent)

Return the solver used for forward iteration.
The fallback method returns `nothing`,
which indicates direct iteration using results from the last step as input.
"""
forwardsolver(::AbstractHetAgent) = nothing

"""
    forward!(ha::AbstractHetAgent, invals...)

Iterate the distributions of `ha` forward by one step
with macro variables evaluated at `invals`.
Unless in special circumstances,
the fallback method selected based on [`HetAgentStyle`](@ref) should be sufficient
and there is no need to add methods to this function.
"""
forward!(ha::AbstractHetAgent, invals...) = forward!(HetAgentStyle(ha), ha, invals...)

function forward!(::TimeDiscrete, ha::AbstractHetAgent, invals...)
    D = getdist(ha)
    Dlast = getlastdist(ha)
    Dendo = getdistendo(ha)
    copyto!(Dlast, D)
    forward!(Dendo, Dlast, endoprocs(ha)...)
    forward!(D, Dendo, exogprocs(ha)...)
end

"""
    forward_steadystate!(ha::AbstractHetAgent, invals...)

A variant of [`forward!`](@ref) used when solving the steady state.
A fallback method is selected based on [`HetAgentStyle`](@ref)
and may simply call [`forward!`](@ref).
"""
forward_steadystate!(ha::AbstractHetAgent, invals...) =
    forward!(HetAgentStyle(ha), ha, invals...)

forward_steadystate!(hs::TimeDiscrete, ha, invals...) = forward!(hs, ha, invals...)

"""
    forward_init!(ha::AbstractHetAgent, invals...)

Initialize data objects contained in `ha` before forward iteration.
A fallback method is selected based on [`HetAgentStyle`](@ref)
and should be sufficient in most scenarios.
"""
forward_init!(ha::AbstractHetAgent, invals...) =
    forward_init!(HetAgentStyle(ha), ha, invals...)

function _initdist!(D::AbstractArray, ds::Vararg{Vector,N}) where N
    nD = ndims(D)
    p0 = 1/prod(i->size(D,i), 1:nD-N)
    dims = (nD-N+1:nD...,)
    vs = splitdimsview(D, dims)
    @inbounds for (i, p) in enumerate(Base.product(ds...))
        fill!(vs[i], *(p0, p...))
    end
end

function initdist!(ha::AbstractHetAgent)
    D = getdist(ha)
    exogs = exogprocs(ha)
    Nexog = length(exogs)
    if Nexog > 0
        ds = ntuple(i->exogs[i].d, Nexog)
        _initdist!(D, ds...)
    else
        fill!(D, 1/length(D))
    end
end

function initendo!(ha::AbstractHetAgent)
    endos = endoprocs(ha)
    endopols = endopolicies(ha)
    foreach(i->update!(endos[i], i, endopols[i]), 1:length(endos))
end

function forward_init!(::TimeDiscrete, ha::AbstractHetAgent, invals...)
    initdist!(ha)
    initendo!(ha)
end

"""
    forward_status(ha::AbstractHetAgent)

Return an object that indicates the status of forward iteration based on values in `ha`.
This method allows tracing the steps of forward iteration for inspection.
The fallback method returns `nothing`.
"""
forward_status(::AbstractHetAgent) = nothing

"""
    forward_converged(ha::AbstractHetAgent, status, tol::Real=1e-8)

Assess whether the forward iteration has converged at tolerance level `tol`
based on values in `ha` and `status` returned by [`forward_status`](@ref).
The fallback method returns `true` if [`supconverged`](@ref) returns `true`
for the current and last distributions while disregarding `status`.
"""
forward_converged(ha::AbstractHetAgent, st, tol::Real=1e-8) =
    supconverged(getdist(ha), getlastdist(ha), tol)

"""
    aggregate(ha::AbstractHetAgent, invals...)

Return aggregated outcomes from each policy
based on the current distribution of agents.
The fallback method takes the dot products disregarding `invals`.
"""
function aggregate(ha::AbstractHetAgent, invals...)
    pols = policies(ha)
    D = getdist(ha)
    N = length(D)
    s2 = stride1(D)
    function _agg(i)
        pol = pols[i]
        s1 = stride1(pol)
        return BLAS.dot(N, pol, s1, D, s2)
    end
    return ntuple(_agg, length(pols))
end

show(io::IO, ha::AbstractHetAgent) = print(io, typeof(ha))

function show(io::IO, ::MIME"text/plain", ha::AbstractHetAgent)
    join(io, size(getdist(ha)), '×')
    print(io, " ", typeof(ha))
    nendo = length(endoprocs(ha))
    print(io, " with ", nendo, " endogenous state")
    nendo > 1 && print(io, "s")
    nexog = length(exogprocs(ha))
    print(io, " and ", nexog, " exogenous state")
    nexog > 1 && print(io, "s")
end
