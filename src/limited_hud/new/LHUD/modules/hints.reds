import LimitedHudConfig.HintsModuleConfig
import LimitedHudCommon.LHUDEvent

@addMethod(InputHintManagerGameController)
protected cb func OnLHUDEvent(evt: ref<LHUDEvent>) -> Void {
  this.ConsumeEvent(evt);
  this.DetermineCurrentVisibility();
}

@addMethod(InputHintManagerGameController)
public func DetermineCurrentVisibility() -> Void {
  if !HintsModuleConfig.IsEnabled() {
    return ;
  };

  if this.lhud_isBraindanceActive {
    this.lhud_isVisibleNow = false;
    this.GetRootWidget().SetVisible(false);
    return ;
  };

  let showForGlobalHotkey: Bool = this.lhud_isGlobalFlagToggled && HintsModuleConfig.BindToGlobalHotkey();
  let showForCombat: Bool = this.lhud_isCombatActive && HintsModuleConfig.ShowInCombat();
  let showForOutOfCombat: Bool = this.lhud_isOutOfCombatActive && HintsModuleConfig.ShowOutOfCombat();
  let showForStealth: Bool =  this.lhud_isStealthActive && HintsModuleConfig.ShowInStealth();
  let showForVehicle: Bool =  this.lhud_isInVehicle && HintsModuleConfig.ShowInVehicle();
  let showForWeapon: Bool = this.lhud_isWeaponUnsheathed && !this.lhud_isCombatActive && HintsModuleConfig.ShowWithWeapon();
  let showForZoom: Bool =  this.lhud_isZoomActive && HintsModuleConfig.ShowWithZoom();

  let isVisible: Bool = showForGlobalHotkey || showForCombat || showForOutOfCombat || showForStealth || showForVehicle || showForWeapon || showForZoom;
  if NotEquals(this.lhud_isVisibleNow, isVisible) {
    this.lhud_isVisibleNow = isVisible;
    if isVisible {
      this.AnimateAlpha(this.GetRootWidget(), 1.0, 0.3);
    } else {
      this.AnimateAlpha(this.GetRootWidget(), 0.0, 0.3);
    };
  };
}

@addMethod(InputHintManagerGameController)
protected cb func OnInitialize() -> Bool {
  if HintsModuleConfig.IsEnabled() {
    this.lhud_isVisibleNow = false;
    this.GetRootWidget().SetOpacity(0.0);
    this.OnInitializeFinished();
  };
}