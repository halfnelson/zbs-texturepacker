local function GetUI()
local UI = {}

  -- create MyDialog1
  UI.MyDialog1 = wx.wxDialog (wx.NULL, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxSize( 560,560 ), wx.wxDEFAULT_DIALOG_STYLE )
	UI.MyDialog1:SetSizeHints( wx.wxDefaultSize, wx.wxDefaultSize )
	
	UI.bSizer1 = wx.wxBoxSizer( wx.wxVERTICAL )
	
	UI.m_scrolledWindow1 = wx.wxScrolledWindow( UI.MyDialog1, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxVSCROLL )
	UI.m_scrolledWindow1:SetScrollRate( 5, 5 )
	UI.bSizer2 = wx.wxBoxSizer( wx.wxVERTICAL )
	
	UI.m_scrolledWindow1:SetSizer( UI.bSizer2 )
	UI.m_scrolledWindow1:Layout()
	UI.bSizer2:Fit( UI.m_scrolledWindow1 )
	UI.bSizer1:Add( UI.m_scrolledWindow1, 1, wx.wxEXPAND  + wx.wxALL, 5 )
	
	UI.MyDialog1:SetSizer( UI.bSizer1 )
	UI.MyDialog1:Layout()
	
	UI.MyDialog1:Centre( wx.wxBOTH )
  
  return UI
end

Dialog = {}
Dialog_mt = { __index = Dialog }


--[[
	UI.m_bitmap1 = wx.wxStaticBitmap( UI.m_scrolledWindow1, wx.wxID_ANY, wx.wxBitmap( "K:\\dev\\mobile\\moaiforge\\sdks\\zbs-moai\\plugin\\zbs-moai\\test-output\\pack.png", wx.wxBITMAP_TYPE_ANY ), wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
  ]]--
local function GetDialog(atlasPath)
  local dlg = {
    UI = GetUI(),
    AtlasPath = atlasPath
  }
  setmetatable(dlg, Dialog_mt)
  
  --our caption
  dlg.UI.MyDialog1:SetTitle(wx.wxFileName(atlasPath):GetFullName())
  dlg:loadAtlas()
  
  dlg.UI.MyDialog1:Connect(wx.wxEVT_CLOSE_WINDOW, function(event) 
    dlg.UI.MyDialog1:Destroy()
  end)
    
  return dlg
  
end



local function getPages(atlasPath)
  
  local blankCount = 0
  local pages = {}
  local basePath = wx.wxFileName(atlasPath):GetPath(wx.wxPATH_GET_VOLUME)
  
  for line in io.lines(atlasPath) do 
    if line == "" then
      blankCount = blankCount + 1
    else
      if blankCount == 1 then
        table.insert(pages, basePath..string.char(wx.wxFileName.GetPathSeparator())..line)
      end
      blankCount = 0
    end
  end
  return pages
end


function Dialog:loadAtlas()
  
  
  local pages = getPages(self.AtlasPath)
  self.UI.bitmaps = {}
  for i,page in ipairs(pages) do
    --load image
    local img = wx.wxImage(page)
    --resize
    local scale = 512/img:GetWidth()
    local bmp 
    if (scale > 1 ) then
      bmp = wx.wxBitmap(img)
    else
      bmp = wx.wxBitmap(img:Scale(512, img:GetHeight()*scale))
    end
  
    --add to form
    local formbmp = wx.wxStaticBitmap( self.UI.m_scrolledWindow1, wx.wxID_ANY, bmp, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxSIMPLE_BORDER )
    self.UI.bSizer2:Add( formbmp, 0, wx.wxALL, 5 )
  end
end

function Dialog:show()
  self.UI.MyDialog1:Show()
end

return GetDialog


