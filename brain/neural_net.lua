-- ------------------------------------------------
-- feed-forward neural network
-- xavier init so random networks dont saturate into uselessness
-- output bias makes them drive forward by default so gen 1 isnt completely dead
-- ------------------------------------------------

NeuralNet = {}
NeuralNet.__index = NeuralNet

function NeuralNet.new(topology)
    local self = setmetatable({}, NeuralNet)
    self.topology = topology
    self.weights = {}
    self.biases = {}

    for i = 1, #topology - 1 do
        self.weights[i] = Matrix.xavier(topology[i + 1], topology[i])
        self.biases[i] = Matrix.create(topology[i + 1], 1, 0)
    end

    -- random steering tendency so gen 1 isnt 60 clones going straight into a wall
    -- some will pull left, some right, some wobble. evolution sorts out who lives.
    local outBias = self.biases[#self.biases]
    outBias[1][1] = math.random() * 1.6 - 0.8
    outBias[2][1] = 0.6 + math.random() * 0.4  -- 0.6 to 1.0, always forward but varied speed

    return self
end

function NeuralNet:forward(inputs)
    local current = Matrix.fromFlat(inputs)
    for i = 1, #self.weights do
        current = Matrix.multiply(self.weights[i], current)
        current = Matrix.add(current, self.biases[i])
        current = Matrix.map(current, tanh)
    end
    return Matrix.toFlat(current)
end

function NeuralNet:getGenome()
    local genome = {}
    for i = 1, #self.weights do
        for r = 1, #self.weights[i] do
            for c = 1, #self.weights[i][r] do
                genome[#genome + 1] = self.weights[i][r][c]
            end
        end
        for r = 1, #self.biases[i] do
            genome[#genome + 1] = self.biases[i][r][1]
        end
    end
    return genome
end

function NeuralNet:setGenome(genome)
    local idx = 1
    for i = 1, #self.weights do
        for r = 1, #self.weights[i] do
            for c = 1, #self.weights[i][r] do
                self.weights[i][r][c] = genome[idx]
                idx = idx + 1
            end
        end
        for r = 1, #self.biases[i] do
            self.biases[i][r][1] = genome[idx]
            idx = idx + 1
        end
    end
end

function NeuralNet:copy()
    local net = NeuralNet.new(self.topology)
    for i = 1, #self.weights do
        net.weights[i] = Matrix.copy(self.weights[i])
        net.biases[i] = Matrix.copy(self.biases[i])
    end
    return net
end
