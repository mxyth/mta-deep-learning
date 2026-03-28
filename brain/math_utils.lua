-- ------------------------------------------------
-- matrix math for the neural net
-- ------------------------------------------------

Matrix = {}

function Matrix.create(rows, cols, fill)
    local m = {}
    fill = fill or 0
    for r = 1, rows do
        m[r] = {}
        for c = 1, cols do
            m[r][c] = fill
        end
    end
    return m
end

function Matrix.random(rows, cols, min, max)
    min = min or -1
    max = max or 1
    local m = Matrix.create(rows, cols)
    for r = 1, rows do
        for c = 1, cols do
            m[r][c] = math.random() * (max - min) + min
        end
    end
    return m
end

-- xavier init - scales weights so activations dont explode or vanish
function Matrix.xavier(rows, cols)
    local limit = math.sqrt(6 / (cols + rows))
    return Matrix.random(rows, cols, -limit, limit)
end

function Matrix.multiply(a, b)
    local aRows = #a
    local aCols = #a[1]
    local bCols = #b[1]
    local result = Matrix.create(aRows, bCols)
    for r = 1, aRows do
        for c = 1, bCols do
            local sum = 0
            for k = 1, aCols do
                sum = sum + a[r][k] * b[k][c]
            end
            result[r][c] = sum
        end
    end
    return result
end

function Matrix.add(a, b)
    local rows = #a
    local cols = #a[1]
    local result = Matrix.create(rows, cols)
    for r = 1, rows do
        for c = 1, cols do
            result[r][c] = a[r][c] + b[r][c]
        end
    end
    return result
end

function Matrix.map(m, fn)
    local rows = #m
    local cols = #m[1]
    local result = Matrix.create(rows, cols)
    for r = 1, rows do
        for c = 1, cols do
            result[r][c] = fn(m[r][c])
        end
    end
    return result
end

function Matrix.fromFlat(t)
    local m = {}
    for i = 1, #t do m[i] = { t[i] } end
    return m
end

function Matrix.toFlat(m)
    local t = {}
    for i = 1, #m do t[i] = m[i][1] end
    return t
end

function Matrix.copy(m)
    local rows = #m
    local cols = #m[1]
    local result = Matrix.create(rows, cols)
    for r = 1, rows do
        for c = 1, cols do
            result[r][c] = m[r][c]
        end
    end
    return result
end

function tanh(x)
    return math.tanh(x)
end
