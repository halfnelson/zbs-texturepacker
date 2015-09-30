local Dialog = {}
local Dialog_mt = { __index = Dialog }


local loadDialog = function(outputSettings, packerSettings)

    local props = { 
      UI = require('texturepackerdialog-ui')(),
      packerSettings = packerSettings
    }
    setmetatable(props, Dialog_mt)
    
    props:createBindings()
    props.outputBindings:setValues(outputSettings)
    props.packerBindings:setValues(packerSettings)
    
    props:bindEvents()
    --return our new item
    return props
 end


function Dialog:createBindings()
  local UI = self.UI
  self.outputBindings = require('wxbinder').create()
  local b = self.outputBindings
  
    --output settings
  b:bindDirPicker("OutputFolder", UI.m_outputDir)
  b:bindText("PackName", UI.m_packName)
  
  self.packerBindings = require('wxbinder').create()
  local p = self.packerBindings
    
   --packer settings
  p:bindChoice("outputFormat", UI.m_imageFormat)
  p:bindSpinnerPercent("jpegQuality", UI.m_jpegQuality)
  p:bindCheckbox("premultiplyAlpha", UI.m_premultiplyAlpha)
    
    --Texture
  p:bindChoice("format", UI.m_pixelFormat)
  p:bindChoice("filterMin", UI.m_minFilter)
  p:bindChoice("filterMag", UI.m_magFilter)
  p:bindChoice("wrapX", UI.m_wrapX)
  p:bindChoice("wrapY", UI.m_wrapY)
    
    --Whitespace Stripping
  p:bindCheckbox("stripWhitespaceX", UI.m_stripWhitespaceX)
  p:bindCheckbox("stripWhitespaceY", UI.m_stripWhitespaceY)
  p:bindSpinner("alphaThreshold", UI.m_alphaThreshold)
  
    --page size
  p:bindSpinner("minWidth", UI.m_minPageWidth)
  p:bindSpinner("minHeight", UI.m_minPageHeight)
  p:bindSpinner("maxWidth", UI.m_maxPageWidth)
  p:bindSpinner("maxHeight", UI.m_maxPageHeight)
    
  p:bindCheckbox("square",UI.m_forceSquare)
  p:bindCheckbox("pot",UI.m_pot)
  
    --padding
  p:bindSpinner("paddingX",UI.m_paddingX)
  p:bindSpinner("paddingY",UI.m_paddingY)
  
  p:bindCheckbox("edgePadding", UI.m_edgePadding)
  p:bindCheckbox("duplicatePadding", UI.m_duplicatePadding)
  p:bindCheckbox("grid", UI.m_grid)
    
    --Debug
  p:bindCheckbox("debug", UI.m_debug)

end

    
  
function Dialog:GetOutputSettings()
  local vals= self.outputBindings:getValues()
  if vals.PackName == "" then
    vals.PackName = "pack"
  end
  return vals
end

function Dialog:GetPackerSettings()
    local s = {}
    for k,v in pairs(self.packerSettings) do
      s[k] = v
    end
    self.packerBindings:bindUITo(s)
    return s
  end
  
  
function Dialog:validationError(message)
     local dlg = wx.wxMessageDialog(self.UI.TexturePackerSettings,message,"Validation Error")
     dlg:ShowModal()
     dlg:Destroy()
  end
  
  
function Dialog:validateOutputSettings()
    local s = self:GetOutputSettings()
    if s.OutputFolder == "" then
      self:validationError("Output folder is required")
      return false
    end
    
    if not wx.wxFileName.DirExists(s.OutputFolder) then
      self:validationError("Output folder does not exist")
      return false
    end
    
    return true
  end
  
function Dialog:ShowModal()
  return self.UI.TexturePackerSettings:ShowModal()
end

function Dialog:Destroy()
  self.UI.TexturePackerSettings:Destroy()
end


  
  
function Dialog:bindEvents()
	
  self.UI.m_sdbSizer1Save:Connect(    wx.wxEVT_COMMAND_BUTTON_CLICKED,  function(event)
    --implements saveClicked
    if self:validateOutputSettings() then
      self.UI.TexturePackerSettings:EndModal(0)
    end
   	event:Skip()
	end )
	

end

return loadDialog
--wx.wxGetApp():MainLoop()
