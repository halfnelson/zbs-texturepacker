
local homepath = (ide.osname == 'Windows') and os.getenv("USERPROFILE") or os.getenv("HOME")
local zbs_package_dir = 'packages/zbs-texturepacker'
local zbs_user_package_dir = homepath..GetPathSeparator()..'.zbstudio'..GetPathSeparator()..'packages'..GetPathSeparator()..'zbs-texturepacker'

local package_root = zbs_package_dir
if wx.wxDir.Exists(zbs_user_package_dir) then
  package_root = zbs_user_package_dir
end


local package_lib = package_root..GetPathSeparator()..'lib'..GetPathSeparator()..'?.lua'


  


package.path =  package.path .. ';' .. package_lib



local ProjectManager = require("texturepackerproject")

local textureMapperMenuId = ID("zbs-moai.texturemappermenu")
local textureMapperLibMenuId = ID("zbs-moai.texturemapperlibmenu")
local textureMapperRemoveMenuId = ID("zbs-moai.texturemappermenuremove")
local texturePackerConfigId = ID("zbs-moai.textureMapperConfig")
local texturePackerLaunchId = ID("zbs-moai.texturePackerLaunch")
local texturePackerLaunchPopupId = ID("zbs-moai.texturePackerLaunchPopup")
local texturePackerGoId = ID("zbs-moai.texturePackerGo")
local TEXTUREATLAS, TEXTUREATLASCONF


local project


local function onProjectPreLoad(self, projdir) 
   project = ProjectManager.loadProject(projdir)
end
    
    
local function updateTreeImages()
  for dir,_ in pairs(project.TextureAtlasDirs) do
    local item = ide.filetree.projtreeCtrl:FindItem(dir) 
    if item then
      ide.filetree.projtreeCtrl:SetItemImage(item, TEXTUREATLAS)
    end
  end
end


local function onProjectLoad(self, projdir) 
   updateTreeImages()
end


local function onFiletreeGetIcon(name, isdir)
  if isdir and project:isTextureAtlasFolder(name) then
    return TEXTUREATLAS
  end
  
  if not isdir then
    if wx.wxFileName(name):GetFullName() == "pack.json" or
      wx.wxFileName(name):GetFullName() == "texturepacker-config.lua" then
        return TEXTUREATLASCONF
    end
  end
  
  return false
end

local function onFiletreeActivate(self, tree, event, item) 
    local atlaspath = tree:GetItemFullName(item)
    if tree:IsDirectory(item) then
      atlaspath = atlaspath..GetPathSeparator()
      if project:isTextureAtlasFolder(atlaspath) then 
        project:showAtlasFor(atlaspath)
      end
    end
end

local function onMenuFiletree(self, menu, tree, event)
  local item_id = event:GetItem()
    local name = tree:GetItemFullName(item_id)
    menu:AppendSeparator()
    if (tree:IsDirectory(item_id)) then
     name = name..GetPathSeparator()
     if not project:isTextureAtlasFolder(name) then
      menu:Append(textureMapperMenuId, "Create Texture Atlas")
      menu:Enable(textureMapperMenuId, true)

      tree:Connect(textureMapperMenuId, wx.wxEVT_COMMAND_MENU_SELECTED,
        function() 
            if project:newAtlasAt(name) then
              tree:SetItemImage(item_id,TEXTUREATLAS)
              tree:Refresh()
            end
        end)
      
      
      menu:Append(textureMapperLibMenuId, "Install Atlas Reader Libs")
      menu:Enable(textureMapperLibMenuId, true)

      tree:Connect(textureMapperLibMenuId, wx.wxEVT_COMMAND_MENU_SELECTED,
        function() 
            local libpath = package_root..GetPathSeparator()..'client'
            wx.wxCopyFile(libpath..GetPathSeparator()..'atlasreader.lua', name..GetPathSeparator()..'atlasreader.lua', false)
            wx.wxCopyFile(libpath..GetPathSeparator()..'moaiatlas.lua', name..GetPathSeparator()..'moaiatlas.lua', false)
            tree:Refresh()
        end)
    else
       menu:Append(texturePackerLaunchPopupId, "Build Texture Atlas")
      menu:Enable(texturePackerLaunchPopupId, true)

      tree:Connect(texturePackerLaunchPopupId, wx.wxEVT_COMMAND_MENU_SELECTED,
        function() 
          DisplayOutputLn("Building Texture Atlas for "..name)
          local ok, err = project:packFolder(name,function(i) DisplayOutputLn(i) end)
          if ok then
            project:showAtlasFor(name)
          else
              wx.wxMessageBox(err,"Texture Packer Error",wx.wxICON_ERROR)
          end
        end)
      
      
      menu:Append(textureMapperMenuId, "Configure Texture Atlas")
      menu:Enable(textureMapperMenuId, true)

      tree:Connect(textureMapperMenuId, wx.wxEVT_COMMAND_MENU_SELECTED,
        function() 
          project:launchConfigEditor(name)
        end)
      
      menu:Append(textureMapperRemoveMenuId, "Remove Texture Atlas")
      menu:Enable(textureMapperRemoveMenuId, true)

      tree:Connect(textureMapperRemoveMenuId, wx.wxEVT_COMMAND_MENU_SELECTED,
        function() 
          project:removeAtlasAt(name)
          tree:SetItemImage(item_id,0)
          tree:Refresh()
        end)
    end
  end
end

local function showConfig()
  --cache old values for delete detection
  local oldDirs = {}
  for k,v in pairs(project.TextureAtlasDirs) do
    oldDirs[k] = true
  end
  project:launchProjectEditor()
  local newDirs = project.TextureAtlasDirs
  
  for k,v in pairs(oldDirs) do
    if not newDirs[k] then
      local item = ide.filetree.projtreeCtrl:FindItem(k) 
       if item then
        ide.filetree.projtreeCtrl:SetItemImage(item, 0)
       end
    end
  end
  
  
  
  updateTreeImages()
  ide.filetree.projtreeCtrl:Refresh()
end

local oldIsDirFunc
local oldExpanderFunc

local function onRegister () 
   local ico = wx.wxBitmap(package_root.."/res/TEXTUREATLAS.png")
   TEXTUREATLAS = ide.filetree.imglist:Add(ico)
   
   ico = wx.wxBitmap(package_root.."/res/TEXTUREATLASCONF.png")
   TEXTUREATLASCONF = ide.filetree.imglist:Add(ico)
   
   --patch tree
   oldIsDirFunc = ide.filetree.projtreeCtrl.IsDirectory
   ide.filetree.projtreeCtrl.IsDirectory = function(self, item_id)
      return oldIsDirFunc(self,item_id) or ide.filetree.projtreeCtrl:GetItemImage(item_id) == TEXTUREATLAS
   end
   
   
   local oldExpanderFunc
   ide.filetree.projtreeCtrl:Connect(wx.wxEVT_COMMAND_TREE_ITEM_EXPANDING,
    function (event)
      updateTreeImages()
      ide.filetree.projtreeCtrl:Refresh()
      event:Skip(true)
    end)

   --add our config menu to project tab
   --get project menu
   local projectMenuId = ide.frame.menuBar:FindMenu(TR("&Project"))
   local projectMenu = ide.frame.menuBar:GetMenu(projectMenuId)
   
   --append
   projectMenu:Append(texturePackerConfigId, TR("Configure Texure Packer..."), TR("Launch Texture Packer Configuration"))
   projectMenu:Connect(texturePackerConfigId, wx.wxEVT_COMMAND_MENU_SELECTED, showConfig)
   
   
   local function executeTexturePacker()
      DisplayOutputLn("Running Texture Packer...")
        
        local ok, err =  project:packAll(function(i) DisplayOutputLn(i) end)
        
        if not ok then
          wx.wxMessageBox(err,"Texture Packer Error",wx.wxICON_ERROR)
        end
   end
   
   
   projectMenu:Append( texturePackerLaunchId, TR("Execute Texture Packer"), TR("Execute Texture Packer"))
   projectMenu:Connect( texturePackerLaunchId, wx.wxEVT_COMMAND_MENU_SELECTED, executeTexturePacker)
   
  
    --TODO add toolbar icon to repack using toolBar:AddTool(id, "", bitmap, TR("description")) use GetWidth on bmp from GetBitmap from ide.frame.toolbar
    --image can be 24 or 16
    local tb = ide:GetToolBar() 
    local size = tb:GetToolBitmapSize()
    local width = size:GetWidth()
    local bmp
    if (width == 24) then
      bmp = wx.wxBitmap(package_root.."/res/TEXTUREATLASGO_24.png")
    else
      bmp = wx.wxBitmap(package_root.."/res/TEXTUREATLASGO.png")
    end
    

    tb:AddTool(texturePackerGoId, "", bmp,"Build Atlases")

    tb:Connect(texturePackerGoId, wx.wxEVT_COMMAND_MENU_SELECTED, executeTexturePacker)
    tb:Realize()
end

return {
  name = "ZBS Texture Packer",
  description = "Integrates libgdx TexturePacker with ZBS",
  author = "David Pershouse",
  version = 0.1,
  dependencies = 1.10,
  onRegister = onRegister,
  onMenuFiletree = onMenuFiletree,
  onProjectPreLoad = onProjectPreLoad,
  onProjectLoad = onProjectLoad,
  onFiletreeActivate = onFiletreeActivate
  
}