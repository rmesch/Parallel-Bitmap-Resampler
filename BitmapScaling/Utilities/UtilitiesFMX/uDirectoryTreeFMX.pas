unit uDirectoryTreeFMX;
// Displays the directory-tree of a root folder. New nodes are only created as necessary
// when either a node is selected or expanded.
// For performance reasons, folders with more than 1000 direct subfolders will not be expanded.

interface

uses FMX.TreeView, System.Generics.Collections, System.Classes,
  System.Types, FMX.Types,
  System.IOUtils, System.SysUtils, System.UITypes;

type

  TTreeViewItem = class(FMX.TreeView.TTreeViewItem)
  protected
    procedure SetIsExpanded(const Value: Boolean); override;
  end;

  TNodeData = record
    FullPath: string;
    HasEnoughSubnodes: Boolean;
  end;
  PNodeData=^TNodeData;

  TDirectoryTree = class(TTreeView)
  private
    fDirectoryDict: TDictionary<NativeUInt, TNodeData>;
    procedure CreateSubNodesToLevel2(aItem: TTreeViewItem);
  protected
    procedure DoChange; override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure NewRootFolder(const RootFolder: string);
    function GetFullFolderName(aItem: TTreeViewItem): string;
  end;

implementation

uses FMX.Dialogs;

{ TDirectoryTree }

procedure TDirectoryTree.DoChange;
begin
  if not(csLoading in ComponentState) then
    CreateSubNodesToLevel2(TTreeViewItem(Selected));
  inherited;
end;

constructor TDirectoryTree.Create(aOwner: TComponent);
begin
  inherited;
  fDirectoryDict := TDictionary<NativeUInt, TNodeData>.Create;
end;

destructor TDirectoryTree.Destroy;
begin
  fDirectoryDict.Free;
  inherited;
end;

procedure TDirectoryTree.CreateSubNodesToLevel2(aItem: TTreeViewItem);
var
  DirArraySize1, DirArraySize2, i, j: integer;
  DirArray1, DirArray2: TStringDynArray;
  TreeItem, TreeItem2: TTreeViewItem;
  NewName: string;
  FileAtr: integer;
  DirectoryCount: integer;
  NodeData, NodeData1: TNodeData;
begin
  if not fDirectoryDict.ContainsKey(NativeUInt(aItem)) then
    raise Exception.Create('Node has no directory name');
  if fDirectoryDict[NativeUInt(aItem)].HasEnoughSubnodes then
    exit;
  BeginUpdate;
  try
{$IFDEF MSWindows}
    FileAtr := faHidden + faSysFile + faSymLink;
{$ELSE}
    raise Exception.Create('Works for MSWindows only');
{$ENDIF}
    NodeData.FullPath := fDirectoryDict[NativeUInt(aItem)].FullPath;
    NodeData.HasEnoughSubnodes := false;
    DirectoryCount := 0;
    DirArray1 := TDirectory.GetDirectories(GetFullFolderName(aItem),
      // stop reading entries if the count exceeds 1000
      function(const path: string; const SearchRec: TSearchRec): Boolean
      begin
        Result := (DirectoryCount < 1001) and (SearchRec.Attr and (not FileAtr)
          = SearchRec.Attr);
        if Result then
          inc(DirectoryCount);
      end);
    DirArraySize1 := Length(DirArray1);
    // ignore folders with more than 1000 entries
    if (DirArraySize1 < 1) or (DirArraySize1 > 1000) then
    begin
      NodeData.HasEnoughSubnodes := true;
      fDirectoryDict.AddOrSetValue(NativeUInt(aItem), NodeData);
      exit;
    end;
    for i := 0 to DirArraySize1 - 1 do
    begin
      NewName := DirArray1[i];
      if aItem.Count <= i then // NewName doesn't have a node yet
      begin
        TreeItem := TTreeViewItem.Create(self);
        NodeData1.FullPath := NewName;
        NodeData1.HasEnoughSubnodes := false;
        fDirectoryDict.Add(NativeUInt(TreeItem), NodeData1);
        TreeItem.Text := ExtractFilename(NewName);
        TreeItem.ImageIndex := 0;
        TreeItem.Parent := aItem;
      end
      else
        TreeItem := TTreeViewItem(aItem.Items[i]); // <------------
      if TreeItem.Count > 0 then // has its subnodes already
        Continue;
      DirectoryCount := 0;
      DirArray2 := TDirectory.GetDirectories(NewName,
        function(const path: string; const SearchRec: TSearchRec): Boolean
        begin
          Result := (DirectoryCount < 1001) and
            (SearchRec.Attr and (not FileAtr) = SearchRec.Attr);
          if Result then
            inc(DirectoryCount);
        end);
      DirArraySize2 := Length(DirArray2);
      if (DirArraySize2 < 1) or (DirArraySize2 > 1000) then
      begin
        NodeData1.FullPath := NewName;
        NodeData1.HasEnoughSubnodes := true;
        // Don't expand a folder with more than 1000 subfolders any futher
        fDirectoryDict.AddOrSetValue(NativeUInt(TreeItem), NodeData1);
        Continue;
      end;
      for j := 0 to DirArraySize2 - 1 do
      begin
        if TreeItem.Count <= j then // DirArray[j] doesn't have a node yet
        begin
          TreeItem2 := TTreeViewItem.Create(self);
          NodeData1.FullPath := DirArray2[j];
          NodeData1.HasEnoughSubnodes := false;
          fDirectoryDict.Add(NativeUInt(TreeItem2), NodeData1);
          TreeItem2.Text := ExtractFilename(DirArray2[j]);
          TreeItem2.ImageIndex := 0;
          TreeItem2.Parent := TreeItem;
        end;
      end;
    end;
    NodeData.HasEnoughSubnodes := true;
    fDirectoryDict.AddOrSetValue(NativeUInt(aItem), NodeData);
  finally
    EndUpdate;
  end;
end;

procedure TDirectoryTree.NewRootFolder(const RootFolder: string);
var
  Root: TTreeViewItem;
  ShortName: string;
  NodeData: TNodeData;
begin
  if not System.SysUtils.DirectoryExists(RootFolder) then
    raise Exception.Create(RootFolder + ' does not exist');
  fDirectoryDict.Clear;
  Clear;
  BeginUpdate;
  try
    ShortName := ExtractFilename(RootFolder);
    if ShortName = '' then
      ShortName := RootFolder;
    Root := TTreeViewItem.Create(self);
    NodeData.FullPath := RootFolder;
    NodeData.HasEnoughSubnodes := false;
    fDirectoryDict.Add(NativeUInt(Root), NodeData);
    Root.Text := ShortName;
    Root.ImageIndex := 0;
    Root.Parent := self;
    CreateSubNodesToLevel2(Root);
  finally
    EndUpdate;
  end;
  Root.Expand;
end;

function TDirectoryTree.GetFullFolderName(aItem: TTreeViewItem): string;
begin
  if not fDirectoryDict.ContainsKey(NativeUInt(aItem)) then
    raise Exception.Create('Node has no directory name');
  Result := fDirectoryDict.Items[NativeUInt(aItem)].FullPath;
end;

{ TTreeViewItem }

procedure TTreeViewItem.SetIsExpanded(const Value: Boolean);
var
  IsExpandedOld: Boolean;
begin
  IsExpandedOld := IsExpanded;
  inherited;
  if IsExpanded and (not IsExpandedOld) then
    if TreeView is TDirectoryTree then
      TDirectoryTree(TreeView).CreateSubNodesToLevel2(self);

end;

end.
