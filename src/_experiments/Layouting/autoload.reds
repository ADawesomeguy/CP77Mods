@wrapMethod(SingleplayerMenuGameController)
protected cb func OnSavesReady(saves: array<String>) -> Bool {
  wrappedMethod(saves);
  if this.m_savesCount > 0 {
    this.GetSystemRequestsHandler().LoadSavedGame(0);
  };
}