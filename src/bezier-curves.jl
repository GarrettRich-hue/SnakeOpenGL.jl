struct CubicBezier{T<:Real}
    p0::Vector{T}
    p1::Vector{T}
    p2::Vector{T}
    p3::Vector{T}
end

BezierDir(p0, d0, p1, d1) = CubicBezier(p0, p0 .+ d0, p1 .- d1, p1)
"""
    bezierposition(bezier, t)
Calculate and return the position on the bezier curve at point t
"""
function bezierposition(bezier::CubicBezier, t::Real) 
    tm = 1-t
    return (tm^3) .* bezier.p0 .+ (3*tm^2*t) .* bezier.p1 .+ (3*tm*t^2).*bezier.p2 + (t^3) .*bezier.p3
end
"""
    splitbezier(bezier, t)
Split the bezier curve at the point parameterized by t into two and return the two resulting bezier curves
"""
function splitbezier(bezier::CubicBezier, t::Real)
    p01 = (bezier.p1 .- bezier.p0) .* t .+ bezier.p0
    p12 = (bezier.p2 .- bezier.p1) .* t .+ bezier.p1
    p23 = (bezier.p3 .- bezier.p2) .* t .+ bezier.p2

    p012 = (p12 .- p01) .* t .+ p01
    p123 = (p23 .- p12) .* t .+ p12

    p0123 = (p123.-p012) .* t .+ p012
    return (CubicBezier(bezier.p0, p01, p012, p0123), CubicBezier(p0123, p123, p23, bezier.p3))
end
