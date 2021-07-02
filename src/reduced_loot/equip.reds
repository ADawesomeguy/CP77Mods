import ReducedLootTypes.RL_LootSource
import ReducedLootDeclarations.*
import ReducedLootUtils.*

@replaceMethod(ScriptedPuppet)
public final static func ProcessLoot(self: wref<ScriptedPuppet>) -> Void {
  let ammoAmount: Int32;
  let ammoToDrop: array<TweakDBID>;
  let blockRequest: ref<BlockAmmoDrop>;
  let i: Int32;
  let inventory: array<wref<gameItemData>>;
  let isBroken: Bool;
  let itemTDBID: TweakDBID;
  let lootModifiers: array<ref<gameStatModifierData>>;
  let rand: Float;
  let tempStat: Float;
  let TS: ref<TransactionSystem> = GameInstance.GetTransactionSystem(self.GetGame());
  let record: wref<Character_Record> = TweakDBInterface.GetCharacterRecord(self.GetRecordID());
  let canDropWeapon: Bool = record.DropsWeaponOnDeath();
  let canDropAmmo: Bool = record.DropsAmmoOnDeath();
  let dropMoney: Bool = record.DropsMoneyOnDeath();
  let foundEquipment: array<ref<gameItemData>> = ScriptedPuppet.GetEquipment(self);
  let heldMoney: Int32 = TS.GetItemQuantity(self, MarketSystem.Money());
  let itemData: ref<gameItemData>;
  ScriptedPuppet.GenerateLootModifiers(self, lootModifiers);
  self.GenerateLootWithStats(lootModifiers);
  if self.IsLooted() {
    return ;
  };
  if self.IsCrowd() {
    return ;
  };
  if dropMoney {
    TS.GiveItem(self, MarketSystem.Money(), heldMoney);
  };
  if canDropWeapon {
    i = 0;
    while i < ArraySize(foundEquipment) {
      RPGManager.SetDroppedWeaponQuality(self, foundEquipment[i]);
      isBroken = RPGManager.BreakItem(self.GetGame(), self, foundEquipment[i].GetID());
      if !isBroken {
        RLog("> Held weapon check #1:");
        itemData = foundEquipment[i];
        if RL_Utils.IsWeapon(itemData) && RL_Checker.CanLootThis(itemData, RL_LootSource.Held) {
          foundEquipment[i].SetShouldKeep_RL();
          RLog("+ kept held weapon " + UIItemsHelper.GetItemTypeKey(itemData.GetItemType()) + " " + UIItemsHelper.QualityEnumToString(RPGManager.GetItemDataQuality(itemData)));
        } else {
          RLog("- removed held weapon " + UIItemsHelper.GetItemTypeKey(itemData.GetItemType()) + " " + UIItemsHelper.QualityEnumToString(RPGManager.GetItemDataQuality(itemData)));
        };
        ScriptedPuppet.ScaleDroppedItem(foundEquipment[i], self);
        TS.GiveItemByItemData(self, foundEquipment[i]);
      };
      i += 1;
    };
  };
  if canDropAmmo {
    ammoToDrop = PlayerHandicapSystem.GetInstance(self).GetHandicapAmmo();
    if ArraySize(ammoToDrop) > 0 {
      blockRequest = new BlockAmmoDrop();
      PlayerHandicapSystem.GetInstance(self).QueueRequest(blockRequest);
    };
    i = 0;
    while i < ArraySize(foundEquipment) {
      itemTDBID = RPGManager.GetWeaponAmmoTDBID(foundEquipment[i].GetID());
      if TDBID.IsValid(itemTDBID) {
        ArrayPush(ammoToDrop, itemTDBID);
      };
      i += 1;
    };
    i = 0;
    while i < ArraySize(ammoToDrop) {
      switch ammoToDrop[i] {
        case t"Ammo.SniperRifleAmmo":
          ammoAmount = RandRange(5, 20);
          break;
        case t"Ammo.HandgunAmmo":
          ammoAmount = RandRange(20, 40);
          break;
        case t"Ammo.RifleAmmo":
          ammoAmount = RandRange(30, 60);
          break;
        case t"Ammo.ShotgunAmmo":
          ammoAmount = RandRange(10, 25);
          break;
        default:
          ammoAmount = 0;
      };
      if ammoAmount > 0 {
        RLog("> Ammo check #1:");
        if RL_Checker.CanDropAmmo(RL_LootSource.Puppet) {
          RLog("+ ammo dropped: " + IntToString(ammoAmount));
          TS.GiveItemByTDBID(self, ammoToDrop[i], ammoAmount);
          self.DropAmmo();
        } else {
          RLog("- ammo removed: " + IntToString(ammoAmount));
        };
      };
      i += 1;
    };
  };
  if Equals(record.CharacterType().Type(), gamedataNPCType.Human) && self.IsHostile() {
    ScriptedPuppet.ProcessSupportiveItems(self);
  };
  if ScriptedPuppet.IsMechanical(self) {
    rand = RandF();
    tempStat = GameInstance.GetStatsSystem(self.GetGame()).GetStatValue(Cast(GetPlayer(self.GetGame()).GetEntityID()), gamedataStatType.ScrapItemChance);
    if tempStat >= rand {
      GameInstance.GetTransactionSystem(self.GetGame()).GiveItemByItemQuery(self, t"Query.GrenadeNoFaction", 1u, 1u);
    };
  };
  if ScriptedPuppet.HasLootableItems(self) {
    ScriptedPuppet.EvaluateLootQuality(self);
  };
  self.CacheLootForDroping();
}

@replaceMethod(ScriptedPuppet)
public final static func DropHeldItems(self: wref<ScriptedPuppet>) -> Bool {
  let canDrop: Bool;
  let canLeftItemDrop: Bool;
  let canRightItemDrop: Bool;
  let isBroken: Bool;
  let leftItem: wref<ItemObject>;
  let result: Bool;
  let rightItem: wref<ItemObject>;
  let slot: TweakDBID;
  if !IsDefined(self) {
    return false;
  };
  canDrop = TweakDBInterface.GetCharacterRecord(self.GetRecordID()).DropsWeaponOnDeath();
  if canDrop {
    slot = t"AttachmentSlots.WeaponRight";
    rightItem = GameInstance.GetTransactionSystem(self.GetGame()).GetItemInSlot(self, slot);
    canRightItemDrop = IsDefined(rightItem) && IsNameValid(TweakDBInterface.GetItemRecord(ItemID.GetTDBID(rightItem.GetItemID())).DropObject());
    slot = t"AttachmentSlots.WeaponLeft";
    leftItem = GameInstance.GetTransactionSystem(self.GetGame()).GetItemInSlot(self, slot);
    canLeftItemDrop = IsDefined(leftItem) && IsNameValid(TweakDBInterface.GetItemRecord(ItemID.GetTDBID(leftItem.GetItemID())).DropObject());
    if canLeftItemDrop || canRightItemDrop {
      // Prevent world drop removal
      RLog("> Held weapon check #2:");
      if IsDefined(rightItem) && RL_Checker.CanLootThis(rightItem.GetItemData(), RL_LootSource.Held) {
        RLog("+ kept held weapon " + UIItemsHelper.GetItemTypeKey(rightItem.GetItemData().GetItemType()) + " " + UIItemsHelper.QualityEnumToString(RPGManager.GetItemDataQuality(rightItem.GetItemData())));
        rightItem.GetItemData().SetShouldKeep_RL();
      } else {
        RLog("- removed held weapon " + UIItemsHelper.GetItemTypeKey(rightItem.GetItemData().GetItemType()) + " " + UIItemsHelper.QualityEnumToString(RPGManager.GetItemDataQuality(rightItem.GetItemData())));
      };
      if IsDefined(leftItem) && RL_Checker.CanLootThis(leftItem.GetItemData(), RL_LootSource.Held) {
        RLog("+ kept held weapon " + UIItemsHelper.GetItemTypeKey(leftItem.GetItemData().GetItemType()) + " " + UIItemsHelper.QualityEnumToString(RPGManager.GetItemDataQuality(leftItem.GetItemData())));
        leftItem.GetItemData().SetShouldKeep_RL();
      } else {
        RLog("- removed held weapon " + UIItemsHelper.GetItemTypeKey(leftItem.GetItemData().GetItemType()) + " " + UIItemsHelper.QualityEnumToString(RPGManager.GetItemDataQuality(leftItem.GetItemData())));
      };
      self.DropWeapons();
      if IsDefined(rightItem) {
        ScriptedPuppet.ScaleDroppedItem(rightItem.GetItemData(), self);
        result = true;
      };
      if IsDefined(leftItem) {
        ScriptedPuppet.ScaleDroppedItem(leftItem.GetItemData(), self);
        result = true;
      };
      return true;
    };
    return false;
  };
  return false;
}

@replaceMethod(ScriptedPuppet)
public final static func DropItemFromSlot(obj: wref<GameObject>, slot: TweakDBID) -> Void {
  let item: wref<ItemObject>;
  let itemInSlotID: ItemID;
  if !IsDefined(obj) {
    return ;
  };
  item = GameInstance.GetTransactionSystem(obj.GetGame()).GetItemInSlot(obj, slot);
  if IsDefined(item) {
    itemInSlotID = item.GetItemData().GetID();
  };
  if IsDefined(item) && NotEquals(RPGManager.GetItemType(itemInSlotID), gamedataItemType.Wea_Fists) && NotEquals(RPGManager.GetItemType(itemInSlotID), gamedataItemType.Cyb_StrongArms) && NotEquals(RPGManager.GetItemType(itemInSlotID), gamedataItemType.Cyb_MantisBlades) && NotEquals(RPGManager.GetItemType(itemInSlotID), gamedataItemType.Cyb_NanoWires) {
    RLog("> Held weapon check #3:");
    if RL_Checker.CanLootThis(item.GetItemData(), RL_LootSource.Held) {
      RLog("+ kept held weapon " + UIItemsHelper.GetItemTypeKey(item.GetItemData().GetItemType()) + " " + UIItemsHelper.QualityEnumToString(RPGManager.GetItemDataQuality(item.GetItemData())));
      item.GetItemData().SetShouldKeep_RL();
    } else {
      RLog("+ removed held weapon " + UIItemsHelper.GetItemTypeKey(item.GetItemData().GetItemType()) + " " + UIItemsHelper.QualityEnumToString(RPGManager.GetItemDataQuality(item.GetItemData())));
    };
    (obj as ScriptedPuppet).DropWeapons();
  };
}

@replaceMethod(ScriptedPuppet)
public final static func DropWeaponFromSlot(obj: wref<GameObject>, slot: TweakDBID) -> Void {
  let isBroken: Bool;
  let item: wref<ItemObject>;
  if !IsDefined(obj) {
    return ;
  };
  item = GameInstance.GetTransactionSystem(obj.GetGame()).GetItemInSlot(obj, slot);
  if IsDefined(item) {
    isBroken = RPGManager.BreakItem(obj.GetGame(), obj, item.GetItemID());
    if !isBroken {
      RLog("> Held weapon check #4:");
      if RL_Checker.CanLootThis(item.GetItemData(), RL_LootSource.Held) {
        RLog("+ kept held weapon " + UIItemsHelper.GetItemTypeKey(item.GetItemData().GetItemType()) + " " + UIItemsHelper.QualityEnumToString(RPGManager.GetItemDataQuality(item.GetItemData())));
        item.GetItemData().SetShouldKeep_RL();
      } else {
        RLog("+ removed held weapon " + UIItemsHelper.GetItemTypeKey(item.GetItemData().GetItemType()) + " " + UIItemsHelper.QualityEnumToString(RPGManager.GetItemDataQuality(item.GetItemData())));
      };
      (obj as ScriptedPuppet).DropWeapons();
    };
  };
}

// hack to remove extra added ammo
@replaceMethod(ScriptedPuppet)
protected cb func OnItemAddedEvent(evt: ref<ItemAddedEvent>) -> Bool {
  let data: ref<gameItemData> = evt.itemData;
  let transactionSystem: ref<TransactionSystem>;
  let quality: gamedataQuality;

  if RL_Utils.IsAmmo(data) {
    RLog("> Ammo check #2:");
    if RL_Checker.CanDropAmmo(RL_LootSource.Puppet) {
      RLog("+ ammo dropped: " + IntToString(data.GetQuantity()));
    } else {
      RLog("- ammo removed: " + IntToString(data.GetQuantity()));
      transactionSystem = GameInstance.GetTransactionSystem(this.GetGame());
      transactionSystem.RemoveItem(this, data.GetID(), data.GetQuantity());
    };
  };

  if this.HasValidLootQuality() {
    quality = this.m_lootQuality;
    this.EvaluateLootQuality();
    if NotEquals(quality, this.m_lootQuality) {
      this.RequestHUDRefresh();
    };
  };
}