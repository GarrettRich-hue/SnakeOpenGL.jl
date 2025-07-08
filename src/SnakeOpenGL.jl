module SnakeOpenGL
export runsnakegame
using ModernGL, GLFW, Images, LinearAlgebra
using MeshIO, GeometryBasics
using Dates
using DataStructures

include(joinpath(@__DIR__, "opengl-abstractions.jl"))
include(joinpath(@__DIR__, "opengl-math.jl"))
function runsnakegame()
    # snake game constants
    GAME_ROWS, GAME_COLS = 8, 8 #GAME_COLS must be large enough to allow snake to be allowed
    MOVEMENT_TIME = 0.2 # the amount of time between the square moving in seconds

    # snake game variables
    snakeQueue = CircularDeque{Int}(GAME_ROWS*GAME_COLS)#first element is tail, last element is head
    squareidtorowcol(id::Int) = ((id) % GAME_ROWS+1, 1+div(id, GAME_ROWS))
    rowcoltosquareid(rowcol::Tuple{Int, Int}) = (first(rowcol)-1) + (last(rowcol)-1)*GAME_ROWS

    snakeRowMove, snakeColMove = 0, -1

    appleRow, appleCol = rand(1:GAME_ROWS), rand(1:GAME_COLS)

    push!(snakeQueue, rowcoltosquareid((cld(GAME_ROWS, 2), cld(GAME_COLS, 2)+2)))
    push!(snakeQueue, rowcoltosquareid((cld(GAME_ROWS, 2), cld(GAME_COLS, 2)+1)))
    push!(snakeQueue, rowcoltosquareid((cld(GAME_ROWS, 2), cld(GAME_COLS, 2))))
    
    # open gl & related constants
    GROUND_TEXTURE_WIDTH, GROUND_TEXTURE_HEIGHT = 0.5, 0.5
    WINDOW_WIDTH, WINDOW_HEIGHT = 1200, 900
    WINDOW_TITLE = "Snake game in Open GL"
    CAMERA_POSITION = GLfloat[GAME_COLS/2, (max(GAME_COLS,GAME_COLS)/2 * cot(π/8) + 1), GAME_ROWS/2]
    SUN_ANGULAR_FREQUENCY = 0.1

    # load assets
    groundImg = loadimagefromfile(joinpath(@__DIR__, "assets", "ground-texture.jpg")) # ground diffuse map
    appleVertexPos, appleNormals, appleTextureCoors, appleElements = loadmeshfromfile(joinpath(@__DIR__, "assets", "apple.obj")) # apple mesh
    appleImg = loadimagefromfile(joinpath(@__DIR__, "assets", "apple-diffuse.jpg"),true, true) # apple diffuse map
    snakeImg = loadimagefromfile(joinpath(@__DIR__, "assets/snake-diffuse.jpg"), true, true) # snake diffuse map
    snakeVertexPos, snakeNormals, snakeTextureCoors, snakeElements = loadmeshfromfile(joinpath(@__DIR__, "assets", "snake-tube.obj")) # snake mesh

    # create ground model
    groundVertexPos = vec([GLfloat[col, 0, row] for (row, col) in Iterators.product(0:GAME_ROWS, 0:GAME_COLS)])
    groundNormals = [GLfloat[0, 1, 0] for i =1:length(groundVertexPos)]
    groundTextureCoors = vec([GLfloat[col*GROUND_TEXTURE_WIDTH, row*GROUND_TEXTURE_HEIGHT] for (row, col) in Iterators.product(0:GAME_ROWS, 0:GAME_COLS)])
    f(row, col) = row + col*(GAME_ROWS+1)
    groundElements = vcat(
                          Vector{GLuint}[[f(row, col), f(row +1, col), f(row, col+1)] for row in 0:(GAME_ROWS-1) for col in 0:(GAME_COLS-1)], 
                          Vector{GLuint}[[f(row+1, col), f(row +1, col+1), f(row, col+1)] for row in 0:(GAME_ROWS-1) for col in 0:(GAME_COLS-1)] )
 
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
    cameraPositionLoc = glGetUniformLocation(prog, "cameraPosition")
    lightDirectionLoc = glGetUniformLocation(prog, "lightDirection")
    diffuseLightLoc = glGetUniformLocation(prog, "diffuseLight")
    ambientLightLoc = glGetUniformLocation(prog, "ambientLight")
    specularLightLoc = glGetUniformLocation(prog, "specularLight")

    # create shader program for models stretched by a bezier curve
    progBezier = createshaderprogram(joinpath(@__DIR__, "shaders/bezier.vert"), joinpath(@__DIR__, "shaders/model.frag"))
    p0Loc = glGetUniformLocation(progBezier, "p0")
    p1Loc = glGetUniformLocation(progBezier, "p1")
    d0Loc = glGetUniformLocation(progBezier, "d0")
    d1Loc = glGetUniformLocation(progBezier, "d1")
    s0Loc = glGetUniformLocation(progBezier, "s0")
    s1Loc = glGetUniformLocation(progBezier, "s1")
    modelLocBez = glGetUniformLocation(progBezier, "model")
    viewLocBez = glGetUniformLocation(progBezier, "view")
    projLocBez = glGetUniformLocation(progBezier, "proj")
    texLocBez = glGetUniformLocation(progBezier, "tex")
    cameraPositionLocBez = glGetUniformLocation(progBezier, "cameraPosition")
    lightDirectionLocBez = glGetUniformLocation(progBezier, "lightDirection")
    diffuseLightLocBez = glGetUniformLocation(progBezier, "diffuseLight")
    ambientLightLocBez = glGetUniformLocation(progBezier, "ambientLight")
    specularLightLocBez = glGetUniformLocation(progBezier, "specularLight")

    groundVAO, groundVBO = createvertexarrayobject(hcat(groundVertexPos, groundNormals, groundTextureCoors), prog, ["position", "normal", "texcoord"]; elements = groundElements)

    # create ground texture
    groundTex = createimagemipmap(groundImg, 0)

    # create apple model
    appleVAO, appleVBO = createvertexarrayobject(hcat(appleVertexPos, appleNormals,appleTextureCoors), prog, ["position", "normal", "texcoord"]; elements =appleElements)

    # create apple texture
    appleTex = createimagemipmap(appleImg, 1)

    # create snake model
    snakeVAO, snakeVBO = createvertexarrayobject(hcat(snakeVertexPos, snakeNormals, snakeTextureCoors), progBezier, ["position", "normal", "texcoord"]; elements = snakeElements)
    # create snake texture
    snakeTex = createimagemipmap(snakeImg, 2)

    glEnable(GL_DEPTH_TEST)

    startTime = datetime2unix(now())
    prevElapsedTime = 0
    # render loop
    while !GLFW.WindowShouldClose(window)
        # handle user input
        if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS 
            GLFW.SetWindowShouldClose(window, true)
        end
        snakeDirRow, snakeDirCol = squareidtorowcol(snakeQueue[length(snakeQueue)]) .- squareidtorowcol(snakeQueue[length(snakeQueue)-1])
        if GLFW.GetKey(window, GLFW.KEY_UP) == GLFW.PRESS
            if snakeDirRow != 1
                snakeRowMove, snakeColMove = -1, 0
            end
        elseif GLFW.GetKey(window, GLFW.KEY_RIGHT) == GLFW.PRESS
            if snakeDirCol != -1
                snakeRowMove, snakeColMove = 0, 1
            end
        elseif GLFW.GetKey(window, GLFW.KEY_DOWN) == GLFW.PRESS
            if snakeDirRow != -1
                snakeRowMove, snakeColMove = 1, 0
            end
        elseif GLFW.GetKey(window, GLFW.KEY_LEFT) == GLFW.PRESS
            if snakeDirCol != 1
                snakeRowMove, snakeColMove = 0, -1
            end
        end
        currentTime = datetime2unix(now()) - startTime
        elapsedTime = currentTime
        # game logic
        if ceil(prevElapsedTime/MOVEMENT_TIME) < elapsedTime/MOVEMENT_TIME
            # make movement 
            headRow, headCol = squareidtorowcol(last(snakeQueue))
            newHeadRow, newHeadCol = headRow+snakeRowMove, headCol+snakeColMove
            push!(snakeQueue, rowcoltosquareid((newHeadRow, newHeadCol)))
            if (newHeadRow, newHeadCol) == (appleRow, appleCol)
                appleRow, appleCol = rand(1:GAME_ROWS), rand(1:GAME_COLS)
            else
                popfirst!(snakeQueue)
            end
            
        end

        prevElapsedTime = elapsedTime 
        #calculate lighting based on day
        lightDirection = -normalize([-cos(SUN_ANGULAR_FREQUENCY * elapsedTime), 2*sin(SUN_ANGULAR_FREQUENCY *elapsedTime), -sin(SUN_ANGULAR_FREQUENCY *elapsedTime)])
        diffuseLight = Vector{GLfloat}((lightDirection[2] < 0) ? [0.8, 0.8, 0.8, 1.0] : [0.1, 0.1, 0.2, 1.0])
        ambientLight =  Vector{GLfloat}((lightDirection[2] < 0) ? [0.3, 0.3, 0.3, 1.0] : [0.2, 0.2, 0.3, 1.0])
        specularLight = Vector{GLfloat}((lightDirection[2] < 0) ? [0.8, 0.8, 0.8, 1.0] : [0.2, 0.2, 0.2, 1.0])
        lightDirection = (lightDirection[2] <0) ? lightDirection : -lightDirection
        # clear background
        glClearColor(0.1, 0.1, 0.1, 1.0)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        # set model program
        glUseProgram(prog)
        view = rotate(π/2, 1, 0, 0)*translate(-CAMERA_POSITION)
        glUniformMatrix4fv(viewLoc, 1, GL_FALSE, view)

        proj = perspective(π/4, WINDOW_WIDTH/WINDOW_HEIGHT, 1, 100)
        glUniformMatrix4fv(projLoc, 1, GL_FALSE, proj)
        glUniform3f(cameraPositionLoc, CAMERA_POSITION...)
        glUniform3f(lightDirectionLoc, lightDirection...)
        glUniform4f(diffuseLightLoc, diffuseLight...)
        glUniform4f(ambientLightLoc,ambientLight...)
        glUniform4f(specularLightLoc, specularLight...)
        # draw ground
        model = Matrix{GLfloat}(I, 4, 4)
        glUniformMatrix4fv(modelLoc, 1, GL_FALSE, model)
        glUniform1i(texLoc, 0)
        glBindVertexArray(groundVAO[1])
        glDrawElements(GL_TRIANGLES, 3*length(groundElements), GL_UNSIGNED_INT, C_NULL)
        # draw apple
        model = translate(-0.5+appleCol, 0.5, -0.5+appleRow)*rotate(-0.7, [1, 0, 0.])*rotate(elapsedTime, [0., 1., 0.])*scale(1/11*0.7)
        glUniformMatrix4fv(modelLoc, 1, GL_FALSE, model)
        glUniform1i(texLoc, 1)
        glBindVertexArray(appleVAO[1])
        glDrawElements(GL_TRIANGLES, 3*length(appleElements), GL_UNSIGNED_INT, C_NULL)
        # draw snake
        glUseProgram(progBezier)
        glBindVertexArray(snakeVAO[1])
        model = translate(0.0, 0.0, 0.0)
        glUniformMatrix4fv(modelLocBez, 1, GL_FALSE, model)
        glUniformMatrix4fv(viewLocBez, 1, GL_FALSE, view)
        glUniformMatrix4fv(projLocBez, 1, GL_FALSE, proj)
        glUniform1i(texLocBez, 2)
        glUniform3f(cameraPositionLocBez, CAMERA_POSITION...)
        glUniform3f(lightDirectionLocBez, lightDirection...)
        glUniform4f(diffuseLightLocBez, diffuseLight...)
        glUniform4f(ambientLightLocBez, ambientLight...)
        glUniform4f(specularLightLocBez, specularLight...)
        for (ind, snakePart) in enumerate(snakeQueue)
            pos = row, col = squareidtorowcol(snakePart)
            nextpos = nextrow, nextcol = (ind != length(snakeQueue)) ? squareidtorowcol(snakeQueue[ind+1]) : (-1, -1)
            prepos=prerow,precol = (ind != 1) ? squareidtorowcol(snakeQueue[ind-1]) : (row + row-nextrow, col + col-nextcol)
            if ind == length(snakeQueue)
                nexpos = nextrow, nextcol = (row + row-prerow, col + col-precol)
            end
            glUniform3f(p0Loc, GLfloat[col+(precol-col)/2-0.5, 0.5, row+(prerow-row)/2-0.5]...)
            glUniform3f(p1Loc, GLfloat[col+(nextcol-col)/2-0.5, 0.5, row+(nextrow-row)/2-0.5]...)
            glUniform3f(d0Loc, GLfloat[-(precol-col)/2, 0.0, -(prerow-row)/2]...)
            glUniform3f(d1Loc, GLfloat[(nextcol-col)/2, 0.0, (nextrow-row)/2]...)
            glUniform1f(s0Loc, GLfloat(0.5))
            glUniform1f(s1Loc, GLfloat(0.5))
            glDrawElements(GL_TRIANGLES, 3*length(snakeElements), GL_UNSIGNED_INT, C_NULL)
        end

        GLFW.SwapBuffers(window)
        GLFW.PollEvents()
    end
end

end
