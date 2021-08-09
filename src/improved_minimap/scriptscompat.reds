// Compatibility script which replaces GetAllBlackboardDefs().UI_ActiveVehicleData.IsPlayerMounted usage
// with GetAllBlackboardDefs().UI_System.IsMounted_IMZ from this mod

@addField(JournalNotificationQueue)
public let m_UIBlackboard_Compat: wref<IBlackboard>;

@replaceMethod(JournalNotificationQueue)
protected cb func OnPlayerAttach(playerPuppet: ref<GameObject>) -> Bool {
  let shardCallback: ref<ShardCollectedInventoryCallback>;
  this.m_journalMgr = GameInstance.GetJournalManager(playerPuppet.GetGame());
  this.m_journalMgr.RegisterScriptCallback(this, n"OnJournalUpdate", gameJournalListenerType.State);
  this.m_journalMgr.RegisterScriptCallback(this, n"OnJournalEntryVisited", gameJournalListenerType.Visited);
  this.m_activeVehicleBlackboard = this.GetBlackboardSystem().Get(GetAllBlackboardDefs().UI_ActiveVehicleData);
  this.m_UIBlackboard_Compat = this.GetBlackboardSystem().Get(GetAllBlackboardDefs().UI_System);
  this.m_mountBBConnectionId = this.m_UIBlackboard_Compat.RegisterListenerBool(GetAllBlackboardDefs().UI_System.IsMounted_IMZ, this, n"OnPlayerMounted");
  this.m_isPlayerMounted = this.m_UIBlackboard_Compat.GetBool(GetAllBlackboardDefs().UI_System.IsMounted_IMZ);
  this.m_playerPuppet = playerPuppet;
  this.m_uiSystem = GameInstance.GetUISystem(playerPuppet.GetGame());
  shardCallback = new ShardCollectedInventoryCallback();
  shardCallback.m_notificationQueue = this;
  shardCallback.m_journalManager = this.m_journalMgr;
  this.m_transactionSystem = GameInstance.GetTransactionSystem(playerPuppet.GetGame());
  this.m_shardTransactionListener = this.m_transactionSystem.RegisterInventoryListener(playerPuppet, shardCallback);
}

@replaceMethod(gameuiCrosshairContainerController)
protected final func RegisterPSMListeners(playerPuppet: ref<GameObject>) -> Void {
  let bbCrosshairInfo: ref<IBlackboard>;
  let uiBlackboard_Compat: wref<IBlackboard>;
  this.m_Player = playerPuppet as PlayerPuppet;
  let playerSMDef: ref<PlayerStateMachineDef> = GetAllBlackboardDefs().PlayerStateMachine;
  if IsDefined(playerSMDef) {
    bbCrosshairInfo = this.GetPSMBlackboard(playerPuppet);
    if IsDefined(bbCrosshairInfo) {
      this.m_crosshairStateBlackboardId = bbCrosshairInfo.RegisterListenerInt(playerSMDef.Crosshair, this, n"OnPSMCrosshairStateChanged");
      this.m_bbPlayerTierEventId = bbCrosshairInfo.RegisterListenerInt(playerSMDef.SceneTier, this, n"OnSceneTierChange");
    };
  };
  if IsDefined(this.m_Player) && this.m_Player.IsControlledByLocalPeer() {
    uiBlackboard_Compat = this.GetBlackboardSystem().Get(GetAllBlackboardDefs().UI_System);
    this.m_isMountedBlackboardId =  uiBlackboard_Compat.RegisterListenerBool(GetAllBlackboardDefs().UI_System.IsMounted_IMZ, this, n"OnMountChanged");
  };
}

@replaceMethod(gameuiCrosshairContainerController)
protected final func UnregisterPSMListeners(playerPuppet: ref<GameObject>) -> Void {
  let bbCrosshairInfo: ref<IBlackboard>;
  let playerSMBB: ref<IBlackboard>;
  let playerSMDef: ref<PlayerStateMachineDef> = GetAllBlackboardDefs().PlayerStateMachine;
  let uiBlackboard_Compat: wref<IBlackboard>;
  if IsDefined(playerSMDef) {
    bbCrosshairInfo = this.GetPSMBlackboard(playerPuppet);
    if IsDefined(bbCrosshairInfo) {
      bbCrosshairInfo.UnregisterListenerInt(playerSMDef.Crosshair, this.m_crosshairStateBlackboardId);
      this.m_crosshairStateBlackboardId = 0u;
      bbCrosshairInfo.UnregisterListenerInt(playerSMDef.SceneTier, this.m_bbPlayerTierEventId);
      this.m_bbPlayerTierEventId = 0u;
    };
  };
  playerSMBB = this.GetPSMBlackboard(playerPuppet);
  if this.m_crosshairStateBlackboardId > 0u {
    playerSMBB.UnregisterDelayedListener(GetAllBlackboardDefs().PlayerStateMachine.Crosshair, this.m_crosshairStateBlackboardId);
    this.m_crosshairStateBlackboardId = 0u;
  };
  if this.m_CombatStateBlackboardId > 0u {
    playerSMBB.UnregisterDelayedListener(GetAllBlackboardDefs().PlayerStateMachine.Combat, this.m_CombatStateBlackboardId);
    this.m_CombatStateBlackboardId = 0u;
  };
  if this.m_isMountedBlackboardId > 0u {
    uiBlackboard_Compat = this.GetBlackboardSystem().Get(GetAllBlackboardDefs().UI_System);
    uiBlackboard_Compat.UnregisterDelayedListener(GetAllBlackboardDefs().UI_System.IsMounted_IMZ, this.m_isMountedBlackboardId);
    this.m_isMountedBlackboardId = 0u;
  };
}