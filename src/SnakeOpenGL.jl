module SnakeOpenGL
export runsnakegame
using ModernGL, GLFW, Images, LinearAlgebra
using MeshIO, GeometryBasics
using Dates

include(joinpath(@__DIR__, "opengl-abstractions.jl"))
include(joinpath(@__DIR__, "opengl-math.jl"))
function runsnakegame()
    # snake game constants
    GAME_ROWS, GAME_COLS = 8, 8

    # open gl & related constants
    GROUND_TEXTURE_WIDTH, GROUND_TEXTURE_HEIGHT = 0.5, 0.5
    WINDOW_WIDTH, WINDOW_HEIGHT = 1200, 900
    WINDOW_TITLE = "Snake game in Open GL"
    # create window and set context
    window = createfixedsizewindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
    GLFW.MakeContextCurrent(window)
    glViewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    # create shader program for models
    prog = createshaderprogram(joinpath(@__DIR__, "shaders", "model.vert"), joinpath(@__DIR__, "shaders", "model.frag"))

    modelLoc = glGetUniformLocation(prog, "model")
    viewLoc = glGetUniformLocation(prog, "view")
    projLoc = glGetUniformLocation(prog, "proj")
    texLoc = glGetUniformLocation(prog, "tex")

    #create ground model
    #groundVertexPos = Vector{GLfloat}[[0, 0, 0], [0, 0, GAME_ROWS], [GAME_COLS, 0, 0] , [GAME_COLS, 0, GAME_ROWS]]
    #groundTextureCoors = Vector{GLfloat}[[0,0], [0,GAME_ROWS*GROUND_TEXTURE_HEIGHT],[GAME_COLS*GROUND_TEXTURE_WIDTH,0], [GAME_COLS*GROUND_TEXTURE_WIDTH, GAME_ROWS*GROUND_TEXTURE_HEIGHT]] 
    groundVertexPos = vec([GLfloat[col, 0, row] for (row, col) in Iterators.product(0:GAME_ROWS, 0:GAME_COLS)])
    groundTextureCoors = vec([GLfloat[col*GROUND_TEXTURE_WIDTH, row*GROUND_TEXTURE_HEIGHT] for (row, col) in Iterators.product(0:GAME_ROWS, 0:GAME_COLS)])

    f(row, col) = row + col*(GAME_ROWS+1)
    #groundElements = Vector{GLuint}[[0, 1, 2], [1, 3, 2]]
    groundElements = vcat(
                          Vector{GLuint}[[f(row, col), f(row +1, col), f(row, col+1)] for row in 0:(GAME_ROWS-1) for col in 0:(GAME_COLS-1)], 
                          Vector{GLuint}[[f(row+1, col), f(row +1, col+1), f(row, col+1)] for row in 0:(GAME_ROWS-1) for col in 0:(GAME_COLS-1)] )
    
    groundVAO, groundVBO = createvertexarrayobject(hcat(groundVertexPos, groundTextureCoors), prog, ["position", "texcoord"]; elements = groundElements)

    # create ground texture
    groundImg = loadimagefromfile(joinpath(@__DIR__, "assets", "ground-texture.jpg"))
    groundTex = createimagemipmap(groundImg, 0)

    # create apple model
    appleMesh = expand_faceviews(load(joinpath(@__DIR__, "assets", "apple.obj")))
    appleVertexPos = Vector{Vector{GLfloat}}(appleMesh.vertex_attributes[:position])
    appleTextureCoors = Vector{Vector{GLfloat}}(appleMesh.vertex_attributes[:uv])
    appleElements = map(x -> Vector{GLuint}(x .-1), Vector{Vector{GLuint}}(appleMesh.faces)) 
    appleVAO, appleVBO = createvertexarrayobject(hcat(appleVertexPos,appleTextureCoors), prog, ["position", "texcoord"]; elements =appleElements)

    # create apple texture
    appleImg = loadimagefromfile(joinpath(@__DIR__, "assets", "apple-diffuse.jpg"), true, true)
    appleTex = createimagemipmap(appleImg, 1)

    glEnable(GL_DEPTH_TEST)

    startTime = datetime2unix(now())
    # render loop
    while !GLFW.WindowShouldClose(window)
        if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS 
            GLFW.SetWindowShouldClose(window, true)
        end
  
        currentTime = datetime2unix(now())
        elapsedTime = currentTime-startTime
        # clear background
        glClearColor(0.1, 0.1, 0.1, 1.0)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        # set model program
        glUseProgram(prog)
        view = rotate(π/2, 1, 0, 0)*translate(-GAME_COLS/2, -(max(GAME_COLS,GAME_COLS)/2 * cot(π/8) + 1), -GAME_ROWS/2 )
        glUniformMatrix4fv(viewLoc, 1, GL_FALSE, view)

        proj = perspective(π/4, WINDOW_WIDTH/WINDOW_HEIGHT, 1, 100)
        glUniformMatrix4fv(projLoc, 1, GL_FALSE, proj)
        # draw ground
        model = Matrix{GLfloat}(I, 4, 4)
        glUniformMatrix4fv(modelLoc, 1, GL_FALSE, model)
        glUniform1i(texLoc, 0)
        glBindVertexArray(groundVAO[1])
        glDrawElements(GL_TRIANGLES, 3*length(groundElements), GL_UNSIGNED_INT, C_NULL)
        # draw apple
        model = translate(3.5, 1, 3.5)*rotate(-0.7, [1, 0, 0.])*rotate(elapsedTime, [0., 1., 0.])*scale(1/11*0.7)
        glUniformMatrix4fv(modelLoc, 1, GL_FALSE, model)
        glUniform1i(texLoc, 1)
        glBindVertexArray(appleVAO[1])
        glDrawElements(GL_TRIANGLES, 3*length(appleMesh.faces), GL_UNSIGNED_INT, C_NULL)

        GLFW.SwapBuffers(window)
        GLFW.PollEvents()
    end
end

end
