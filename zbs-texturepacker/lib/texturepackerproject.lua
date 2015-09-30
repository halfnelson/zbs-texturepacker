--[[
 Helper functions
--]]

local function thisDir()
  local info = debug.getinfo(1,'S');
  local fname = info.source:gsub("@","")
  local dir = wx.wxFileName(fname):GetPath()
  return dir
end


local md = require("mobdebug.mobdebug")
local function tableToLua(t)
  return md.line(t , {indent='  ', comment=false} )
end

--converts a lua table string into a gdx compat minimal json string
local function dodgyLuaToJson(l)
  local j = string.gsub(l,"=",":") --string.gsub(l,"
  j = string.gsub(j,": {(.-)}",": [%1]")
  return j
end

local function dodgyTableToJson(t) 
  return dodgyLuaToJson(tableToLua(t))
end

local function dodgyJsonToLua(j)
  local l = string.gsub(j,":","=")
  l = string.gsub(l,"= %[(.-)%]","= { %1 }") --swap array syntax
  l = string.gsub(l,"\"(%w-)\" =","%1 =") --strip json quotes
  l = string.gsub(l,"(%w-) =","['%1'] =") --table key syntax for lua
  return l
end

local function dodgyLuaToTable(l)
    local fn,err = loadstring("do local _ = "..l.."; return _ end")
    return fn()
end

local function dodgyJsonToTable(j)
  return dodgyLuaToTable(dodgyJsonToLua(j))
end

local function tableToConfigLua(t, varname)
  return md.line(t , {indent='  ', comment=false, name =varname} )
end

local function fileWrite(fname,content)
  local file = wx.wxFile(fname, wx.wxFile.write)
  file:Write(content, #content)
  file:Close()
end

local function fileSize(fname) --thanks to Paul Kulchenko for working this one out
  local size = wx.wxFileSize(fname)
  -- size can be returned as 0 for symlinks, so check with wxFile:Length();
  -- can't use wxFile:Length() as it's reported incorrectly for some non-seekable files
  -- (see https://github.com/pkulchenko/ZeroBraneStudio/issues/458);
  -- the combination of wxFileSize and wxFile:Length() should do the right thing.
  if size == 0 then size = wx.wxFile(fname, wx.wxFile.read):Length() end
  return size
end

local function fileRead(fname)
  local file = wx.wxFile(fname, wx.wxFile.read) 
  local _, result = file:Read(fileSize(fname))
  file:Close()
  return result
end

local function getParentFolder(dir)
    local f = wx.wxFileName.DirName(dir)
    f:RemoveLastDir()
    return f:GetFullPath()
end

local function getPathSeparator()
  return string.char(wx.wxFileName.GetPathSeparator())
end

local function isSameOrSubpathOf(root,name)
  return root == name or  string.sub(name,1,string.len(root))==root
end

local function overrideConfig(base, ext)
  local newSettings = {}
  for k,v in pairs(base) do
    newSettings[k]=v
  end
  
  for k,v in pairs(ext) do
    newSettings[k]=v
  end
  return newSettings
end

local newPackJSON = {

}
  

local PackJSONDefaults = {
    pot= true,
    paddingX= 2,
    paddingY= 2,
    bleed= true,
    edgePadding= true,
    duplicatePadding= false,
    rotation= false,
    minWidth= 16,
    minHeight= 16,
    maxWidth= 1024,
    maxHeight= 1024,
    square= false,
    stripWhitespaceX= false,
    stripWhitespaceY= false,
    alphaThreshold= 0,
    filterMin= "Nearest",
    filterMag= "Nearest",
    wrapX= "ClampToEdge",
    wrapY= "ClampToEdge",
    ['format']= "RGBA8888",
    alias= true,
    outputFormat= "png",
    jpegQuality= 0.9,
    ignoreBlankImages= true,
    fast= false,
    debug= false,
    combineSubdirectories= false,
    flattenPaths= false,
    premultiplyAlpha= false,
    useIndexes= true,
    limitMemory= true,
    grid= false,
    scale= { 1 },
    scaleSuffix= { "" }
}


local Project = {}
local Project_mt = { __index = Project }

local ProjectManager = {
  loadProject = function(dir,javabin)
    --create new project object
    local props = { 
       ProjectDir = dir,
       TextureAtlasDirs = {},
       JavaBin = javabin or "java",
    }
    setmetatable(props, Project_mt)
    
    --load config (if exists)
    props:loadConfig()
    
    --return our new item
    return props
  end
}

function Project:makeRelative(name)
  local dir = wx.wxFileName.DirName(name)
  dir:MakeAbsolute(self.ProjectDir)
  dir:MakeRelativeTo(self.ProjectDir)
  return dir:GetFullPath(wx.wxPATH_UNIX)
end

function Project:makeAbsolute(name)
  local f = wx.wxFileName.DirName(name:gsub("/",getPathSeparator()))
  f:MakeAbsolute(self.ProjectDir..getPathSeparator())
  return f:GetFullPath()
end

function Project:getSubFoldersOf(name)
  local f = self:makeAbsolute(name)
  local subdirs = {}
  if not wx.wxDir.Exists(f) then return subdirs end
  
  local d = wx.wxDir(f)
  if not d:HasSubDirs() then return subdirs end
  
  local continue, dir = d:GetFirst("", wx.wxDIR_DIRS)
  while continue do
    table.insert(subdirs,dir)      
    continue, dir = d:GetNext()
  end
  
  return subdirs
end


function Project:loadConfig()
  local f = wx.wxFileName.DirName(self.ProjectDir)
  f:SetFullName("texturepacker-config.lua")
  if f:FileExists() then
      local cfgfn = loadfile(f:GetFullPath())
      if cfgfn then
        local config = cfgfn()
        if config then
          self.TextureAtlasDirs = config.AtlasDirs or {}
          self.JavaBin = config.JavaBin or self.JavaBin
        end
      end
  end
end


function Project:saveConfig()
  local f = wx.wxFileName.DirName(self.ProjectDir)
  f:SetFullName("texturepacker-config.lua")
  local config = { JavaBin= self.JavaBin, AtlasDirs= self.TextureAtlasDirs }
  fileWrite(f:GetFullPath(), tableToConfigLua(config, "textureAtlasDirs"))
end



function Project:rootTextureAtlasFolderFor(name)
  for r,_ in pairs(self.TextureAtlasDirs) do
       local fullpath = self:makeAbsolute(r)  --  self.ProjectDir..getPathSeparator()..(r:gsub("/",getPathSeparator()))
       if isSameOrSubpathOf(fullpath,name) then
         return r
       end
  end
  return false
end

function Project:isTextureAtlasFolder(name)
  return self:rootTextureAtlasFolderFor(name) and true or false
end


function Project:savePackerConfig(dir, config)
   --first work out what fields have changed from default
   local diff = {}
   local parentConfig = self:getParentConfig(dir)
   local empty = true
   for k,v in pairs(config) do
    if parentConfig[k] ~= v then
      diff[k] = v
      empty = false
    end
   end
   if not empty then
     local content = dodgyTableToJson(diff)
     fileWrite(dir..getPathSeparator().."pack.json", content)
   else
     --we can remove it
     wx.wxRemoveFile(dir..getPathSeparator().."pack.json")
   end
end



local function configAtPath(dir)
  local f = wx.wxFileName.DirName(dir)
  f:SetFullName("pack.json")
  if f:FileExists() then
    return dodgyJsonToTable(fileRead(f:GetFullPath()))
  else
    return newPackJSON
  end
end

function Project:getParentConfig(dir)
  local parentDir = getParentFolder(dir)
  local parentConfig
  if self:isTextureAtlasFolder(parentDir) then
    parentConfig = self:getCombinedConfig(parentDir)
  else
    parentConfig = PackJSONDefaults
  end
  return parentConfig
end


function Project:getCombinedConfig(dir)
  local parentConfig = self:getParentConfig(dir)
  local thisConfig = configAtPath(dir)
  return overrideConfig(parentConfig, thisConfig)
end

function Project:launchConfigEditor(name)
  
  local textureAtlasFolder = self:rootTextureAtlasFolderFor(name) or self:makeRelative(name)
  
  local inputSettings = self.TextureAtlasDirs[textureAtlasFolder] or {}
  if (inputSettings.OutputFolder) then
    inputSettings.OutputFolder = self:makeAbsolute(inputSettings.OutputFolder)
  end
  
  local settingsDialog = require("texturepackerdialog")(inputSettings, self:getCombinedConfig(name))
  local result = settingsDialog:ShowModal()
  if result == 0 then
    
    local outputSettings = settingsDialog:GetOutputSettings()
    --patch outputfolder to be relative
    outputSettings.OutputFolder = self:makeRelative(outputSettings.OutputFolder)
    self.TextureAtlasDirs[textureAtlasFolder] = outputSettings
    self:saveConfig()
    
    local packerSettings = settingsDialog:GetPackerSettings()
    self:savePackerConfig(name, packerSettings)
    
  end
  
  settingsDialog:Destroy()
  return result == 0
end


function Project:launchProjectEditor()
  local dlg = require('texturepackerprojectdialog')(self)
  dlg:ShowModal()
  local res = dlg:GetValues()
  self.JavaBin = res.JavaBin
  self:saveConfig()
  dlg:Destroy()
end



function Project:newAtlasAt(dir)
  local name = self:makeRelative(dir)
  return self:launchConfigEditor(name)
end

function Project:removeAtlasAt(dir)
  local name =self:rootTextureAtlasFolderFor(dir)
  self.TextureAtlasDirs[name] = nil
  self:saveConfig()
end

function Project:packFolder(dir,outputCallback)
  
  local inputFolder = self:makeAbsolute(dir)
  local name =self:rootTextureAtlasFolderFor(inputFolder)
  local settings = self.TextureAtlasDirs[name]
  local outputFolder = self:makeAbsolute(settings.OutputFolder)
  
  local cmd = '"'..self.JavaBin..'"'.." -jar "..thisDir()..getPathSeparator().."runnable-texturepacker.jar "..inputFolder.." "..outputFolder.." "..settings.PackName
  if outputCallback then
    outputCallback("running cmd:"..cmd)
  end
  local f = io.popen(cmd, 'r')
  while true do
    local s = f:read('*line')
    if s == nil then break end
    if outputCallback then outputCallback(s) end
  end
  
end

function Project:showAtlasFor(name)
   local conf = self.TextureAtlasDirs[self:rootTextureAtlasFolderFor(name)]
   local dlg = require('atlasviewer')(self:makeAbsolute(conf.OutputFolder)..conf.PackName..".atlas")
   dlg:show()
end



function Project:packAll(outputCallback)
  for f,_ in pairs(self.TextureAtlasDirs) do
    outputCallback("Processing Folder "..f)
    self:packFolder(f,outputCallback)
  end
end

return ProjectManager
