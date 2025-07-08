using ModernGL, Images, LinearAlgebra
function createfixedsizewindow(windowWidth::Int, windowHeight::Int, windowTitle::String)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE);
    GLFW.WindowHint(GLFW.RESIZABLE, GL_FALSE)

    window::GLFW.Window = GLFW.CreateWindow(windowWidth, windowHeight, windowTitle)
    if window == C_NULL
        @error "Failed to create GLFW window"
        GLFW.Terminate()
    end
    

    return window
end
function createshaderprogram(vertexFileName::String,fragmentFileName::String)
    vertexShaderSource = read(vertexFileName, String) 
    vertexShader = glCreateShader(GL_VERTEX_SHADER)
    glShaderSource(vertexShader, 1, [vertexShaderSource], C_NULL)
    glCompileShader(vertexShader)
    # check that fragment shader compiled correctly
    success = GLint[0]
    infoLog = ""
    glGetShaderiv(vertexShader,GL_COMPILE_STATUS, success)
    if success[1] == GL_FALSE
        glGetShaderInfoLog(vertexShader, 512, C_NULL, infoLog)
        @error "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n$infoLog"
    end

    fragmentShaderSource = read(fragmentFileName, String) 
    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
    glShaderSource(fragmentShader, 1, [fragmentShaderSource], C_NULL)
    glCompileShader(fragmentShader)
    # check that fragment shader compiled correctly
    glGetShaderiv(fragmentShader,GL_COMPILE_STATUS, success)
    if success[1] == GL_FALSE
        glGetShaderInfoLog(fragmentShader, 512, C_NULL, infoLog)
        @error "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n$infoLog"
    end

    #create program
    shaderProgram = glCreateProgram()
    # link shaders to program
    glAttachShader(shaderProgram, vertexShader)
    glAttachShader(shaderProgram, fragmentShader)
    glLinkProgram(shaderProgram)
    # check that program linked correctly
    glGetProgramiv(shaderProgram,GL_LINK_STATUS, success)
    if success[1] == GL_FALSE
        glGetProgramInfoLog(shaderProgram, 512, C_NULL, infoLog)
        @error "ERROR::PROGRAM::LINK_FAILED\n$infoLog"
    end

    # free shaders now that the program has been made correctly
    glDeleteShader(vertexShader)
    glDeleteShader(fragmentShader)

    return shaderProgram
end
function createvertexarrayobject(values::Matrix{Vector{GLfloat}}, shaderProgram::UInt32,attributeNames::Vector{String}; elements::Vector{Vector{GLuint}} = [], vertexUsagePattern::UInt32 = GL_STATIC_DRAW, elementUsagePattern::UInt32= GL_STATIC_DRAW)
    @assert size(values,2)  == length(attributeNames) 

    VAO = GLint[0]
    glGenVertexArrays(1, VAO)
    glBindVertexArray(VAO[1])

    VBO = GLint[0]
    glGenBuffers(1, VBO)
    glBindBuffer(GL_ARRAY_BUFFER, VBO[1])

    vertexData = collect(Iterators.flatten(permutedims(values)))
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData),vertexData, vertexUsagePattern)

    attributeSizes = [maximum(Iterators.map(length,col)) for col in eachcol(values)]
    createfloatvertexattributepointers(shaderProgram, collect(zip(attributeNames, attributeSizes)))

    if length(elements) != 0
        eles = collect(Iterators.flatten(elements))
        EBO = GLint[0]
        glGenBuffers(1, EBO)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO[1])
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(eles), eles, elementUsagePattern)
    end

    return VAO, VBO
end
function createfloatvertexattributepointers(shaderProgram::UInt32, attributes::Vector{Tuple{String, Int}})
    totalLength = sum(last.(attributes))
    total = 0
    for attr in attributes
        atName, atSize = attr
        location = glGetAttribLocation(shaderProgram, atName) 
        if location == -1
            @error "Could not find attribute location of \"$atName\""
        end
        glVertexAttribPointer(location, atSize, GL_FLOAT, false, totalLength * sizeof(GLfloat), Ptr{Nothing}(total*sizeof(GLfloat)))
        glEnableVertexAttribArray(location)
        total += atSize
    end
end
function loadimagefromfile(filename::String, flipHorizontal::Bool = false, flipVertical::Bool=false)
    img = permutedims(load(filename))[end:-1:1, :]
    if flipVertical
        img = img[end:-1:1, :]
    end
    if flipHorizontal
        img = img[:, end:-1:1]
    end
    # scale the image dimensions into powers of 2 if not already, this improves texture compatibility on different versions of open gl and on graphics cards
    img = imresize(img, tuple([Int(round(2^ceil(log2(i)))) for i in size(img)]...)) 
    return img
end
function createimagemipmap(image::Union{Matrix{RGB{N0f8}}, Matrix{RGBA{N0f8}}}, textureUnit::Int ; wrapS::UInt32 = GL_REPEAT, wrapT::UInt32 = GL_REPEAT, minFilter::UInt32 = GL_LINEAR_MIPMAP_LINEAR, magFilter::UInt32 = GL_LINEAR, flipHorizontal::Bool = false, flipVertical::Bool=false)
    height, width = size(image)

    tex = GLint[0]
    glGenTextures(1, tex)
    glActiveTexture(UInt32(GL_TEXTURE0 + textureUnit))
    glBindTexture(GL_TEXTURE_2D, tex[1])

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapS)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapT) 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter) 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter)
    rgb_a  = (typeof(image) == Matrix{RGB{N0f8}}) ? GL_RGB : GL_RGBA
    glTexImage2D(GL_TEXTURE_2D, 0, rgb_a, width, height, 0, rgb_a, GL_UNSIGNED_BYTE, image)
    glGenerateMipmap(GL_TEXTURE_2D) # generate mipmap for texture

    return tex
end
function loadmeshfromfile(filename::String)
    fMesh = expand_faceviews(load(filename))
    fVertexPos = Vector{Vector{GLfloat}}(fMesh.vertex_attributes[:position])
    fNormals = Vector{Vector{GLfloat}}(fMesh.vertex_attributes[:normal])
    fTextureCoors = Vector{Vector{GLfloat}}(fMesh.vertex_attributes[:uv])
    fElements = map(x -> Vector{GLuint}(x .-1), Vector{Vector{GLuint}}(fMesh.faces)) 
    return fVertexPos, fNormals, fTextureCoors, fElements

end
