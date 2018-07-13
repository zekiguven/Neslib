unit Neslib.Collections;
{< Generic collections that are faster and more light-weight than Delphi's
   built-in collections. Also adds read-only views for most collections, as well
   as additional collections not found in the RTL. }

{$INCLUDE 'Neslib.inc'}

interface

uses
  System.Types,
  System.Generics.Defaults,
  Neslib.System;

type
  { Various utilities that operate on generic dynamic arrays. Mostly used
    internally by various generic collections. }
  TArray = class // static
  {$REGION 'Internal Declarations'}
  private
    class procedure QuickSort<T>(var AValues: TArray<T>;
      const AComparer: IComparer<T>; L, R: Integer); static;
  {$ENDREGION 'Internal Declarations'}
  public
    { Moves items within an array.

      Parameters:
        AArray: the array
        AFromIndex: the source index into AArray
        AToIndex: the destination index into AArray
        ACount: the number of elements to move.

      You should use this utility instead of System.Move since it correctly
      handles elements with [weak] references.

      @bold(Note): no range checking is performed on the arguments. }
    class procedure Move<T>(var AArray: TArray<T>; const AFromIndex, AToIndex,
      ACount: Integer); overload; static;

    { Moves items from one array to another.

      Parameters:
        AFromArray: the source array
        AFromIndex: the source index into AFromArray
        AToArray: the destination array
        AToIndex: the destination index into AToArray
        ACount: the number of elements to move.

      You should use this utility instead of System.Move since it correctly
      handles elements with [weak] references.

      @bold(Note): no range checking is performed on the arguments. }
    class procedure Move<T>(const AFromArray: TArray<T>; const AFromIndex: Integer;
      var AToArray: TArray<T>; const AToIndex, ACount: Integer); overload; static;

    { Finalizes an element in an array.

      Parameters:
        AArray: the array containing the element to finalize.
        AIndex: the index of the element to finalize.

      You should call this utility to mark an element in an array as "unused".
      This prevents memory problems when the array contains elements that are
      reference counted or contain [weak] references. In those cases, the
      element will be set to all zero's. If the array contains "regular"
      elements, then this method does nothing.

      @bold(Note): no range checking is performed on the arguments. }
    class procedure Finalize<T>(var AArray: TArray<T>;
      const AIndex: Integer); overload; static; inline;

    { Finalizes a range ofelements in an array.

      Parameters:
        AArray: the array containing the elements to finalize.
        AIndex: the index of the first element to finalize.
        ACount: the number of elements to finalize.

      You should call this utility to mark an element in an array as "unused".
      This prevents memory problems when the array contains elements that are
      reference counted or contain [weak] references. In those cases, the
      element will be set to all zero's. If the array contains "regular"
      elements, then this method does nothing.

      @bold(Note): no range checking is performed on the arguments. }
    class procedure Finalize<T>(var AArray: TArray<T>; const AIndex,
      ACount: Integer); overload; static; inline;

    { Sorts an array using the default comparer.

      Parameters:
        AValues: the array to sort. }
    class procedure Sort<T>(var AValues: TArray<T>); overload; static;

    { Sorts an array.

      Parameters:
        AValues: the array to sort.
        AComparer: the comparer to use to determine sort order.
        AIndex: the start index into the array
        ACount: the number of elements to sort

      Set AIndex to 0 and ACount to Length(AValues) to sort the entire array.

      @bold(Note): no range checking is performed on the arguments. }
    class procedure Sort<T>(var AValues: TArray<T>;
      const AComparer: IComparer<T>; const AIndex, ACount: Integer); overload; static;

    { Searches for an item in a sorted array.

      Parameters:
        AValues: the array to search. This array must be sorted (you can use
          Sort to sort it).
        AItem: the item to search for.
        AFoundIndex: when the array contains AItem, this value is set to the
          index of that item. Otherwise, it is set to the index between the two
          items where AItem would fit.
        AComparer: the comparer to use to determine sort order.
        AIndex: the start index into the array
        ACount: the number of elements to search

      Returns:
        True when AItem is found, or False if not.

      Set AIndex to 0 and ACount to Length(AValues) to search in the entire
      array.

      @bold(Note): no range checking is performed on the arguments. }
    class function BinarySearch<T>(const AValues: TArray<T>; const AItem: T;
      out AFoundIndex: Integer; const AComparer: IComparer<T>;
      const AIndex, ACount: Integer): Boolean; overload; static;
  end;

type
  { Abstract base generic enumerator class. Generic collections have a method
    called GetEnumerator that returns an instance of a class derived from this
    class. This allows for <tt>for..in</tt> enumeration of collections. }
  TEnumerator<T> = class abstract
  {$REGION 'Internal Declarations'}
  protected
    function GetCurrent: T; virtual; abstract;
  {$ENDREGION 'Internal Declarations'}
  public
    { Moves to the next element in the collection.

      Returns:
        True if there is a next element to enumerate. False otherwise. }
    function MoveNext: Boolean; virtual; abstract;

    { The current value of the enumeration }
    property Current: T read GetCurrent;
  end;

type
  { A standard enumerator for enumerating elements in a dynamic array. Lists
    and stacks use this class for their enumerators. }
  TArrayEnumerator<T> = class(TEnumerator<T>)
  {$REGION 'Internal Declarations'}
  private
    FItems: TArray<T>;
    FHigh: Integer;
    FIndex: Integer;
  protected
    function GetCurrent: T; override;
  {$ENDREGION 'Internal Declarations'}
  public
    constructor Create(const AItems: TArray<T>; const ACount: Integer);
    function MoveNext: Boolean; override;
  end;

type
  { Interface for enumerable collections. }
  IEnumerable<T> = interface
    { Copies the elements in the collection to a dynamic array }
    function ToArray: TArray<T>;

    { Returns an enumerator to enumerate over the items in the collection. }
    function GetEnumerator: TEnumerator<T>;
  end;

type
  { Abstract base class for collections that are enumerable. Most collections
    types in this unit are.

    Implements IEnumerable<T>. }
  TEnumerable<T> = class abstract(TRefCounted, IEnumerable<T>)
  public
    { Copies the elements in the collection to a dynamic array }
    function ToArray: TArray<T>; virtual; abstract;

    { Returns an enumerator to enumerate over the items in the collection. }
    function GetEnumerator: TEnumerator<T>; virtual; abstract;
  end;

type
  { A read-only view of a list. }
  IReadOnlyList<T> = interface(IEnumerable<T>)
    {$REGION 'Internal Declarations'}
    function GetCount: Integer;
    function GetItem(const AIndex: Integer): T;
    function GetCapacity: Integer;
    {$ENDREGION 'Internal Declarations'}

    { Checks whether the list contains a given item.
      This method performs a O(n) linear search and uses the list's comparer to
      check for equality. For a faster check, use BinarySearch.

      Parameters:
        AValue: The value to check.

      Returns:
        True if the list contains AValue. }
    function Contains(const AValue: T): Boolean;

    { Returns the index of a given item or -1 if not found.
      This method performs a O(n) linear search and uses the list's comparer to
      check for equality. For a faster check, use BinarySearch.

      Parameters:
        AValue: The value to find. }
    function IndexOf(const AValue: T): Integer;

    { Returns the last index of a given item or -1 if not found.
      This method performs a O(n) backwards linear search and uses the list's
      comparer to check for equality. For a faster check, use BinarySearch.

      Parameters:
        AValue: The value to find. }
    function LastIndexOf(const AValue: T): Integer;

    { Returns the index of a given item or -1 if not found.
      This method performs a O(n) linear search and uses the list's comparer to
      check for equality. For a faster check, use BinarySearch.

      Parameters:
        AValue: The value to find.
        ADirection: Whether to search forwards or backwards. }
    function IndexOfItem(const AValue: T; const ADirection: TDirection): Integer;

    { Performs a binary search for a given item. This requires that the list
      is sorted. This is an O(log n) operation that uses the default comparer to
      check for equality.

      Parameters:
        AItem: The item to find.
        AIndex: is set to the index of AItem if found. If not found, it is set
          to the index of the first entry larger than AItem.

      Returns:
        Whether the list contains the item. }
    function BinarySearch(const AItem: T; out AIndex: Integer): Boolean; overload;

    { Performs a binary search for a given item. This requires that the list
      is sorted. This is an O(log n) operation that uses the given comparer to
      check for equality.

      Parameters:
        AItem: The item to find.
        AIndex: is set to the index of AItem if found. If not found, it is set
          to the index of the first entry larger than AItem.
        AComparer: the comparer to use to check for equality.

      Returns:
        Whether the list contains the item. }
    function BinarySearch(const AItem: T; out AIndex: Integer;
      const AComparer: IComparer<T>): Boolean; overload;

    { Returns the first item in the list. }
    function First: T;

    { Returns the last item in the list. }
    function Last: T;

    { The number of items in the list }
    property Count: Integer read GetCount;

    { The items in the list }
    property Items[const AIndex: Integer]: T read GetItem; default;

    { The number of reserved items in the list. Is >= Count to improve
      performance by reducing memory reallocations. }
    property Capacity: Integer read GetCapacity;
  end;

type
  { Base class for TList<T> and TSortedList<T> }
  TBaseList<T> = class abstract(TEnumerable<T>, IReadOnlyList<T>)
  {$REGION 'Internal Declarations'}
  private
    FItems: TArray<T>;
    FCount: Integer;
    function GetCount: Integer;
    function GetItem(const AIndex: Integer): T; inline;
    function GetCapacity: Integer;
  private
    procedure SetCount(const Value: Integer);
    procedure SetCapacity(const Value: Integer);
  private
    procedure Grow(const AMinCount: Integer);
    procedure GrowCheck; overload; inline;
    procedure GrowCheck(const AMinCount: Integer); overload; inline;
  protected
    procedure ItemAdded(const AItem: T); virtual;
    procedure ItemDeleted(const AItem: T); virtual;
  {$ENDREGION 'Internal Declarations'}
  public
    { IEnumerable<T> }

    { Copies the elements in the list to a dynamic array }
    function ToArray: TArray<T>; override; final;

    { Allow <tt>for..in</tt> enumeration of the list. }
    function GetEnumerator: TEnumerator<T>; override;
  public
    { Checks whether the list contains a given item.
      This method performs a O(n) linear search and uses the list's comparer to
      check for equality. For a faster check, use BinarySearch.

      Parameters:
        AValue: The value to check.

      Returns:
        True if the list contains AValue. }
    function Contains(const AValue: T): Boolean;

    { Returns the index of a given item or -1 if not found.
      This method performs a O(n) linear search and uses the list's comparer to
      check for equality. For a faster check, use BinarySearch.

      Parameters:
        AValue: The value to find. }
    function IndexOf(const AValue: T): Integer;

    { Returns the last index of a given item or -1 if not found.
      This method performs a O(n) backwards linear search and uses the list's
      comparer to check for equality. For a faster check, use BinarySearch.

      Parameters:
        AValue: The value to find. }
    function LastIndexOf(const AValue: T): Integer;

    { Returns the index of a given item or -1 if not found.
      This method performs a O(n) linear search and uses the list's comparer to
      check for equality. For a faster check, use BinarySearch.

      Parameters:
        AValue: The value to find.
        ADirection: Whether to search forwards or backwards. }
    function IndexOfItem(const AValue: T; const ADirection: TDirection): Integer;

    { Performs a binary search for a given item. This requires that the list
      is sorted. This is an O(log n) operation that uses the default comparer to
      check for equality.

      Parameters:
        AItem: The item to find.
        AIndex: is set to the index of AItem if found. If not found, it is set
          to the index of the first entry larger than AItem.

      Returns:
        Whether the list contains the item. }
    function BinarySearch(const AItem: T; out AIndex: Integer): Boolean; overload;

    { Performs a binary search for a given item. This requires that the list
      is sorted. This is an O(log n) operation that uses the given comparer to
      check for equality.

      Parameters:
        AItem: The item to find.
        AIndex: is set to the index of AItem if found. If not found, it is set
          to the index of the first entry larger than AItem.
        AComparer: the comparer to use to check for equality.

      Returns:
        Whether the list contains the item. }
    function BinarySearch(const AItem: T; out AIndex: Integer;
      const AComparer: IComparer<T>): Boolean; overload;

    { Returns the first item in the list. }
    function First: T;

    { Returns the last item in the list. }
    function Last: T;

    { Clears the list }
    procedure Clear; virtual;

    { Deletes an item from the list.

      Parameters:
        AIndex: the index of the item to delete }
    procedure Delete(const AIndex: Integer);

    { Deletes a range of items from the list.

      Parameters:
        AIndex: the index of the first item to delete
        ACount: the number of items to delete }
    procedure DeleteRange(const AIndex, ACount: Integer);

    { Removes an item from the list.

      Parameters:
        AValue: the value of the item to remove. It this list does not contain
          this item, nothing happens.

      Returns:
        The index of the removed item, or -1 of the list does not contain
        AValue.

      If the list contains multiple items with the same value, only the first
      item is removed. }
    function Remove(const AValue: T): Integer;

    { Removes an item from the list, starting from the beginning or end.

      Parameters:
        AValue: the value of the item to remove. It this list does not contain
          this item, nothing happens.
        ADirection: the direction to search for the item (from the beginning or
          the end)

      Returns:
        The index of the removed item (given ADirection), or -1 of the list does
        not contain AValue.

      If the list contains multiple items with the same value, only the first
      (or last) item is removed. }
    function RemoveItem(const AValue: T; const ADirection: TDirection): Integer;

    { Trims excess memory used by the list. To improve performance and reduce
      memory reallocations, the list usually contains space for more items than
      are actually stored in this list. That is, Capacity >= Count. Call this
      method free that excess memory. You can do this when you are done filling
      the list to free memory. }
    procedure TrimExcess;

    { The number of items in the list }
    property Count: Integer read FCount write SetCount;
    { The items in the list }

    property Items[const AIndex: Integer]: T read GetItem; default;

    { The number of reserved items in the list. Is >= Count to improve
      performance by reducing memory reallocations. }
    property Capacity: Integer read GetCapacity write SetCapacity;
  end;

type
  { Generic list. Similar to Delphi's TList<T> }
  TList<T> = class(TBaseList<T>)
  {$REGION 'Internal Declarations'}
  protected
    function GetItem(const AIndex: Integer): T; inline;
    procedure SetItem(const AIndex: Integer; const Value: T);
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates an empty list }
    constructor Create; overload;

    { Creates a list with the contents of another collection

      Parameters:
        ACollection: the collection containing the items to add. Can be any
          class that descends from TEnumerable<T>. }
    constructor Create(const ACollection: TEnumerable<T>); overload;

    { Adds an item to the end of the list.

      Parameters:
        AValue: the item to add.

      Returns:
        The index of the added item. }
    function Add(const AValue: T): Integer;

    { Adds a range of items to the end of the list.

      Parameters:
        AValues: an array of items to add. }
    procedure AddRange(const AValues: array of T); overload;

    { Adds the items of another collection to the end of the list.

      Parameters:
        ACollection: the collection containing the items to add. Can be any
          class that descends from TEnumerable<T>. }
    procedure AddRange(const ACollection: TEnumerable<T>); overload; inline;

    { Inserts an item into the list.

      Parameters:
        AIndex: the index in the list to insert the item. The item will be
          inserted before AIndex. Set to 0 to insert at the beginning to the
          list. Set to Count to add to the end of the list.
        AValue: the item to insert. }
    procedure Insert(const AIndex: Integer; const AValue: T);

    { Inserts a range of items into the list.

      Parameters:
        AIndex: the index in the list to insert the items. The items will be
          inserted before AIndex. Set to 0 to insert at the beginning to the
          list. Set to Count to add to the end of the list.
        AValues: the items to insert. }
    procedure InsertRange(const AIndex: Integer; const AValues: array of T); overload;

    { Inserts the items from another collection into the list.

      Parameters:
        AIndex: the index in the list to insert the items. The items will be
          inserted before AIndex. Set to 0 to insert at the beginning to the
          list. Set to Count to add to the end of the list.
        ACollection: the collection containing the items to insert. Can be any
          class that descends from TEnumerable<T>. }
    procedure InsertRange(const AIndex: Integer; const ACollection: TEnumerable<T>); overload;

    { Swaps to elements in the list.

      Parameters:
        AIndex: the index of the first element to swap
        AIndex: the index of the last element to swap }
    procedure Exchange(const AIndex1, AIndex2: Integer);

    { Moves an element in the list to a different location.

      Parameters:
        ACurIndex: the index of the element to move.
        ANewIndex: the new index for the element. }
    procedure Move(const ACurIndex, ANewIndex: Integer);

    { Reverses the order of the elements in the list. }
    procedure Reverse;

    { Sort the list using the default comparer for the element type }
    procedure Sort; overload;

    { Sort the list using a custom comparer.

      Parameters:
        AComparer: the comparer to use to sort the list. }
    procedure Sort(const AComparer: IComparer<T>); overload;

    { The items in the list }
    property Items[const AIndex: Integer]: T read GetItem write SetItem; default;
  end;

type
  { Generic sorted list. Adding and removing items will keep the list in a
    sorted state. }
  TSortedList<T> = class(TBaseList<T>)
  {$REGION 'Internal Declarations'}
  private
    FComparer: IComparer<T>;
    FDuplicates: TDuplicates;
  protected
    function GetItem(const AIndex: Integer): T; inline;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates an empty list, using the default comparer for sorting. }
    constructor Create; overload;

    { Creates an empty list, using a given comparer for sorting.

      Parameters:
        AComparer: the comparer to use for sorting. }
    constructor Create(const AComparer: IComparer<T>); overload;

    { Creates a list with the contents of another collection. It uses the
      default comparer for sorting.

      Parameters:
        ACollection: the collection containing the items to add. Can be any
          class that descends from TEnumerable<T>. }
    constructor Create(const ACollection: TEnumerable<T>); overload;

    { Creates a list with the contents of another collection and a given
      comparer for sorting.

      Parameters:
        AComparer: the comparer to use for sorting.
        ACollection: the collection containing the items to add. Can be any
          class that descends from TEnumerable<T>. }
    constructor Create(const AComparer: IComparer<T>;
      const ACollection: TEnumerable<T>); overload;

    { Adds an item to the list in sorted order.

      Parameters:
        AValue: the item to add.

      Returns:
        The index of the added item. }
    function Add(const AValue: T): Integer;

    { Adds a range of items to the list in sorted order.

      Parameters:
        AValues: an array of items to add. }
    procedure AddRange(const AValues: array of T); overload;

    { Adds the items of another collection to the list in sorted order.

      Parameters:
        ACollection: the collection containing the items to add. Can be any
          class that descends from TEnumerable<T>. }
    procedure AddRange(const ACollection: TEnumerable<T>); overload; inline;

    { How duplicates should be handled:
      * dupIgnore: (default) duplicates are ignored and not added to the list.
      * dupAccept: duplicates are added to the list.
      * dupError: an exception will be raised when trying to add a duplicate to
          the list. }
    property Duplicates: TDuplicates read FDuplicates write FDuplicates;

    { The items in the list }
    property Items[const AIndex: Integer]: T read GetItem; default;
  end;

type
  { Generic list of TRefCounted objects.
    The list retains strong references to its items. }
  TRCList<T: TRefCounted> = class(TList<T>)
  {$REGION 'Internal Declarations'}
  protected
    procedure ItemAdded(const AItem: T); override;
    procedure ItemDeleted(const AItem: T); override;
  public
    procedure Clear; override;
  {$ENDREGION 'Internal Declarations'}
  end;

type
  { Generic sorted list of TRefCounted objects. }
  TRCSortedList<T: TRefCounted> = class(TSortedList<T>)
  {$REGION 'Internal Declarations'}
  protected
    procedure ItemAdded(const AItem: T); override;
    procedure ItemDeleted(const AItem: T); override;
  public
    procedure Clear; override;
  {$ENDREGION 'Internal Declarations'}
  end;

implementation

uses
  System.SysUtils,
  System.RTLConsts;

{ TArray }

class function TArray.BinarySearch<T>(const AValues: TArray<T>;
  const AItem: T; out AFoundIndex: Integer; const AComparer: IComparer<T>;
  const AIndex, ACount: Integer): Boolean;
var
  L, H: Integer;
  Mid, Cmp: Integer;
begin
  {$IFNDEF NO_RANGE_CHECKS}
  if (AIndex < Low(AValues)) or ((AIndex > High(AValues)) and (ACount > 0))
    or (AIndex + ACount - 1 > High(AValues)) or (ACount < 0)
    or (AIndex + ACount < 0)
  then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  {$ENDIF}

  if (ACount = 0) then
  begin
    AFoundIndex := AIndex;
    Exit(False);
  end;

  Result := False;
  L := AIndex;
  H := AIndex + ACount - 1;
  while (L <= H) do
  begin
    Mid := L + (H - L) shr 1;
    Cmp := AComparer.Compare(AValues[Mid], AItem);
    if (Cmp < 0) then
      L := Mid + 1
    else
    begin
      H := Mid - 1;
      if (Cmp = 0) then
        Result := True;
    end;
  end;
  AFoundIndex := L;
end;

class procedure TArray.Finalize<T>(var AArray: TArray<T>; const AIndex,
  ACount: Integer);
begin
  {$IF Defined(WEAKREF)}
  if System.HasWeakRef(T) then
  begin
    System.Finalize(AArray[AIndex], ACount);
    FillChar(AArray[AIndex], ACount * SizeOf(T), 0);
  end
  else
  {$ENDIF}
  if IsManagedType(T) then
    FillChar(AArray[AIndex], ACount * SizeOf(T), 0);
end;

class procedure TArray.Finalize<T>(var AArray: TArray<T>;
  const AIndex: Integer);
begin
  {$IF Defined(WEAKREF)}
  if System.HasWeakRef(T) then
  begin
    System.Finalize(AArray[AIndex], 1);
    FillChar(AArray[AIndex], SizeOf(T), 0);
  end
  else
  {$ENDIF}
  if IsManagedType(T) then
    FillChar(AArray[AIndex], SizeOf(T), 0);
end;

class procedure TArray.Move<T>(var AArray: TArray<T>; const AFromIndex,
  AToIndex, ACount: Integer);
{$IFDEF WEAKREF}
var
  I: Integer;
{$ENDIF}
begin
  {$IFDEF WEAKREF}
  if System.HasWeakRef(T) then
  begin
    if (ACount > 0) then
    begin
      if (AFromIndex < AToIndex) then
      begin
        for I := ACount - 1 downto 0 do
          AArray[AToIndex + I] := AArray[AFromIndex + I]
      end
      else if (AFromIndex > AToIndex) then
      begin
        for I := 0 to ACount - 1 do
          AArray[AToIndex + I] := AArray[AFromIndex + I];
      end;
    end;
  end
  else
  {$ENDIF}
    System.Move(AArray[AFromIndex], AArray[AToIndex], ACount * SizeOf(T));
end;

class procedure TArray.Move<T>(const AFromArray: TArray<T>;
  const AFromIndex: Integer; var AToArray: TArray<T>; const AToIndex,
  ACount: Integer);
{$IFDEF WEAKREF}
var
  I: Integer;
{$ENDIF}
begin
  {$IFDEF WEAKREF}
  if System.HasWeakRef(T) then
  begin
    for I := 0 to ACount - 1 do
      AToArray[AToIndex + I] := AFromArray[AFromIndex + I];
  end
  else
  {$ENDIF}
    System.Move(AFromArray[AFromIndex], AToArray[AToIndex], ACount * SizeOf(T));
end;

class procedure TArray.QuickSort<T>(var AValues: TArray<T>;
  const AComparer: IComparer<T>; L, R: Integer);
var
  I, J: Integer;
  Pivot, Temp: T;
begin
  if (Length(AValues) = 0) or ((R - L) <= 0) then
    Exit;

  repeat
    I := L;
    J := R;
    Pivot := AValues[L + (R - L) shr 1];
    repeat
      while (AComparer.Compare(AValues[I], Pivot) < 0) do
        Inc(I);

      while (AComparer.Compare(AValues[J], Pivot) > 0) do
        Dec(J);

      if (I <= J) then
      begin
        if (I <> J) then
        begin
          Temp := AValues[I];
          AValues[I] := AValues[J];
          AValues[J] := Temp;
        end;
        Inc(I);
        Dec(J);
      end;
    until (I > J);

    if (L < J) then
      QuickSort(AValues, AComparer, L, J);
    L := I;
  until (I >= R);
end;

class procedure TArray.Sort<T>(var AValues: TArray<T>);
var
  Comparer: IComparer<T>;
begin
  if (Length(AValues) > 1) then
  begin
    Comparer := TComparer<T>.Default;
    QuickSort<T>(AValues, Comparer, 0, Length(AValues) - 1);
  end;
end;

class procedure TArray.Sort<T>(var AValues: TArray<T>;
  const AComparer: IComparer<T>; const AIndex, ACount: Integer);
begin
  if (ACount > 1) then
    QuickSort<T>(AValues, AComparer, AIndex, AIndex + ACount - 1);
end;

{ TArrayEnumerator<T> }

constructor TArrayEnumerator<T>.Create(const AItems: TArray<T>;
  const ACount: Integer);
begin
  inherited Create;
  FItems := AItems;
  FHigh := ACount - 1;
  FIndex := -1;
end;

function TArrayEnumerator<T>.GetCurrent: T;
begin
  Result := FItems[FIndex];
end;

function TArrayEnumerator<T>.MoveNext: Boolean;
begin
  Result := (FIndex < FHigh);
  if Result then
    Inc(FIndex);
end;

{ TBaseList<T> }

function TBaseList<T>.BinarySearch(const AItem: T; out AIndex: Integer;
  const AComparer: IComparer<T>): Boolean;
begin
  Result := TArray.BinarySearch<T>(FItems, AItem, AIndex, AComparer, 0, FCount);
end;

function TBaseList<T>.BinarySearch(const AItem: T;
  out AIndex: Integer): Boolean;
var
  Comparer: IComparer<T>;
begin
  Comparer := TComparer<T>.Default;
  Result := TArray.BinarySearch<T>(FItems, AItem, AIndex, Comparer, 0, FCount);
end;

procedure TBaseList<T>.Clear;
begin
  FItems := nil;
  FCount := 0;
end;

function TBaseList<T>.Contains(const AValue: T): Boolean;
begin
  Result := (IndexOf(AValue) >= 0);
end;

procedure TBaseList<T>.Delete(const AIndex: Integer);
begin
  {$IFNDEF NO_RANGE_CHECKS}
  if (AIndex < 0) or (AIndex >= Count) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  {$ENDIF}

  ItemDeleted(FItems[AIndex]);

  if IsManagedType(T) then
    FItems[AIndex] := Default(T);

  Dec(FCount);
  if (AIndex <> Count) then
  begin
    TArray.Move<T>(FItems, AIndex + 1, AIndex, FCount - AIndex);
    TArray.Finalize<T>(FItems, Count);
  end;
end;

procedure TBaseList<T>.DeleteRange(const AIndex, ACount: Integer);
var
  TailCount, I: Integer;
begin
  {$IFNDEF NO_RANGE_CHECKS}
  if (AIndex < 0) or (ACount < 0) or (AIndex + ACount > FCount)
    or (AIndex + ACount < 0)
  then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  {$ENDIF}

  if (ACount = 0) then
    Exit;

  for I := AIndex to AIndex + ACount - 1 do
  begin
    ItemDeleted(FItems[I]);
    if IsManagedType(T) then
      FItems[I] := Default(T);
  end;

  TailCount := FCount - (AIndex + ACount);
  if (TailCount > 0) then
  begin
    TArray.Move<T>(FItems, AIndex + ACount, AIndex, TailCount);
    TArray.Finalize<T>(FItems, FCount - ACount, ACount);
  end
  else
    TArray.Finalize<T>(FItems, AIndex, ACount);

  Dec(FCount, ACount);
end;

function TBaseList<T>.First: T;
begin
  Result := GetItem(0);
end;

function TBaseList<T>.GetCapacity: Integer;
begin
  Result := Length(FItems);
end;

function TBaseList<T>.GetCount: Integer;
begin
  Result := FCount;
end;

function TBaseList<T>.GetEnumerator: TEnumerator<T>;
begin
  Result := TArrayEnumerator<T>.Create(FItems, FCount);
end;

function TBaseList<T>.GetItem(const AIndex: Integer): T;
begin
  {$IFNDEF NO_RANGE_CHECKS}
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  {$ENDIF}
  Result := FItems[AIndex];
end;

procedure TBaseList<T>.Grow(const AMinCount: Integer);
var
  NewCount: Integer;
begin
  NewCount := Length(FItems);
  if (NewCount = 0) then
    NewCount := AMinCount
  else
  begin
    repeat
      NewCount := NewCount * 2;
      if (NewCount < 0) then
        OutOfMemoryError;
    until (NewCount >= AMinCount);
  end;
  SetCapacity(NewCount);
end;

procedure TBaseList<T>.GrowCheck;
begin
  if (FCount >= Length(FItems)) then
    Grow(FCount + 1);
end;

procedure TBaseList<T>.GrowCheck(const AMinCount: Integer);
begin
  if (AMinCount > Length(FItems)) then
    Grow(AMinCount);
end;

function TBaseList<T>.IndexOf(const AValue: T): Integer;
var
  I: Integer;
  Comparer: IComparer<T>;
begin
  Comparer := TComparer<T>.Default;
  for I := 0 to FCount - 1 do
  begin
    if (Comparer.Compare(FItems[I], AValue) = 0) then
      Exit(I);
  end;
  Result := -1;
end;

function TBaseList<T>.IndexOfItem(const AValue: T;
  const ADirection: TDirection): Integer;
begin
  if (ADirection = TDirection.FromBeginning) then
    Result := IndexOf(AValue)
  else
    Result := LastIndexOf(AValue);
end;

procedure TBaseList<T>.ItemAdded(const AItem: T);
begin
  { No default implementation }
end;

procedure TBaseList<T>.ItemDeleted(const AItem: T);
begin
  { No default implementation }
end;

function TBaseList<T>.Last: T;
begin
  Result := GetItem(FCount - 1);
end;

function TBaseList<T>.LastIndexOf(const AValue: T): Integer;
var
  I: Integer;
  Comparer: IComparer<T>;
begin
  Comparer := TComparer<T>.Default;
  for I := FCount - 1 downto 0 do
  begin
    if (Comparer.Compare(FItems[I], AValue) = 0) then
      Exit(I);
  end;
  Result := -1;
end;

function TBaseList<T>.Remove(const AValue: T): Integer;
begin
  Result := IndexOf(AValue);
  if (Result >= 0) then
    Delete(Result);
end;

function TBaseList<T>.RemoveItem(const AValue: T;
  const ADirection: TDirection): Integer;
begin
  Result := IndexOfItem(AValue, ADirection);
  if (Result >= 0) then
    Delete(Result);
end;

procedure TBaseList<T>.SetCapacity(const Value: Integer);
begin
  if (Value < FCount) then
    SetCount(Value);
  SetLength(FItems, Value);
end;

procedure TBaseList<T>.SetCount(const Value: Integer);
begin
  {$IFNDEF NO_RANGE_CHECKS}
  if (Value < 0) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  {$ENDIF}

  if (Value > Capacity) then
    SetCapacity(Value);

  if (Value < Count) then
    DeleteRange(Value, Count - Value);

  FCount := Value;
end;

function TBaseList<T>.ToArray: TArray<T>;
var
  I: Integer;
begin
  SetLength(Result, FCount);
  if (not IsManagedType(T)) then
    TArray.Move<T>(FItems, 0, Result, 0, FCount)
  else
  begin
    for I := 0 to FCount - 1 do
      Result[I] := FItems[I];
  end;
end;

procedure TBaseList<T>.TrimExcess;
begin
  SetCapacity(FCount);
end;

{ TList<T> }

function TList<T>.Add(const AValue: T): Integer;
begin
  GrowCheck;
  Result := FCount;
  FItems[FCount] := AValue;
  Inc(FCount);
  ItemAdded(AValue);
end;

procedure TList<T>.AddRange(const AValues: array of T);
begin
  InsertRange(FCount, AValues);
end;

procedure TList<T>.AddRange(const ACollection: TEnumerable<T>);
begin
  InsertRange(FCount, ACollection);
end;

constructor TList<T>.Create;
begin
  inherited Create;
end;

constructor TList<T>.Create(const ACollection: TEnumerable<T>);
begin
  inherited Create;
  InsertRange(0, ACollection);
end;

procedure TList<T>.Exchange(const AIndex1, AIndex2: Integer);
var
  Temp: T;
begin
  Temp := FItems[AIndex1];
  FItems[AIndex1] := FItems[AIndex2];
  FItems[AIndex2] := Temp;
end;

function TList<T>.GetItem(const AIndex: Integer): T;
begin
  {$IFNDEF NO_RANGE_CHECKS}
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  {$ENDIF}
  Result := FItems[AIndex];
end;

procedure TList<T>.Insert(const AIndex: Integer; const AValue: T);
begin
  {$IFNDEF NO_RANGE_CHECKS}
  if (AIndex < 0) or (AIndex > FCount) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  {$ENDIF}

  GrowCheck;
  if (AIndex <> Count) then
  begin
    TArray.Move<T>(FItems, AIndex, AIndex + 1, FCount - AIndex);
    TArray.Finalize<T>(FItems, AIndex);
  end;
  FItems[AIndex] := AValue;
  Inc(FCount);
  ItemAdded(AValue);
end;

procedure TList<T>.InsertRange(const AIndex: Integer;
  const AValues: array of T);
var
  I: Integer;
begin
  {$IFNDEF NO_RANGE_CHECKS}
  if (AIndex < 0) or (AIndex > Count) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  {$ENDIF}

  GrowCheck(FCount + Length(AValues));
  if (AIndex <> Count) then
  begin
    TArray.Move<T>(FItems, AIndex, AIndex + Length(AValues), FCount - AIndex);
    TArray.Finalize<T>(FItems, AIndex, Length(AValues));
  end;

  for I := 0 to Length(AValues) - 1 do
  begin
    FItems[AIndex + I] := AValues[I];
    ItemAdded(AValues[I]);
  end;

  Inc(FCount, Length(AValues));
end;

procedure TList<T>.InsertRange(const AIndex: Integer;
  const ACollection: TEnumerable<T>);
var
  Item: T;
  Index: Integer;
begin
  Index := AIndex;
  for Item in ACollection do
  begin
    Insert(Index, Item);
    Inc(Index);
  end;
end;

procedure TList<T>.Move(const ACurIndex, ANewIndex: Integer);
var
  Temp: T;
begin
  if (ACurIndex = ANewIndex) then
    Exit;

  {$IFNDEF NO_RANGE_CHECKS}
  if (ANewIndex < 0) or (ANewIndex >= FCount) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  {$ENDIF}

  Temp := FItems[ACurIndex];
  FItems[ACurIndex] := Default(T);
  if (ACurIndex < ANewIndex) then
    TArray.Move<T>(FItems, ACurIndex + 1, ACurIndex, ANewIndex - ACurIndex)
  else
    TArray.Move<T>(FItems, ANewIndex, ANewIndex + 1, ACurIndex - ANewIndex);

  TArray.Finalize<T>(FItems, ANewIndex);
  FItems[ANewIndex] := Temp;
end;

procedure TList<T>.Reverse;
var
  Temp: T;
  B, E: Integer;
begin
  B := 0;
  E := FCount - 1;
  while (B < E) do
  begin
    Temp := FItems[B];
    FItems[B] := FItems[E];
    FItems[E] := Temp;
    Inc(B);
    Dec(E);
  end;
end;

procedure TList<T>.SetItem(const AIndex: Integer; const Value: T);
var
  Orig: T;
begin
  {$IFNDEF NO_RANGE_CHECKS}
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  {$ENDIF}

  Orig := FItems[AIndex];
  FItems[AIndex] := Value;

  ItemAdded(Value);
  ItemDeleted(Orig);
end;

procedure TList<T>.Sort;
var
  Comparer: IComparer<T>;
begin
  Comparer := TComparer<T>.Default;
  TArray.Sort<T>(FItems, Comparer, 0, FCount);
end;

procedure TList<T>.Sort(const AComparer: IComparer<T>);
begin
  TArray.Sort<T>(FItems, AComparer, 0, Count);
end;

{ TSortedList<T> }

function TSortedList<T>.Add(const AValue: T): Integer;
begin
  if (BinarySearch(AValue, Result, FComparer)) then
  begin
    case FDuplicates of
      dupIgnore:
        Exit;

      dupError:
        raise EListError.CreateRes(@SGenericDuplicateItem);
    end;
  end;
  Assert((Result >= 0) and (Result <= FCount));

  GrowCheck;
  if (Result <> Count) then
  begin
    TArray.Move<T>(FItems, Result, Result + 1, FCount - Result);
    TArray.Finalize<T>(FItems, Result);
  end;
  FItems[Result] := AValue;
  Inc(FCount);
  ItemAdded(AValue);
end;

procedure TSortedList<T>.AddRange(const AValues: array of T);
var
  I: Integer;
begin
  GrowCheck(FCount + Length(AValues));
  for I := 0 to Length(AValues) - 1 do
    Add(AValues[I]);
end;

procedure TSortedList<T>.AddRange(const ACollection: TEnumerable<T>);
var
  Item: T;
begin
  for Item in ACollection do
    Add(Item);
end;

constructor TSortedList<T>.Create;
begin
  inherited Create;
  FComparer := TComparer<T>.Default;
end;

constructor TSortedList<T>.Create(const ACollection: TEnumerable<T>);
begin
  inherited Create;
  FComparer := TComparer<T>.Default;
  AddRange(ACollection);
end;

constructor TSortedList<T>.Create(const AComparer: IComparer<T>;
  const ACollection: TEnumerable<T>);
begin
  inherited Create;
  FComparer := AComparer;
  AddRange(ACollection);
end;

constructor TSortedList<T>.Create(const AComparer: IComparer<T>);
begin
  inherited Create;
  FComparer := AComparer;
end;

function TSortedList<T>.GetItem(const AIndex: Integer): T;
begin
  {$IFNDEF NO_RANGE_CHECKS}
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  {$ENDIF}
  Result := FItems[AIndex];
end;

{ TRCList<T> }

procedure TRCList<T>.Clear;
var
  I: Integer;
begin
  for I := 0 to FCount - 1 do
    FItems[I].Release;
  inherited;
end;

procedure TRCList<T>.ItemAdded(const AItem: T);
begin
  AItem.Retain;
end;

procedure TRCList<T>.ItemDeleted(const AItem: T);
begin
  AItem.Release;
end;

{ TRCSortedList<T> }

procedure TRCSortedList<T>.Clear;
var
  I: Integer;
begin
  for I := 0 to FCount - 1 do
    FItems[I].Release;
  inherited;
end;

procedure TRCSortedList<T>.ItemAdded(const AItem: T);
begin
  AItem.Retain;
end;

procedure TRCSortedList<T>.ItemDeleted(const AItem: T);
begin
  AItem.Release;
end;

end.