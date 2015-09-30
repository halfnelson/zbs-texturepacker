
local Dialog = {}
local Dialog_mt = { __index = Dialog }

local loadDialog = function(project)
    --create new project object
    local props = { 
       Project = project,
       UI = require('texturepackerprojectdialog-ui')()
    }
    setmetatable(props, Dialog_mt)
    props:createBindings()
    props:bindToProject()
    props:bindPopupMenu()
    props:bindAddButton()
    props:bindPackButton()
    --return our new item
    return props
 end

local texturePackerConfigMenuId = ID("zbs-moai.textureMapperConfigMenu")
local texturePackerRemoveMenuId = ID("zbs-moai.textureMapperRemoveMenu")
function Dialog:AddFolder()
  local dlg = wx.wxDirDialog(self.UI.TexturePackerProject, "Select Atlas Folder",self.Project.ProjectDir)
  local res = dlg:ShowModal()
  if res == wx.wxID_OK then
     local path = dlg:GetPath()
     if self.Project:launchConfigEditor(path) then
       self:bindToProject()
     end
  end
  dlg:Destroy()
end

function Dialog:bindPackButton()
  local butt = self.UI.m_run
  butt:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function() 
      self.Project:packAll(function(i) DisplayOutputLn(i) end)
  end)
end

function Dialog:bindAddButton()
  local butt = self.UI.m_add
  butt:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function() 
      self:AddFolder()
  end)
end

function Dialog:launchConfigForTreeItem(item_id)
  local ctl = self.UI.m_folders
  local dir= ctl:GetItemText(item_id) 
  local parent = ctl:GetItemParent(item_id)
  if parent:GetValue() ~= self.root:GetValue() then
   dir = ctl:GetItemText(parent).."/"..dir
  end
  dir = self.Project:makeAbsolute(dir)
  self.Project:launchConfigEditor(dir)
end



function Dialog:bindPopupMenu()
  local ctl = self.UI.m_folders
  
  ctl:Connect(wx.wxEVT_COMMAND_TREE_ITEM_ACTIVATED,function(event)
             local item_id = event:GetItem()
             self:launchConfigForTreeItem(item_id)
  end)
  
  ctl:Connect(wx.wxEVT_COMMAND_TREE_ITEM_MENU,
    function (event)
      local item_id = event:GetItem()
      ctl:SelectItem(item_id)
      local menu = wx.wxMenu({
        { texturePackerConfigMenuId, TR("Edit Config...") },
        { texturePackerRemoveMenuId, TR("Remove Atlas") }
        
      })
    
      menu:Connect(texturePackerConfigMenuId, wx.wxEVT_COMMAND_MENU_SELECTED, function()
         self:launchConfigForTreeItem(item_id)
      end)
    
      menu:Connect(texturePackerRemoveMenuId, wx.wxEVT_COMMAND_MENU_SELECTED, function()
         
         local dir= ctl:GetItemText(item_id) 
         local parent = ctl:GetItemParent(item_id)
         if parent:GetValue() ~= self.root:GetValue() then
           dir = ctl:GetItemText(parent).."/"..dir
         end
         dir = self.Project:makeAbsolute(dir)
         self.Project:removeAtlasAt(dir)
         self:bindToProject()
      end)
    
      ctl:PopupMenu(menu)
    end)
end

function Dialog:createBindings() 
  self.Binder = require('wxbinder').create()
  self.Binder:bindFilePicker('JavaBin', self.UI.m_javaBin)
  local this = self
  self.Binder:addBinding('TextureAtlasDirs', self.UI.m_folders, 
    function(var, widget) 
      this:UpdateFolderList(var,widget) 
    end, 
    function() 
      return false 
    end)
end

function Dialog:bindToProject() 
  self.Binder:setValues(self.Project)
end

function Dialog:GetValues() 
  return self.Binder:getValues()
end

function Dialog:UpdateFolderList(folders, tree)
  tree:DeleteAllItems()
  local root = tree:AddRoot("Texture Packed Folders")
  self.root = root
  for folder,settings in pairs(folders) do
    local parent = tree:AppendItem(root, folder)
    local subdirs = self.Project:getSubFoldersOf(folder)
    for _,subdir in ipairs(subdirs) do
      tree:AppendItem(parent, subdir)
    end
  end
  tree:CollapseAll()
  tree:Expand(root)
end

function Dialog:ShowModal() 
  return self.UI.TexturePackerProject:ShowModal()
end

function Dialog:Destroy() 
   self.UI.TexturePackerProject:Destroy()
end


return loadDialog