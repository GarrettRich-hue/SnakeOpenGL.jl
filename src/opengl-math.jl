using ModernGL
using LinearAlgebra
"""
    perspective(fovy, aspect, zNear, zFar)
Return a perspective project matrix

# Arguments
- `fovy::Float32`: the field of view angle, in radians, in the y direction
- `aspect::Float32`: the aspect ratio that determines the field of view in the x direction. The aspect ratio is the ratio of width to height.
- `zNear::Float32`: the distance from the viewer to the near clipping plane (always positive)
- `zFar::Float32`: the distance from the viewer to the far clipping plane (always positive)
"""
function perspective(fovy::GLfloat, aspect::GLfloat, zNear::GLfloat, zFar::GLfloat)::Matrix{GLfloat}
    f = cot(fovy/2)
    return [f/aspect 0 0 0; 0 f 0 0; 0 0 (zFar+zNear)/(zNear-zFar) 2*zFar*zNear/(zNear-zFar); 0 0 -1 0]
end
function perspective(fovy::Real, aspect::Real, zNear::Real, zFar::Real)::Matrix{GLfloat}
    return perspective(GLfloat(fovy), GLfloat(aspect), GLfloat(zNear), GLfloat(zFar))
end
"""
    translate(x, y, z)
Return a translation matrix that translates by the vector ``\\pmatrix{x// y// z}``
"""
function translate(x::GLfloat, y::GLfloat, z::GLfloat)
    return GLfloat[1 0 0 x; 0 1 0 y; 0 0 1 z; 0 0 0 1]
end
function translate(x::Real, y::Real, z::Real)
    return translate(GLfloat(x), GLfloat(y), GLfloat(z))
end
"""
    translate(translationVector)
Return a translation matrix that translates by the given translationVector
"""
function translate(translationVector::Vector{<:Real})
    return translate(translationVector[1], translationVector[2], translationVector[3])
end
"""
    rotate(angle, x, y, z)
Return a rotation matrix that rotates about the given axis (specified by x,y,z) at the given angle.
"""
function rotate(angle::GLfloat, X::GLfloat, Y::GLfloat, Z::GLfloat)
    mag = norm((X,Y,Z))
    x,y,z = X/mag, Y/mag, Z/mag
    s, c = sincos(angle)
    mc = 1-c
    return [x^2*mc+c x*y*mc-z*s x*z*mc+y*s 0; 
            y*x*mc+z*s y^2*mc+c y*z*mc-x*s 0;
            x*z*mc-y*s y*z*mc+x*s z^2*mc+c 0;
            0 0 0 1]
end
function rotate(angle::Real, X::Real, Y::Real, Z::Real)
    return rotate(GLfloat(angle), GLfloat(X), GLfloat(Y), GLfloat(Z))
end
"""
    rotate(angle, axis)
Return a rotation matrix that rotates about the given axis at the given angle.
"""
function rotate(angle::GLfloat, axis::Vector{GLfloat})
    return rotate(angle, axis[1], axis[2], axis[3])
end
function rotate(angle::Real, axis::Vector{<:Real})
    return rotate(GLfloat(angle), GLfloat.(axis))
end
"""
    scale(x, y, z)
Return a scaling matrix that scales the x-axis, y-axis and z-axis by x, y and z respectively.
"""
function scale(x::GLfloat, y::GLfloat, z::GLfloat)::Matrix{GLfloat}
    return GLfloat[x 0 0 0; 0 y 0 0; 0 0 z 0; 0 0 0 1]
end
function scale(x::Real, y::Real, z::Real)
    return scale(GLfloat(x), GLfloat(y), GLfloat(z))
end
"""
    scale(codedVector)
Return a scaling matrix that scales each axis by the corresponding component of the codedVector.
"""
function scale(codedVector::Vector{<: Real})
    return scale(codedVector[1], codedVector[2], codedVector[3])
end
"""
    scale(scaleFactor)
Return a scaling matrix that scales uniformly by the scaleFactor
"""
function scale(scaleFactor::Real)
    return scale(scaleFactor, scaleFactor, scaleFactor)
end
