function GetUI()
local UI = {}


-- create TexturePackerProject
UI.TexturePackerProject = wx.wxDialog (wx.NULL, wx.wxID_ANY, "Texture Packer Project Settings", wx.wxDefaultPosition, wx.wxSize( 568,290 ), wx.wxDEFAULT_DIALOG_STYLE )
	UI.TexturePackerProject:SetSizeHints( wx.wxDefaultSize, wx.wxDefaultSize )
	
	UI.bSizer1 = wx.wxBoxSizer( wx.wxVERTICAL )
	
	UI.bSizer2 = wx.wxBoxSizer( wx.wxHORIZONTAL )
	
	UI.m_staticText1 = wx.wxStaticText( UI.TexturePackerProject, wx.wxID_ANY, "Java Binary", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticText1:Wrap( -1 )
	UI.bSizer2:Add( UI.m_staticText1, 0, wx.wxALL + wx.wxALIGN_CENTER_VERTICAL, 5 )
	
	UI.m_javaBin = wx.wxFilePickerCtrl( UI.TexturePackerProject, wx.wxID_ANY, "", "Select a file", "*.*", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxFLP_DEFAULT_STYLE )
	UI.bSizer2:Add( UI.m_javaBin, 1, wx.wxALL, 5 )
	
	
	UI.bSizer1:Add( UI.bSizer2, 0, wx.wxEXPAND, 5 )
	
	UI.bSizer3 = wx.wxBoxSizer( wx.wxHORIZONTAL )
	
	UI.m_staticText2 = wx.wxStaticText( UI.TexturePackerProject, wx.wxID_ANY, "Folders To Pack:", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticText2:Wrap( -1 )
	UI.bSizer3:Add( UI.m_staticText2, 0, wx.wxALIGN_BOTTOM + wx.wxALL, 5 )
	
	
	UI.bSizer3:Add( 0, 0, 1, wx.wxEXPAND, 5 )
	
	UI.m_add = wx.wxButton( UI.TexturePackerProject, wx.wxID_ANY, "Add", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer3:Add( UI.m_add, 0, wx.wxEXPAND + wx.wxTOP + wx.wxRIGHT + wx.wxLEFT, 5 )
	
	UI.m_run = wx.wxButton( UI.TexturePackerProject, wx.wxID_ANY, "Pack All", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer3:Add( UI.m_run, 0, wx.wxTOP + wx.wxRIGHT + wx.wxLEFT, 5 )
	
	
	UI.bSizer1:Add( UI.bSizer3, 0, wx.wxEXPAND, 5 )
	
	UI.m_folders = wx.wxTreeCtrl( UI.TexturePackerProject, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTR_DEFAULT_STYLE + wx.wxTR_HIDE_ROOT )
	UI.bSizer1:Add( UI.m_folders, 1, wx.wxEXPAND + wx.wxBOTTOM + wx.wxRIGHT + wx.wxLEFT, 5 )
	
	
	UI.TexturePackerProject:SetSizer( UI.bSizer1 )
	UI.TexturePackerProject:Layout()
	
	UI.TexturePackerProject:Centre( wx.wxBOTH )


return UI
end
return GetUI
--wx.wxGetApp():MainLoop()
