module HUDrag.HUDWidgetsManager

// Widgets and order:
// - NewMinimap - Minimap
// - NewTracker - Quest tracker
// - NewWanted - Wanted bar
// - NewNotifications - Notifications area
// - NewVehicleSummon - Vehicle summon
// - NewWeaponCrouch - Ammo counter and Crouch indicator
// - NewDpad - Dpad hint
// - NewHealthBar - Player healthbar
// - NewStaminaBar - Stamina
// - NewPhoneAvatar - Phone call avatar
// - NewPhoneControl - Phone call input control
// - NewInputHint - Input hints

@addField(PlayerPuppet)
public let hudWidgetsManager: ref<HUDWidgetsManager>;

@addField(AllBlackboardDefinitions)
public let hudWidgetsManager: wref<HUDWidgetsManager>;

public class HUDWidgetsManager {

  public let gameInstance: GameInstance;
  public let puppetId: EntityID;
  public let isActive: Bool;
  public let activeWidget: CName;

  private func Initialize(gameInstance: GameInstance, puppetId: EntityID, hudGameController: ref<inkGameController>) {
    this.gameInstance = gameInstance;
    this.puppetId = puppetId;
    this.SetHUDEditorListener(hudGameController);
  }

  public static func CreateInstance(puppet: ref<gamePuppet>, hudGameController: ref<inkGameController>) {
    let instance: ref<HUDWidgetsManager> = new HUDWidgetsManager();
    let gameInstance = puppet.GetGame();
    let puppetEntityId = puppet.GetEntityID();

    instance.Initialize(gameInstance, puppetEntityId, hudGameController);

    let player = GetPlayer(gameInstance);
    player.hudWidgetsManager = instance;
    GetAllBlackboardDefs().hudWidgetsManager = instance;
  }

  public static func GetInstance() -> wref<HUDWidgetsManager> {
    return GetAllBlackboardDefs().hudWidgetsManager;
  }

  public func GetPlayerPuppet() -> wref<PlayerPuppet> {
    return GameInstance.FindEntityByID(this.gameInstance, this.puppetId) as PlayerPuppet;
  }

  public static func GetNextWidget(widgetName: CName) -> CName {
    switch widgetName {
      case n"NewMinimap": return n"NewTracker";
      case n"NewTracker": return n"NewWanted";
      case n"NewWanted": return n"NewNotifications";
      case n"NewNotifications": return n"NewVehicleSummon";
      case n"NewVehicleSummon": return n"NewWeaponCrouch";
      case n"NewWeaponCrouch": return n"NewDpad";
      case n"NewDpad": return n"NewHealthBar";
      case n"NewHealthBar": return n"NewStaminaBar";
      case n"NewStaminaBar": return n"NewPhoneAvatar";
      case n"NewPhoneAvatar": return n"NewPhoneControl";
      case n"NewPhoneControl": return n"NewInputHint";
      default: return n"NewMinimap"; 
    };
  }

  public static func GetPreviousWidget(widgetName: CName) -> CName {
    switch widgetName {
      case n"NewInputHint": return n"NewPhoneControl";
      case n"NewPhoneControl": return n"NewPhoneAvatar";
      case n"NewPhoneAvatar": return n"NewStaminaBar";
      case n"NewStaminaBar": return n"NewHealthBar";
      case n"NewHealthBar": return n"NewDpad";
      case n"NewDpad": return n"NewWeaponCrouch";
      case n"NewWeaponCrouch": return n"NewVehicleSummon";
      case n"NewVehicleSummon": return n"NewNotifications";
      case n"NewNotifications": return n"NewWanted";
      case n"NewWanted": return n"NewTracker";
      case n"NewTracker": return n"NewMinimap";
      default: return n"NewInputHint"; 
    };
  }

  public func SetHUDEditorListener(hudGameController: ref<inkGameController>) -> Void {
    let player: wref<PlayerPuppet> = this.GetPlayerPuppet();

    player.RegisterInputListener(hudGameController, n"ToggleSprint");
    player.RegisterInputListener(hudGameController, n"UI_Unequip");
    player.RegisterInputListener(hudGameController, n"world_map_filter_navigation_down");
    player.RegisterInputListener(hudGameController, n"back");
    player.RegisterInputListener(hudGameController, n"cancel");
    player.RegisterInputListener(hudGameController, n"right_button");
    player.RegisterInputListener(hudGameController, n"left_button");
    player.RegisterInputListener(hudGameController, n"CameraMouseX");
    player.RegisterInputListener(hudGameController, n"CameraMouseY");
    player.RegisterInputListener(hudGameController, n"click");
  }

  public func AssignHUDWidgetListeners(customSlot: ref<HUDitorCustomSlot>) {
    let player: wref<PlayerPuppet> = this.GetPlayerPuppet();

    player.RegisterInputListener(customSlot, n"mouse_wheel");
    player.RegisterInputListener(customSlot, n"CameraMouseX");
    player.RegisterInputListener(customSlot, n"CameraMouseY");
    player.RegisterInputListener(customSlot, n"click");
  }

   public func RemoveHUDWidgetListeners(customSlot: ref<HUDitorCustomSlot>) {
    let player: wref<PlayerPuppet> = this.GetPlayerPuppet();

    player.UnregisterInputListener(customSlot, n"CameraMouseX");
    player.UnregisterInputListener(customSlot, n"CameraMouseY");
    player.UnregisterInputListener(customSlot, n"mouse_wheel");
    player.UnregisterInputListener(customSlot, n"click");
  }
} 