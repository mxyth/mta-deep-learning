-- ------------------------------------------------
-- genetic algorithm / neuroevolution
-- tournament selection, uniform crossover, adaptive mutation
-- when fitness gets stuck, boosts the mutation to shake things up
-- ------------------------------------------------

Genetic = {}

local MUTATION_RATE  = 0.2
local MUTATION_POWER = 0.5
local ELITISM        = 3
local IMMIGRANTS     = 5
local TOURNEY_SIZE   = 3

function Genetic.rankByFitness(population)
    table.sort(population, function(a, b) return a.fitness > b.fitness end)
end

function Genetic.selectParent(population)
    local best = nil
    for i = 1, TOURNEY_SIZE do
        local c = population[math.random(1, #population)]
        if not best or c.fitness > best.fitness then best = c end
    end
    return best
end

function Genetic.crossover(genomeA, genomeB)
    local child = {}
    for i = 1, #genomeA do
        child[i] = math.random() < 0.5 and genomeA[i] or genomeB[i]
    end
    return child
end

function Genetic.mutate(genome, mutBoost)
    mutBoost = mutBoost or 1.0
    local rate = math.min(MUTATION_RATE * mutBoost, 0.8)
    local power = MUTATION_POWER * mutBoost
    for i = 1, #genome do
        if math.random() < rate then
            if math.random() < 0.1 then
                genome[i] = math.random() * 2 - 1
            else
                genome[i] = genome[i] + (math.random() * 2 - 1) * power
            end
        end
    end
    return genome
end

function Genetic.evolve(population, topology, mutBoost)
    mutBoost = mutBoost or 1.0
    Genetic.rankByFitness(population)

    local nextGen = {}
    local popSize = #population
    local idx = 1

    for i = 1, math.min(ELITISM, popSize) do
        nextGen[idx] = population[i].net:copy()
        idx = idx + 1
    end

    local immCount = math.min(math.floor(IMMIGRANTS * mutBoost), popSize - idx + 1)
    for i = 1, immCount do
        nextGen[idx] = NeuralNet.new(topology)
        idx = idx + 1
    end

    while idx <= popSize do
        local a = Genetic.selectParent(population)
        local b = Genetic.selectParent(population)
        local child = Genetic.crossover(a.net:getGenome(), b.net:getGenome())
        Genetic.mutate(child, mutBoost)
        local net = NeuralNet.new(topology)
        net:setGenome(child)
        nextGen[idx] = net
        idx = idx + 1
    end

    return nextGen
end
