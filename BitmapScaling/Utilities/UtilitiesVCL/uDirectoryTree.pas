unit uDirectoryTree;
//Displays the directory-tree of a root folder. New nodes are only created as necessary
//when either a node is selected or expanded.
//For performance reasons, folders with more than 1000 direct subfolders will not be expanded.

interface

uses VCL.ComCtrls, VCL.Controls, System.Classes,
  System.Types, System.Generics.Collections,
  System.IOUtils, System.SysUtils;

type
  TNodeData=record
    FullPath: string;
    HasEnoughSubnodes: boolean;
  end;

  TDirectoryTree = class(TTreeView)
  private
    fDirectoryDict: TDictionary<NativeUInt, TNodeData>;
    procedure CreateSubNodesToLevel2(aItem: TTreeNode);
  protected
    procedure Change(Node: TTreeNode); override;
    procedure Expand(Node: TTreeNode); override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure NewRootFolder(const RootFolder: string);
    function GetFullFolderName(aNode: TTreeNode): string;
  end;

implementation

uses WinAPI.Windows;

{ TDirectoryTree }

procedure TDirectoryTree.Expand(Node: TTreeNode);
begin
  CreateSubNodesToLevel2(Node);
  inherited;
end;

procedure TDirectoryTree.Change(Node: TTreeNode);
begin
  CreateSubNodesToLevel2(Node);
  inherited;
end;

constructor TDirectoryTree.Create(aOwner: TComponent);
begin
  inherited;
  fDirectoryDict := TDictionary<NativeUInt, TNodeData>.Create;
  ReadOnly := true;
end;

destructor TDirectoryTree.Destroy;
begin
  fDirectoryDict.Free;
  inherited;
end;

procedure TDirectoryTree.CreateSubNodesToLevel2(aItem: TTreeNode);
var
  DirArraySize1, DirArraySize2, i, j: integer;
  DirArray1, DirArray2: TStringDynArray;
  TreeItem, TreeItem2: TTreeNode;
  NewName: string;
  FileAtr: integer;
  DirectoryCount: integer;
  NodeData, NodeData1: TNodeData;
begin
  if not fDirectoryDict.ContainsKey(NativeUInt(aItem.ItemId)) then
   raise Exception.Create('Node has no directory name');
  if fDirectoryDict[NativeUInt(aItem.ItemId)].HasEnoughSubnodes then
  exit;
  Items.BeginUpdate;
  try
    NodeData.FullPath:=fDirectoryDict[NativeUInt(aItem.ItemId)].FullPath;
    NodeData.HasEnoughSubnodes:=false;
    FileAtr := faHidden + faSysFile + faSymLink;
    DirectoryCount := 0;
    DirArray1 := TDirectory.GetDirectories(GetFullFolderName(aItem),
      function(const path: string; const SearchRec: TSearchRec): Boolean
      begin
        Result := (DirectoryCount < 1001) and (SearchRec.Attr and (not FileAtr)
          = SearchRec.Attr);
        if Result then
          inc(DirectoryCount);
      end);
    DirArraySize1 := Length(DirArray1);
    // ignore directories with more than 1000 entries
    if (DirArraySize1 < 1) or (DirArraySize1 > 1000) then
    begin
      NodeData.HasEnoughSubnodes:=true;
      fDirectoryDict.AddOrSetValue(NativeUInt(aItem.ItemId),NodeData);
      exit;
    end;
    for i := 0 to DirArraySize1 - 1 do
    begin
      NewName := DirArray1[i];
      if aItem.Count <= i then // NewName isn't a node yet
      begin
        TreeItem := Items.AddChild(aItem, ExtractFilename(NewName));
        NodeData1.FullPath:=NewName;
        NodeData1.HasEnoughSubnodes:=False;
        fDirectoryDict.Add(NativeUInt(TreeItem.ItemId), NodeData1);
        TreeItem.ImageIndex := 0;
      end
      else
        TreeItem := aItem.Item[i];
      if TreeItem.Count > 0 then // already filled
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
        NodeData1.FullPath:=NewName;
        NodeData1.HasEnoughSubnodes:=true;
        //Don't expand a folder with more than 1000 subfolders any futher
        fDirectoryDict.AddOrSetValue(NativeUInt(TreeItem.ItemId),NodeData1);
        Continue;
      end;
      for j := 0 to DirArraySize2 - 1 do
      begin
        if TreeItem.Count <= j then
        begin
          TreeItem2 := Items.AddChild(TreeItem, ExtractFilename(DirArray2[j]));
          NodeData1.FullPath:=DirArray2[j];
        NodeData1.HasEnoughSubnodes:=false;
          fDirectoryDict.Add(NativeUInt(TreeItem2.ItemId), NodeData1);
          TreeItem2.ImageIndex := 0;
        end;
      end;
    end;
    NodeData.HasEnoughSubnodes:=true;
    fDirectoryDict.AddOrSetValue(NativeUInt(aItem.ItemId),NodeData);
  finally
    Items.EndUpdate;
  end;
end;

procedure TDirectoryTree.NewRootFolder(const RootFolder: string);
var
  Root: TTreeNode;
  ShortName: string;
  NodeData: TNodeData;
begin
  if not System.SysUtils.DirectoryExists(RootFolder) then
    raise Exception.Create(RootFolder + ' does not exist');
  fDirectoryDict.Clear;
  Items.Clear;
  Items.BeginUpdate;
  try
    ShortName := ExtractFilename(RootFolder);
    if ShortName = '' then
      ShortName := RootFolder;
    Root := Items.AddChild(nil, ShortName);
    NodeData.FullPath:=RootFolder;
    NodeData.HasEnoughSubnodes:=false;
    fDirectoryDict.Add(NativeUInt(Root.ItemId), NodeData);
    Root.ImageIndex := 0;
    CreateSubNodesToLevel2(Root);
  finally
    Items.EndUpdate;
  end;
  Root.Expand(false);
end;

function TDirectoryTree.GetFullFolderName(aNode: TTreeNode): string;
begin
  if not fDirectoryDict.ContainsKey(NativeUInt(aNode.ItemId)) then
    raise Exception.Create('Node has no directory name');
  Result := fDirectoryDict.Items[NativeUInt(aNode.ItemId)].FullPath;
end;

end.
