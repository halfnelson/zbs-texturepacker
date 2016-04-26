--atlas loader

local function readLine(f)
  return f:read("*line")
end

local function readTuple(line)
  local vals = {}
  if line == nil then return false end
  
  local key = line:match("(%w+)%:")
  if not key then return false end
  for k,_ in line:gmatch("[%:%,]+%s*([%-%w]+)") do
    table.insert(vals, k)
  end
  return key, vals
end

local function getAtlasMapping() 

  local function b(str) 
    return function(obj, val)
      obj[str] = val == "true"
    end
  end

  local function s(str)
    return function(obj, val)
      obj[str] = tostring(val)
    end
  end

  local function n(str)
    return function(obj, val)
      obj[str] = tonumber(val)
    end
  end

  local atlasMapping = {
    ["size"] = { n("width"), n("height") },
    ["format"] = { s("format") },
    ["filter"] = { s("minFilter"), s("magFilter") },
    ["repeat"] = { function(obj, val)
          if (val == "x") then
            obj.repeatX = true
          end
          if (val == "y") then
            obj.repeatY = true
          end
          if (val == "xy") then
            obj.repeatX = true
            obj.repeatY = true
          end
        end},
    ["rotate"] = { b("rotate") },
    ["xy"] = { n("x"),n("y") },
    ["size"] = { n("width"), n("height") },
    ["orig"] = { n("originalWidth"), n("originalHeight") },
    ["split"] = { n("startX"), n("endX"), n("startY"), n("endY") },
    ["pad"] = { n("padLeft"), n("padRight"), n("padTop"), n("padBottom") },
    ["offset"] = { n("offsetX"), n("offsetY") },
    ["index"] = { n("index") }
  }
  
  return atlasMapping
end

local atlasMapping = getAtlasMapping()


local function processKV(obj, line)
  local key, vals = readTuple(line)
  if not key then return false end
  --we have (a) key value pair(s)
  local transform = atlasMapping[key]
  if transform then 
    for i,t in ipairs(transform) do
      t(obj,vals[i])
    end
  end
  return true
end


local function readAtlas(path)
  local atlas = {
    pages = {}
  }
  local f = io.open(path,"r")
  local line = readLine(f) --first line is always blank
  while true do
    --read pages
    local page = {}
    page.fileName = readLine(f)
    if not page.fileName then break end
    while true do
      --read key values for page
      line = readLine(f)
      if not processKV(page, line) then break end
    end
    --read regions
    page.regions = {}
    while true do
      local region = {}
      region.name = line
      while true do
        --read region key values
        line=readLine(f)
        if not processKV(region,line) then break end
      end
      table.insert(page.regions, region)
      --line = readLine(f)
      if line == nil or line == "" then break end --finished page
    end
    table.insert(atlas.pages, page)
  end
  f:close() 
  return atlas
end

return { readAtlas = readAtlas }

