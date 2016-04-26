local reader = require('atlasreader')

local Atlas = {}
local Atlas_mt = { __index = Atlas }


function Atlas:createPage(page, pagenumber)
    local regions = page.regions
    
    --sort regions heere to keep them in correct order in deck so we can animate cleanly.
    table.sort(regions, 
      function(a,b) 
        if a.name < b.name then return true end
        if a.name > b.name then return false end
        --if same sort by index
        return a.index < b.index
      end)
      
    
    --first load texture
    local texture = self.texturefunc(page.fileName)
    assert(texture, "texture load failed")
    local boundsDeck = MOAIBoundsDeck.new()
    boundsDeck:reserveBounds(#regions)
    boundsDeck:reserveIndices(#regions)

    local deck = MOAIGfxQuadDeck2D.new()
    deck:setBoundsDeck(boundsDeck)
    deck:setTexture(texture)
    deck:reserve(#regions)

    for i, region in ipairs(regions) do
        
        local uvRect = {
            u0 = region.x/page.width,
            v0 = region.y/page.height,
            u1 = (region.x+region.width)/page.width,
            v1 = (region.y+region.height)/page.height
          }
        
        --moai's slightly upsidedown uv rect
        local uv = {uvRect.u0, uvRect.v0, uvRect.u1, uvRect.v0, uvRect.u1, uvRect.v1, uvRect.u0, uvRect.v1 }
        
        if region.rotate then
            uv = {uv[7], uv[8], uv[1], uv[2], uv[3], uv[4], uv[5], uv[6]}
        end
        if self.flipX then
            uv = {uv[3], uv[4], uv[1], uv[2], uv[7], uv[8], uv[5], uv[6]}
        end
        if self.flipY then
            uv = {uv[7], uv[8], uv[5], uv[6], uv[3], uv[4], uv[1], uv[2]}
        end

        
        --setup deck
        deck:setUVQuad(i, unpack(uv))
        deck:setRect(i, region.offsetX, region.offsetY, region.offsetX+region.width, region.offsetY+region.height)
        boundsDeck:setBounds(i, 0, 0, 0, region.originalWidth, region.originalHeight, 0)
        boundsDeck:setIndex(i, i)
        
        --add to region lookup
        if region.index >= 0 then
          if not self.regions[region.name] then self.regions[region.name] = {} end
          self.regions[region.name][region.index+1] = { deck, i } 
        else
          self.regions[region.name] = { deck, i }
        end
    end
   self.pageDecks[page.fileName] = { deck = deck, boundsDeck = boundsDeck, texture = texture, regions = regions }
  
  
end

local function defaultTextureFunc(texturepath)
  local texture = MOAITexture.new()
  texture:load(texturepath)
  return texture
end

function Atlas:assignToProp(regionname, prop)
  local deck,idx = unpack(self.regions[regionname])
  prop:setDeck(deck)
  prop:setIndex(idx)
end



function Atlas:init(atlasfile,flipY, flipX, texturefunc)
    --storage for created decks
    self.pageDecks = {}
    
    self.flipX = flipX
    self.flipY = flipY
    --index of regions to decks and index
    self.regions = {}
    self.texturefunc = texturefunc or defaultTextureFunc
    --atlas
    self.atlas = reader.readAtlas(atlasfile)
    
    --load it up
    for i,v in ipairs(self.atlas.pages) do
      self:createPage(v, i)
    end
    
   
    
end



function create(atlasfile, flipY, flipX, texturefunc)
  local obj = {}
  setmetatable(obj, Atlas_mt)
  obj:init(atlasfile, flipY, flipX, texturefunc)
  return obj
end


return create