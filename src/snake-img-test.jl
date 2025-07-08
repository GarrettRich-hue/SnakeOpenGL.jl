using Plots
using FileIO
function main()
    img = load(joinpath(@__DIR__, "src/assets/snake-diffuse.jpg"))
    println(typeof(img))
    plot(img)
end
main()
